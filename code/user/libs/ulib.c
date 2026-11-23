//LAB5 功能模块二 2410665
#include <stdio.h>
#include <syscall.h>
#include <ulib.h>

void
exit(int error_code)
{
    sys_exit(error_code);
    cprintf("BUG: exit failed.\n");
    while (1)
    {
        ;
    }
}

int fork(void) { return sys_fork(); }
int wait(int *store) { return sys_wait(0, store); }
int waitpid(int pid, int *store) { return sys_wait(pid, store); }
void yield(void) { sys_yield(); }
int kill(int pid) { return sys_kill(pid); }
int getpid(void) { return sys_getpid(); }
void pgdir(void) { sys_pgdir(); }

void
__panic(const char *file, int line, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    cprintf("user panic at %s:%d: ", file, line);
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);
    exit(-1);
}
