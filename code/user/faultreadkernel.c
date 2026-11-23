#include <stdio.h>
#include <ulib.h>

int
main(void)
{
    cprintf("faultreadkernel: reading a kernel address.\n");
    int value = *(volatile int *)0xFFFFFFFFC0000000UL;
    cprintf("faultreadkernel failed: read %d.\n", value);
    return 0;
}
