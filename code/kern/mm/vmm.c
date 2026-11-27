#include <vmm.h>
#include <sync.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <error.h>
#include <pmm.h>
#include <riscv.h>
#include <kmalloc.h>

/*
  vmm design include two parts: mm_struct (mm) & vma_struct (vma)
  mm is the memory manager for the set of continuous virtual memory
  area which have the same PDT. vma is a continuous virtual memory area.
  There a linear link list for vma & a redblack link list for vma in mm.
---------------
  mm related functions:
   golbal functions
     struct mm_struct * mm_create(void)
     void mm_destroy(struct mm_struct *mm)
     int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
--------------
  vma related functions:
   global functions
     struct vma_struct * vma_create (uintptr_t vm_start, uintptr_t vm_end,...)
     void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
     struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr)
   local functions
     inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
---------------
   check correctness functions
     void check_vmm(void);
     void check_vma_struct(void);
     void check_pgfault(void);
*/

// szx func : print_vma and print_mm
void print_vma(char *name, struct vma_struct *vma)
{
    cprintf("-- %s print_vma --\n", name);
    cprintf("   mm_struct: %p\n", vma->vm_mm);
    cprintf("   vm_start,vm_end: %x,%x\n", vma->vm_start, vma->vm_end);
    cprintf("   vm_flags: %x\n", vma->vm_flags);
    cprintf("   list_entry_t: %p\n", &vma->list_link);
}

void print_mm(char *name, struct mm_struct *mm)
{
    cprintf("-- %s print_mm --\n", name);
    cprintf("   mmap_list: %p\n", &mm->mmap_list);
    cprintf("   map_count: %d\n", mm->map_count);
    list_entry_t *list = &mm->mmap_list;
    for (int i = 0; i < mm->map_count; i++)
    {
        list = list_next(list);
        print_vma(name, le2vma(list, list_link));
    }
}

static void check_vmm(void);
static void check_vma_struct(void);
static void check_pgfault(void);

// mm_create -  alloc a mm_struct & initialize it.
struct mm_struct *
mm_create(void)
{
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

    if (mm != NULL)
    {
        list_init(&(mm->mmap_list));
        mm->mmap_cache = NULL;
        mm->pgdir = NULL;
        mm->map_count = 0;
        mm->sm_priv = NULL;
        mm->mm_count = 0;
        lock_init(&(mm->mm_lock));
    }
    return mm;
}

// vma_create - alloc a vma_struct & initialize it. (addr range: vm_start~vm_end)
struct vma_struct *
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags)
{
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));

    if (vma != NULL)
    {
        vma->vm_start = vm_start;
        vma->vm_end = vm_end;
        vma->vm_flags = vm_flags;
    }
    return vma;
}

// find_vma - find a vma  (vma->vm_start <= addr <= vma_vm_end)
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr)
{
    struct vma_struct *vma = NULL;
    if (mm != NULL)
    {
        vma = mm->mmap_cache;
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
        {
            bool found = 0;
            list_entry_t *list = &(mm->mmap_list), *le = list;
            while ((le = list_next(le)) != list)
            {
                vma = le2vma(le, list_link);
                if (vma->vm_start <= addr && addr < vma->vm_end)
                {
                    found = 1;
                    break;
                }
            }
            if (!found)
            {
                vma = NULL;
            }
        }
        if (vma != NULL)
        {
            mm->mmap_cache = vma;
        }
    }
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
    list_entry_t *list = &(mm->mmap_list);
    list_entry_t *le_prev = list, *le_next;

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
        {
            break;
        }
        le_prev = le;
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
    }
    if (le_next != list)
    {
        check_vma_overlap(vma, le2vma(le_next, list_link));
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
}

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
    }
    kfree(mm); // kfree mm
    mm = NULL;
}

/*
 * mm_map - register [addr, addr + len) as a legal user area.
 * The range is page aligned outward, must stay inside the user window and
 * must not overlap an existing vma.
 */
int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
    if (!USER_ACCESS(start, end))
    {
        return -E_INVAL;
    }
    assert(mm != NULL);

    struct vma_struct *vma = find_vma(mm, start);
    if (vma != NULL && end > vma->vm_start)
    {
        /* The new range would overlap the vma that contains start. */
        return -E_INVAL;
    }

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        return -E_NO_MEM;
    }
    insert_vma_struct(mm, vma);
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    return 0;
}

/*
 * dup_mmap - clone every vma of the parent and the pages behind it.
 * COW is the default for this lab: cow_copy_range() shares the writable
 * pages read-only. Defining LAB5_NO_COW falls back to a full copy.
 */
//LAB5 COW Challenge 2412090
int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
    assert(to != NULL && from != NULL);
    list_entry_t *list = &(from->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *vma = le2vma(le, list_link);
        struct vma_struct *nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }
        insert_vma_struct(to, nvma);

