#include <stdio.h>
#include <ulib.h>

int
main(void)
{
    int pid = fork();
    if (pid == 0)
    {
        exit(0);
    }
    assert(pid > 0);

    /* 0x1000 is below USERBASE: the kernel must reject the store instead
     * of dereferencing it on behalf of the user. */
    assert(waitpid(pid, (int *)0x1000) != 0);
    assert(waitpid(pid, NULL) == 0);
    cprintf("badarg pass.\n");
    return 0;
}
