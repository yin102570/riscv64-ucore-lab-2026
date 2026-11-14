#include <defs.h>
#include <assert.h>
#include <error.h>
#include <proc.h>
#include <stdio.h>

/* 故障注入开关与进程计数 getter，由 injector 在 proc.c 里定义 */
extern int force_alloc_proc_fail;
extern int force_setup_kstack_fail;
extern int get_nr_process(void);

static int dummy_fn(void *arg) {
    (void)arg;
    return 0;
}

static void boundary_pass(const char *name) {
    cprintf("[Boundary %s] PASS\n", name);
}

/* T8：do_fork 失败路径清理。setup_kstack / alloc_proc 失败时，
 * 必须返回真实错误码，不挂半初始化 PCB（进程计数不变）。 */
void test_t8_failure_cleanup(void) {
    int nr_before = get_nr_process();

    /* 场景 1：setup_kstack 失败 -> -E_NO_MEM，且进程计数不变 */
    force_setup_kstack_fail = 1;
    int ret = kernel_thread(dummy_fn, 0, 0);
    force_setup_kstack_fail = 0;
    assert(ret == -E_NO_MEM);
    assert(get_nr_process() == nr_before);
    cprintf("[Boundary T8a] setup_kstack fail -> -E_NO_MEM, nr_process unchanged OK\n");

    /* 场景 2：alloc_proc 失败 -> -E_NO_FREE_PROC，进程计数不变 */
    force_alloc_proc_fail = 1;
    ret = kernel_thread(dummy_fn, 0, 0);
    force_alloc_proc_fail = 0;
    assert(ret == -E_NO_FREE_PROC);
    assert(get_nr_process() == nr_before);
    cprintf("[Boundary T8b] alloc_proc fail -> -E_NO_FREE_PROC, nr_process unchanged OK\n");

    boundary_pass("T8");
}
