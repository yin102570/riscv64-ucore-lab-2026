#include <stdio.h>
#include <ulib.h>

int
main(void)
{
    cprintf("badsegment: writing just above the user stack.\n");
    *(volatile int *)0x80000000UL = 1;
    cprintf("badsegment failed.\n");
    return 0;
}
