#include <stdio.h>
#include <ulib.h>

int bss_var;

int
main(void)
{
    assert(bss_var == 0);
    bss_var = 0x1234;

    int pid = fork();
    if (pid == 0)
    {
        assert(bss_var == 0x1234);
        bss_var = 0x5678;
        exit(0);
    }
    assert(pid > 0);
    assert(wait(NULL) == 0);
    assert(bss_var == 0x1234);
    cprintf("testbss pass.\n");
    return 0;
}