#ifdef LAB5_NO_COW
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, 0) != 0)
#else
        if (cow_copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end) != 0)
#endif
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}

/* Drop all pages and page tables of an address space that nobody shares. */
void exit_mmap(struct mm_struct *mm)
{
    assert(mm != NULL && mm_count(mm) == 0);

    pde_t *pgdir = mm->pgdir;
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
    }

    le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
    }
}

/*
 * user_mem_check - can user space [start, start + len) be accessed?
 * A process always has an mm; kernel threads pass NULL and are checked
 * against the kernel window instead.
 */
//LAB5 功能模块一 2410665
bool user_mem_check(struct mm_struct *mm, uintptr_t start, size_t len, bool write)
{
    if (mm != NULL)
    {
        if (!USER_ACCESS(start, start + len))
        {
            return 0;
        }

        uintptr_t addr = start, end = start + len;
        while (addr < end)
        {
            struct vma_struct *vma = find_vma(mm, addr);
            if (vma == NULL || addr < vma->vm_start)
            {
                return 0;
            }
            if (!(vma->vm_flags & (write ? VM_WRITE : VM_READ)))
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK) && addr < vma->vm_start + PGSIZE)
            {
                /* The lowest page of the stack is a guard page. */
                return 0;
            }
            addr = vma->vm_end;
        }
        return 1;
    }
    return KERN_ACCESS(start, start + len);
}

/*
 * do_pgfault - resolve a page fault on behalf of user space.
 *
 * Two cases are meaningful here:
 *  - a COW page (PTE_COW) is written: give the writer a private copy;
 *  - a stack address below the pages already mapped: grow the stack.
 * Everything else is a real fault and is reported to the caller, which
 * kills the process.
 */
//LAB5 COW Challenge 2412090
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    struct vma_struct *vma = find_vma(mm, addr);
    if (vma == NULL || addr < vma->vm_start)
    {
        return -E_FAULT;
    }

    pte_t *ptep = get_pte(mm->pgdir, addr, 0);
    if (ptep != NULL && (*ptep & PTE_V))
    {
        if (!(*ptep & PTE_COW))
        {
            return -E_FAULT;
        }

        struct Page *page = pte2page(*ptep);
        if (page_ref(page) == 1)
        {
            /* Sole owner: there is nothing to copy, just re-enable writes. */
            uint32_t perm = (*ptep & PTE_USER) | PTE_W | PTE_V;
            *ptep = pte_create(page2ppn(page), perm);
            tlb_invalidate(mm->pgdir, addr);
            return 0;
        }

        struct Page *npage = alloc_page();
        if (npage == NULL)
        {
            return -E_NO_MEM;
        }
        memcpy(page2kva(npage), page2kva(page), PGSIZE);

        uint32_t perm = (*ptep & (PTE_R | PTE_X | PTE_U)) | PTE_W | PTE_V;
        if (page_insert(mm->pgdir, npage, ROUNDDOWN(addr, PGSIZE), perm) != 0)
        {
            free_page(npage);
            return -E_NO_MEM;
        }
        return 0;
    }

    /* Not mapped yet: only the growable user stack may fault in a page. */
    if (!(vma->vm_flags & VM_STACK))
    {
        return -E_FAULT;
    }
    if ((error_code & 0x1) == 0)
    {
        return -E_FAULT; /* a read before the stack grew is not valid */
    }

    uintptr_t la = ROUNDDOWN(addr, PGSIZE);
    if (la < vma->vm_start + PGSIZE)
    {
        return -E_FAULT; /* guard page */
    }
    struct Page *page = pgdir_alloc_page(mm->pgdir, la, PTE_USER);
    if (page == NULL)
    {
        return -E_NO_MEM;
    }
    memset(page2kva(page), 0, PGSIZE);
    return 0;
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
    check_vmm();
}

// check_vmm - check correctness of vmm
static void
check_vmm(void)
{
    check_vma_struct();
    // check_pgfault();

    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void)
{
    struct mm_struct *mm = mm_create();
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    for (i = step1 + 1; i <= step2; i++)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
    {
        assert(le != &(mm->mmap_list));
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
        assert(vma1 != NULL);
        struct vma_struct *vma2 = find_vma(mm, i + 1);
        assert(vma2 != NULL);
        struct vma_struct *vma3 = find_vma(mm, i + 2);
        assert(vma3 == NULL);
        struct vma_struct *vma4 = find_vma(mm, i + 3);
        assert(vma4 == NULL);
        struct vma_struct *vma5 = find_vma(mm, i + 4);
        assert(vma5 == NULL);

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
    }

    for (i = 4; i >= 0; i--)
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
        if (vma_below_5 != NULL)
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
}
