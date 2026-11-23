//LAB5 功能模块二 2410665
#include <defs.h>
#include <stdio.h>
#include <syscall.h>

static void
cputch(int c, int *cnt)
{
    sys_putc(c);
    (*cnt)++;
}

int
vcprintf(const char *fmt, va_list ap)
{
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
    return cnt;
}

int
cprintf(const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    int cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
