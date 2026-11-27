#ifndef __KERN_MM_VMM_H__
#define __KERN_MM_VMM_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <sync.h>

struct mm_struct;

/* A virtual memory area, [vm_start, vm_end). */
struct vma_struct
{
    struct mm_struct *vm_mm; // address space this vma belongs to
    uintptr_t vm_start;      // first address inside the area
    uintptr_t vm_end;        // first address after the area
    uint32_t vm_flags;       // VM_READ / VM_WRITE / VM_EXEC / VM_STACK
    list_entry_t list_link;  // sorted linkage inside mm->mmap_list
};

#define le2vma(le, member) \
    to_struct((le), struct vma_struct, member)

#define VM_READ 0x00000001
#define VM_WRITE 0x00000002
#define VM_EXEC 0x00000004
#define VM_STACK 0x00000008

/* Address space shared by every thread of a process. */
struct mm_struct
{
    list_entry_t mmap_list;        // vma list sorted by vm_start
    struct vma_struct *mmap_cache; // last hit, avoids a list walk
    pde_t *pgdir;                  // root page table (kernel virtual address)
    int map_count;                 // number of vmas
    void *sm_priv;                 // private data for the swap manager
    int mm_count;                  // processes sharing this address space
    lock_t mm_lock;                // serialises concurrent address-space copies
};

struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr);
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags);
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma);

struct mm_struct *mm_create(void);
void mm_destroy(struct mm_struct *mm);

void vmm_init(void);
int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr);

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store);
int dup_mmap(struct mm_struct *to, struct mm_struct *from);
void exit_mmap(struct mm_struct *mm);

bool user_mem_check(struct mm_struct *mm, uintptr_t start, size_t len, bool write);

extern volatile unsigned int pgfault_num;
extern struct mm_struct *check_mm_struct;

static inline int
mm_count(struct mm_struct *mm)
{
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    return ++mm->mm_count;
}

static inline int
mm_count_dec(struct mm_struct *mm)
{
    return --mm->mm_count;
}

static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
    }
}

static inline void
unlock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        unlock(&(mm->mm_lock));
    }
}

#endif /* !__KERN_MM_VMM_H__ */
