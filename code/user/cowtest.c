#include <stdio.h>
#include <ulib.h>

/*
 * COW regression: two children fork while the parent's writable pages are
 * still shared.  Each child writes both a .data page and a stack page, then
 * the parent must still see its original values.  This exercises the
 * reference count > 2 path in do_pgfault().
 */

int shared = 1;

int
main(void)
{
    int pid1, pid2, code;
    int local = 10;

    if ((pid1 = fork()) == 0) {
        assert(shared == 1 && local == 10);
        shared = 2;
        local = 20;
        yield();
        yield();
        assert(shared == 2 && local == 20);
        cprintf("child1 private copy ok\n");
        exit(0);
    }
    assert(pid1 > 0);

    if ((pid2 = fork()) == 0) {
        assert(shared == 1 && local == 10);
        shared = 3;
        local = 30;
        assert(shared == 3 && local == 30);
        cprintf("child2 private copy ok\n");
        exit(0);
    }
    assert(pid2 > 0);

    yield();
    yield();
    yield();
    assert(shared == 1 && local == 10);
    cprintf("parent unchanged: shared=%d local=%d\n", shared, local);

    assert(waitpid(pid1, &code) == 0 && code == 0);
    assert(waitpid(pid2, &code) == 0 && code == 0);
    cprintf("cowtest pass.\n");
    return 0;
}
