#include <stdio.h>
#include <ulib.h>

static void
tree(int depth)
{
    if (depth == 0)
    {
        exit(0);
    }
    for (int i = 0; i < 2; i++)
    {
        int pid = fork();
        if (pid == 0)
        {
            tree(depth - 1);
            exit(0);
        }
        assert(pid > 0);
    }
    for (int i = 0; i < 2; i++)
    {
        assert(wait(NULL) == 0);
    }
    exit(0);
}

int
main(void)
{
    int pid = fork();
    if (pid == 0)
    {
        tree(2);
    }
    assert(pid > 0);
    assert(wait(NULL) == 0);
    cprintf("forktree pass.\n");
    return 0;
}
