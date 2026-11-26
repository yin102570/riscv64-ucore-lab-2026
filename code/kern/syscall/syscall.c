//LAB5 功能模块一 2410665
#include <syscall.h>

#include <console.h>
#include <error.h>
#include <pmm.h>
#include <proc.h>
#include <stdio.h>
#include <trap.h>
#include <unistd.h>
#include <vmm.h>

/*
 * A system call is just an agreed register convention:
 *   a0 = number, a1..a5 = arguments, a0 = result on return.
 * The trapframe is the only safe place to read or write those registers,
 * because it is what RESTORE_ALL will load before sret.
 */

static int
sys_exit(uint64_t arg[])
{
    do_exit((int)arg[0]);
    return 0;
}

static int
sys_fork(uint64_t arg[])
{
    (void)arg;
    /* A user fork must resume both sides at the same user stack pointer;
     * passing 0 would tell copy_thread to build a kernel-thread stack. */
    return do_fork(0, current->tf->gpr.sp, current->tf);
}

static int
sys_wait(uint64_t arg[])
{
    int pid = (int)arg[0];
    int *store = (int *)arg[1];

    if (store != NULL &&
        !user_mem_check(current->mm, (uintptr_t)store, sizeof(int), 1)) {
        return -E_INVAL;
    }
    return do_wait(pid, store);
}

static int
sys_exec(uint64_t arg[])
{
    const char *name = (const char *)arg[0];
    size_t len = (size_t)arg[1];
    unsigned char *binary = (unsigned char *)arg[2];
    size_t size = (size_t)arg[3];

    /* sys_exec is only reachable from U-mode; every pointer it receives
     * must be validated against the caller's own address space. */
    if (!user_mem_check(current->mm, (uintptr_t)name, len, 0) ||
        !user_mem_check(current->mm, (uintptr_t)binary, size, 0)) {
        return -E_INVAL;
    }
    return do_execve(name, len, binary, size);
}

static int
sys_yield(uint64_t arg[])
{
    (void)arg;
    return do_yield();
}

static int
sys_kill(uint64_t arg[])
{
    return do_kill((int)arg[0]);
}

static int
sys_getpid(uint64_t arg[])
{
    (void)arg;
    return current->pid;
}

static int
sys_putc(uint64_t arg[])
{
    cputchar((int)arg[0]);
    return 0;
}

static int
sys_pgdir(uint64_t arg[])
{
    (void)arg;
    print_pgdir((pde_t *)KADDR(current->pgdir));
    return 0;
}

static int (*const syscalls[NR_SYSCALLS])(uint64_t[]) = {
    [SYS_exit]   = sys_exit,
    [SYS_fork]   = sys_fork,
    [SYS_wait]   = sys_wait,
    [SYS_exec]   = sys_exec,
    [SYS_yield]  = sys_yield,
    [SYS_kill]   = sys_kill,
    [SYS_getpid] = sys_getpid,
    [SYS_putc]   = sys_putc,
    [SYS_pgdir]  = sys_pgdir,
};

void
syscall(void)
{
    struct trapframe *tf = current->tf;
    uintptr_t num = tf->gpr.a0;

    uint64_t args[5] = {
        tf->gpr.a1, tf->gpr.a2, tf->gpr.a3,
        tf->gpr.a4, tf->gpr.a5,
    };

    int ret = -E_INVAL;
    if (num < NR_SYSCALLS && syscalls[num] != NULL) {
        ret = syscalls[num](args);
    }
    tf->gpr.a0 = ret;
}
