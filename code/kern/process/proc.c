#include <proc.h>

#include <assert.h>
#include <elf.h>
#include <error.h>
#include <kmalloc.h>
#include <pmm.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sync.h>
#include <trap.h>
#include <unistd.h>
#include <vmm.h>

/*
 * Process/thread mechanism.
 *
 * A thread is a process that shares an address space.  The process tree
 * (parent/cptr/yptr/optr) is what makes exit and wait meet: a dying
 * process releases its user pages, becomes a zombie, and the parent
 * releases the PCB and kernel stack later.  Keeping those two halves
 * separate is the central invariant of lab5.
 */

list_entry_t proc_list;

#define HASH_SHIFT 10
#define HASH_LIST_SIZE (1 << HASH_SHIFT)
#define pid_hashfn(x) (hash32(x, HASH_SHIFT))

static list_entry_t hash_list[HASH_LIST_SIZE];

struct proc_struct *idleproc = NULL;
struct proc_struct *initproc = NULL;
struct proc_struct *current = NULL;

static int nr_process = 0;

void kernel_thread_entry(void);
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

static int setup_pgdir(struct mm_struct *mm);
static void put_pgdir(struct mm_struct *mm);
static int load_icode(unsigned char *binary, size_t size);
static int kernel_execve(const char *name, unsigned char *binary, size_t size);

char *
set_proc_name(struct proc_struct *proc, const char *name)
{
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

char *
get_proc_name(struct proc_struct *proc)
{
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}

static int
get_pid(void)
{
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++last_pid >= MAX_PID)
    {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe)
    {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list)
        {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid)
            {
                if (++last_pid >= next_safe)
                {
                    if (last_pid >= MAX_PID)
                    {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid)
            {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}

/* First kernel entry of a forked thread: the frame is already on its
 * kernel stack, so all that is left is to restore it. */
static void
forkret(void)
{
    forkrets(current->tf);
}

static void
hash_proc(struct proc_struct *proc)
{
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

static void
unhash_proc(struct proc_struct *proc)
{
    list_del(&(proc->hash_link));
}

struct proc_struct *
find_proc(int pid)
{
    if (0 < pid && pid < MAX_PID)
    {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list)
        {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid)
            {
                return proc;
            }
        }
    }
    return NULL;
}

static int
setup_kstack(struct proc_struct *proc)
{
    struct Page *page = alloc_pages(KSTACKPAGE);
    if (page != NULL)
    {
        proc->kstack = (uintptr_t)page2kva(page);
        return 0;
    }
    return -E_NO_MEM;
}

static void
put_kstack(struct proc_struct *proc)
{
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
}

/* Link a process into both the global list and its parent's child chain. */
static void
set_links(struct proc_struct *proc)
{
    list_add(&proc_list, &(proc->list_link));

    proc->yptr = NULL;
    if ((proc->optr = proc->parent->cptr) != NULL)
    {
        proc->optr->yptr = proc;
    }
    proc->parent->cptr = proc;
    nr_process++;
}

static void
remove_links(struct proc_struct *proc)
{
    list_del(&(proc->list_link));

    if (proc->optr != NULL)
    {
        proc->optr->yptr = proc->yptr;
    }
    if (proc->yptr != NULL)
    {
        proc->yptr->optr = proc->optr;
    }
    else
    {
        proc->parent->cptr = proc->optr;
    }
    nr_process--;
}

/*
 * do_exit - release what the process can release itself, then hand the
 * PCB and kernel stack to the parent.
 *
 * The current kernel stack and proc_struct are still in use by schedule(),
 * so they must survive this call.  Only the user address space, the
 * zombie state, the exit code and the parent wakeup belong here.
 */
//LAB5 功能模块四 2412090
int
do_exit(int error_code)
{
    if (current == idleproc)
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
    {
        panic("initproc exit.\n");
    }

    struct mm_struct *mm = current->mm;
    if (mm != NULL)
    {
        /* Stop using the dying page table before its pages go away. */
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
        current->pgdir = boot_pgdir_pa;
    }

    current->state = PROC_ZOMBIE;
    current->exit_code = error_code;

    bool intr_flag;
    local_intr_save(intr_flag);
    {
        /* Orphans are adopted by initproc so every process still has a
         * parent that can eventually call do_wait(). */
        struct proc_struct *proc;
        while ((proc = current->cptr) != NULL)
        {
            current->cptr = proc->optr;
            proc->parent = initproc;
            proc->yptr = NULL;
            if ((proc->optr = initproc->cptr) != NULL)
            {
                initproc->cptr->yptr = proc;
            }
            initproc->cptr = proc;
        }

        if (current->parent->state == PROC_SLEEPING &&
            (current->parent->wait_state & WT_CHILD))
        {
            wakeup_proc(current->parent);
        }
    }
    local_intr_restore(intr_flag);

    schedule();
    panic("do_exit will not return!!\n");
}

/*
 * The first user program is chosen at build time by TEST, so the grader
 * can reuse one kernel tree for every case.  Without TEST the exit case
 * is the default demonstration.
 */
static int user_main(void *arg);

//LAB5 功能模块二 2410665
static int
init_main(void *arg)
{
    (void)arg;
    int pid;
    if ((pid = kernel_thread(user_main, NULL, 0)) != 0)
    {
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        ;
    }

    cprintf("all user-mode processes have quit.\n");
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
    assert(nr_process == 2);
    assert(list_next(&proc_list) == &(initproc->list_link));
    assert(list_prev(&proc_list) == &(initproc->list_link));
    cprintf("init check memory pass.\n");

    /* init must not return: kernel_thread_entry would turn that into
     * do_exit(0), and initproc is deliberately not allowed to die. */
    while (1)
    {
        current->state = PROC_SLEEPING;
        schedule();
    }
    return 0;
}

#define __KERNEL_EXECVE(name, binary, size) ({                          \
            cprintf("kernel_execve: pid = %d, name = \"%s\".\n",        \
                    current->pid, name);                                \
            kernel_execve(name, binary, (size_t)(size));                \
        })

