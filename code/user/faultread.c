#include <stdio.h>
#include <ulib.h>

int
main(void)
{
    cprintf("faultread: reading 0x0.\n");
    int value = *(volatile int *)0x0;
    cprintf("faultread failed: read %d.\n", value);
    return 0;
}
