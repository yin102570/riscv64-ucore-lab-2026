//LAB5 功能模块一 2410665
#include <defs.h>
#include <stdarg.h>
#include <syscall.h>
#include <unistd.h>

#define MAX_ARGS 5

/*
 * Put the number in a0 and the arguments in a1..a5, then ecall.  Explicit
 * register variables are used so the compiler cannot move an argument to
 * a different register between the assignments and the ecall.
 */
static inline int
syscall(int num, ...)
{
    va_list ap;
    va_start(ap, num);
    uintptr_t a[MAX_ARGS];
    for (int i = 0; i < MAX_ARGS; i++)
    {
        a[i] = va_arg(ap, uintptr_t);
    }
    va_end(ap);

    register uintptr_t a0 asm("a0") = (uintptr_t)num;
    register uintptr_t a1 asm("a1") = a[0];
    register uintptr_t a2 asm("a2") = a[1];
    register uintptr_t a3 asm("a3") = a[2];
    register uintptr_t a4 asm("a4") = a[3];
    register uintptr_t a5 asm("a5") = a[4];

    asm volatile("ecall"
                 : "+r"(a0)
                 : "r"(a1), "r"(a2), "r"(a3), "r"(a4), "r"(a5)
                 : "memory");
    return (int)a0;
}

int sys_exit(int error_code)
{
    return syscall(SYS_exit, (uintptr_t)(intptr_t)error_code, 0, 0, 0, 0);
}
int sys_fork(void) { return syscall(SYS_fork, 0, 0, 0, 0, 0); }
int sys_wait(int pid, int *store)
{
    return syscall(SYS_wait, (uintptr_t)(intptr_t)pid, store, 0, 0, 0);
}
int sys_exec(const char *name, int len, unsigned char *binary, int size)
{
    return syscall(SYS_exec, name, (uintptr_t)(intptr_t)len, binary,
                   (uintptr_t)(intptr_t)size, 0);
}
int sys_yield(void) { return syscall(SYS_yield, 0, 0, 0, 0, 0); }
int sys_kill(int pid)
{
    return syscall(SYS_kill, (uintptr_t)(intptr_t)pid, 0, 0, 0, 0);
}
int sys_getpid(void) { return syscall(SYS_getpid, 0, 0, 0, 0, 0); }
int sys_putc(int c)
{
    return syscall(SYS_putc, (uintptr_t)(intptr_t)c, 0, 0, 0, 0);
}
int sys_pgdir(void) { return syscall(SYS_pgdir, 0, 0, 0, 0, 0); }