#define KERNEL_EXECVE(x) ({                                             \
            extern unsigned char _binary_obj___user_##x##_out_start[],  \
                _binary_obj___user_##x##_out_size[];                    \
            __KERNEL_EXECVE(#x, _binary_obj___user_##x##_out_start,     \
                            _binary_obj___user_##x##_out_size);         \
        })

#define __KERNEL_EXECVE2(x, xstart, xsize) ({                           \
            extern unsigned char xstart[], xsize[];                     \
            __KERNEL_EXECVE(#x, xstart, (size_t)xsize);                 \
        })

#define KERNEL_EXECVE2(x, xstart, xsize)        __KERNEL_EXECVE2(x, xstart, xsize)

//LAB5 功能模块二 2410665
static int
user_main(void *arg)
{
    (void)arg;
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
}

/*
 * kernel_execve - enter do_execve through a supervisor ecall.
 *
 * The ecall gives us a trapframe on the current kernel stack.  load_icode
 * rewrites that frame for U-mode, so the normal __trapret path performs the
 * actual privilege switch.  Calling do_execve directly would return to a
 * kernel thread that has already replaced its address space.
 */
//LAB5 功能模块二 2410665
static int
kernel_execve(const char *name, unsigned char *binary, size_t size)
{
    register uintptr_t a0 asm("a0") = SYS_exec;
    register uintptr_t a1 asm("a1") = (uintptr_t)name;
    register uintptr_t a2 asm("a2") = strlen(name);
    register uintptr_t a3 asm("a3") = (uintptr_t)binary;
    register uintptr_t a4 asm("a4") = size;

    asm volatile("ecall"
                 : "+r"(a0)
                 : "r"(a1), "r"(a2), "r"(a3), "r"(a4)
                 : "memory");
    return (int)a0;
}

/*
 * do_execve - replace the current address space with a freshly loaded
 * image.  The old mm may be shared with other threads, so it is released
 * by reference count rather than unconditionally.
 */
