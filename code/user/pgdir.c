#include <stdio.h>
#include <ulib.h>

int
main(void)
{
    cprintf("pgdir: dumping the page table.\n");
    pgdir();
    cprintf("pgdir pass.\n");
    return 0;
}