//LAB5 功能模块二 2410665
int
do_execve(const char *name, size_t len, unsigned char *binary, size_t size)
{
    if (name == NULL || len == 0 || len > PROC_NAME_LEN)
    {
        return -E_INVAL;
    }

    char local[PROC_NAME_LEN + 1];
    memset(local, 0, sizeof(local));
    memcpy(local, name, len);
    local[len] = '\0';

    struct mm_struct *mm = current->mm;
    if (mm != NULL)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
        current->pgdir = boot_pgdir_pa;
    }

    int ret = load_icode(binary, size);
    if (ret != 0)
    {
        do_exit(ret);
    }
    set_proc_name(current, local);
    return 0;
}

/*
 * load_icode - validate the ELF, map every PT_LOAD segment, build the
 * user stack, and rewrite current->tf so __trapret lands in U-mode.
 */
//LAB5 功能模块二 2410665
static int
load_icode(unsigned char *binary, size_t size)
{
    if (binary == NULL || size < sizeof(struct elfhdr))
    {
        return -E_INVAL;
    }

    struct elfhdr *elf = (struct elfhdr *)binary;
    if (elf->e_magic != ELF_MAGIC)
    {
        return -E_INVAL_ELF;
    }
    if (elf->e_phnum == 0 ||
        elf->e_phoff + (size_t)elf->e_phnum * sizeof(struct proghdr) > size)
    {
        return -E_INVAL_ELF;
    }

    struct mm_struct *mm = mm_create();
    if (mm == NULL)
    {
        return -E_NO_MEM;
    }
    if (setup_pgdir(mm) != 0)
    {
        mm_destroy(mm);
        return -E_NO_MEM;
    }

    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
    int ret = 0;

    for (uint32_t i = 0; i < elf->e_phnum; i++)
    {
        if (ph[i].p_type != ELF_PT_LOAD || ph[i].p_memsz == 0)
        {
            continue;
        }
        if (ph[i].p_filesz > ph[i].p_memsz ||
            (size_t)ph[i].p_offset > size ||
            (size_t)ph[i].p_filesz > size - ph[i].p_offset)
        {
            ret = -E_INVAL_ELF;
            goto bad_icode;
        }

        uintptr_t va = (uintptr_t)ph[i].p_va;
        uintptr_t vend = va + (uintptr_t)ph[i].p_memsz;
        if (!USER_ACCESS(va, vend))
        {
            ret = -E_INVAL_ELF;
            goto bad_icode;
        }

        uint32_t flags = 0;
        if (ph[i].p_flags & ELF_PF_R)
        {
            flags |= VM_READ;
        }
        if (ph[i].p_flags & ELF_PF_W)
        {
            flags |= VM_WRITE;
        }
        if (ph[i].p_flags & ELF_PF_X)
        {
            flags |= VM_EXEC;
        }
        if (mm_map(mm, va, ph[i].p_memsz, flags, NULL) != 0)
        {
            ret = -E_NO_MEM;
            goto bad_icode;
        }

        uintptr_t start = ROUNDDOWN(va, PGSIZE);
        uintptr_t end = ROUNDUP(vend, PGSIZE);
        for (uintptr_t addr = start; addr < end; addr += PGSIZE)
        {
            struct Page *page = alloc_page();
            if (page == NULL)
            {
                ret = -E_NO_MEM;
                goto bad_icode;
            }
            memset(page2kva(page), 0, PGSIZE);

            /* Only the part of the page that the file really provides is
             * copied; the tail of .bss stays zero. */
            uintptr_t fstart = addr > va ? addr : va;
            uintptr_t fend = addr + PGSIZE < va + ph[i].p_filesz
                                 ? addr + PGSIZE
                                 : va + ph[i].p_filesz;
            if (fstart < fend)
            {
                memcpy((char *)page2kva(page) + (fstart - addr),
                       binary + ph[i].p_offset + (fstart - va),
                       fend - fstart);
            }

            uint32_t perm = PTE_U | PTE_R | PTE_V;
            if (flags & VM_WRITE)
            {
                perm |= PTE_W;
            }
            if (flags & VM_EXEC)
            {
                perm |= PTE_X;
            }
            if (page_insert(mm->pgdir, page, addr, perm) != 0)
            {
                free_page(page);
                ret = -E_NO_MEM;
                goto bad_icode;
            }
        }
    }

    /* User stack: a growable VMA with one guard page at the bottom; the
     * four pages nearest USTACKTOP are mapped eagerly for the first call. */
    if (mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE,
               VM_READ | VM_WRITE | VM_STACK, NULL) != 0)
    {
        ret = -E_NO_MEM;
        goto bad_icode;
    }
    for (int i = 1; i <= 4; i++)
    {
        struct Page *page = pgdir_alloc_page(mm->pgdir, USTACKTOP - i * PGSIZE, PTE_USER);
        if (page == NULL)
        {
            ret = -E_NO_MEM;
            goto bad_icode;
        }
        memset(page2kva(page), 0, PGSIZE);
    }

    mm_count_inc(mm);
    current->mm = mm;
    current->pgdir = PADDR(mm->pgdir);
    lsatp(current->pgdir);

    struct trapframe *tf = current->tf;
    memset(&(tf->gpr), 0, sizeof(tf->gpr));
    tf->gpr.sp = USTACKTOP;
    tf->epc = elf->e_entry;
    /* Return to U-mode with interrupts enabled after sret, but with SIE
     * clear until sret restores it from SPIE. */
    tf->status = (tf->status & ~(uintptr_t)SSTATUS_SPP) | SSTATUS_SPIE;
    tf->status &= ~(uintptr_t)SSTATUS_SIE;
    return 0;

bad_icode:
    exit_mmap(mm);
    put_pgdir(mm);
    mm_destroy(mm);
    return ret;
}

//LAB5 功能模块二 2410665
static struct proc_struct *
alloc_proc(void)
{
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL)
    {
        proc->state = PROC_UNINIT;
        proc->pid = -1;
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN + 1);
        proc->exit_code = 0;
        proc->wait_state = 0;
        proc->cptr = proc->yptr = proc->optr = NULL;
        list_init(&(proc->list_link));
        list_init(&(proc->hash_link));
    }
    return proc;
}

/* A user page table starts as a copy of the kernel mappings; the low
 * (user) half must start empty. */
static int
setup_pgdir(struct mm_struct *mm)
{
    struct Page *page = alloc_page();
    if (page == NULL)
    {
        return -E_NO_MEM;
    }
    pde_t *pgdir = page2kva(page);
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
    for (int i = 0; i < PDX1(USERTOP); i++)
    {
        pgdir[i] = 0;
    }
    mm->pgdir = pgdir;
    return 0;
}

static void
put_pgdir(struct mm_struct *mm)
{
    free_page(pa2page(PADDR(mm->pgdir)));
    mm->pgdir = NULL;
}

/*
 * copy_mm - CLONE_VM shares, otherwise duplicate every VMA and its pages.
 * Kernel threads have no user mm and simply keep boot_pgdir_pa.
 */
//LAB5 功能模块三 2410749
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc)
{
    struct mm_struct *oldmm = current->mm;
    if (oldmm == NULL)
    {
        return 0;
    }

    if (clone_flags & CLONE_VM)
    {
        mm_count_inc(oldmm);
        proc->mm = oldmm;
        proc->pgdir = PADDR(oldmm->pgdir);
        return 0;
    }

    struct mm_struct *mm = mm_create();
    if (mm == NULL)
    {
        return -E_NO_MEM;
    }
    if (setup_pgdir(mm) != 0)
    {
        mm_destroy(mm);
        return -E_NO_MEM;
    }

    int ret;
    lock_mm(oldmm);
    ret = dup_mmap(mm, oldmm);
    unlock_mm(oldmm);

    if (ret != 0)
    {
        exit_mmap(mm);
        put_pgdir(mm);
        mm_destroy(mm);
        return ret;
    }

    mm_count_inc(mm);
    proc->mm = mm;
    proc->pgdir = PADDR(mm->pgdir);
    return 0;
}

//LAB5 功能模块三 2410749
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf)
{
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
    *(proc->tf) = *tf;
    proc->tf->gpr.a0 = 0;
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)(proc->tf) : esp;
    proc->context.ra = (uintptr_t)forkret;
    proc->context.sp = (uintptr_t)(proc->tf);
}

//LAB5 功能模块三 2410749
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc = alloc_proc();
    if (proc == NULL)
    {
        goto fork_out;
    }
    proc->parent = current;

    ret = setup_kstack(proc);
    if (ret != 0)
    {
        goto bad_fork_cleanup_proc;
    }
    ret = copy_mm(clone_flags, proc);
    if (ret != 0)
    {
        goto bad_fork_cleanup_kstack;
    }
    copy_thread(proc, stack, tf);

    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
        hash_proc(proc);
        set_links(proc);
    }
    local_intr_restore(intr_flag);

    wakeup_proc(proc);
    ret = proc->pid;

fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}

//LAB5 功能模块二 2410665
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags)
{
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));
    tf.gpr.s0 = (uintptr_t)fn;
    tf.gpr.s1 = (uintptr_t)arg;
    tf.status = read_csr(sstatus);
    tf.status |= SSTATUS_SPP | SSTATUS_SPIE;
    tf.status &= ~(uintptr_t)SSTATUS_SIE;
    tf.epc = (uintptr_t)kernel_thread_entry;
    return do_fork(clone_flags, 0, &tf);
}

void
proc_init(void)
{
    int i;
    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
    {
        list_init(hash_list + i);
    }

    idleproc = alloc_proc();
    assert(idleproc != NULL);
    current = idleproc;

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
    set_proc_name(idleproc, "idle");
    nr_process++;

    int pid = kernel_thread(init_main, "Hello world!!", 0);
    assert(pid == 1);
    initproc = find_proc(1);
    assert(initproc != NULL);
    set_proc_name(initproc, "init");
}

//LAB4 功能模块三 2412090
void
cpu_idle(void)
{
    while (1)
    {
        if (current->need_resched)
        {
            schedule();
        }
    }
}

void
proc_run(struct proc_struct *proc)
{
    if (proc != current)
    {
        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;
        local_intr_save(intr_flag);
        {
            current = next;
            lsatp(next->pgdir);
            switch_to(&(prev->context), &(next->context));
        }
        local_intr_restore(intr_flag);
    }
}

/*
 * do_wait - reap a zombie child, or sleep until one becomes available.
 * pid == 0 means any child; pid > 0 means that exact child.
 */
//LAB5 功能模块四 2412090
int
do_wait(int pid, int *code_store)
{
    bool intr_flag;

    while (1)
    {
        bool has_child = 0;
        struct proc_struct *zombie = NULL;
        struct proc_struct *proc;

        for (proc = current->cptr; proc != NULL; proc = proc->optr)
        {
            if (pid <= 0 || proc->pid == pid)
            {
                has_child = 1;
                if (proc->state == PROC_ZOMBIE)
                {
                    zombie = proc;
                    break;
                }
            }
        }

        if (zombie != NULL)
        {
            current->wait_state = 0;
            if (code_store != NULL)
            {
                *code_store = zombie->exit_code;
            }

            local_intr_save(intr_flag);
            unhash_proc(zombie);
            remove_links(zombie);
            local_intr_restore(intr_flag);

            put_kstack(zombie);
            kfree(zombie);
            return 0;
        }

        if (!has_child)
        {
            return -E_BAD_PROC;
        }

        current->state = PROC_SLEEPING;
        current->wait_state = WT_CHILD;
        schedule();

        /* A kill interrupts the wait; the trap epilogue will call
         * do_exit once this syscall has unwound. */
        if (current->flags & PF_EXITING)
        {
            return -E_KILLED;
        }
    }
}

//LAB5 功能模块四 2412090
int
do_yield(void)
{
    current->need_resched = 1;
    return 0;
}

//LAB5 功能模块四 2412090
int
do_kill(int pid)
{
    struct proc_struct *proc = find_proc(pid);
    if (proc == NULL || proc->state == PROC_ZOMBIE)
    {
        return -E_BAD_PROC;
    }
    proc->flags |= PF_EXITING;
    if (proc->state == PROC_SLEEPING)
    {
        wakeup_proc(proc);
    }
    return 0;
}
