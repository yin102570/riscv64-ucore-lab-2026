#include <defs.h>
#include <assert.h>
#include <pmm.h>
#include <stdio.h>

/*
 * Lab4 边界测试 T1-T4（虚拟内存页操作）
 * 放在临时副本中运行，不进入默认评分路径。
 * 注意：可写页必须是 PTE_R | PTE_W；单独 PTE_W（W=1,R=0）在 RISC-V 是保留组合。
 */

static void boundary_pass(const char *name) {
    cprintf("[Boundary %s] PASS\n", name);
}

/* T1：同一物理页在同一地址重复映射，引用计数和空闲页数都不变 */
void test_t1_same_page_remap(void) {
    struct Page *p = alloc_page();
    assert(p != NULL);

    assert(page_insert(boot_pgdir_va, p, 0x1000, PTE_R | PTE_W) == 0);
    assert(page_ref(p) == 1);

    size_t free_before = nr_free_pages();
    assert(page_insert(boot_pgdir_va, p, 0x1000, PTE_R | PTE_W | PTE_U) == 0);
    assert(page_ref(p) == 1);
    assert(nr_free_pages() == free_before);

    page_remove(boot_pgdir_va, 0x1000);
    assert(page_ref(p) == 0);
    boundary_pass("T1");
}

/* T2：同一地址从 p1 改映射到 p2，旧页只减一次、新页只加一次，权限完全更新 */
void test_t2_remap_perm(void) {
    struct Page *p1 = alloc_page();
    struct Page *p2 = alloc_page();
    assert(p1 != NULL && p2 != NULL);

    assert(page_insert(boot_pgdir_va, p1, 0x2000, PTE_R | PTE_W) == 0);
    assert(page_ref(p1) == 1);
    assert(page_insert(boot_pgdir_va, p2, 0x2000, PTE_R | PTE_U) == 0);
    assert(page_ref(p1) == 0);
    assert(page_ref(p2) == 1);

    pte_t *ptep = get_pte(boot_pgdir_va, 0x2000, 0);
    assert(ptep != NULL && (*ptep & PTE_V));
    assert(*ptep & PTE_U);
    assert((*ptep & PTE_W) == 0);

    page_remove(boot_pgdir_va, 0x2000);
    assert(page_ref(p2) == 0);
    boundary_pass("T2");
}

/* T3：对未映射/已删除地址重复 page_remove，必须幂等 */
void test_t3_idempotent_remove(void) {
    page_remove(boot_pgdir_va, 0x3000);

    struct Page *p = alloc_page();
    assert(p != NULL);
    assert(page_insert(boot_pgdir_va, p, 0x3000, PTE_R | PTE_W) == 0);
    page_remove(boot_pgdir_va, 0x3000);
    page_remove(boot_pgdir_va, 0x3000);
    assert(page_ref(p) == 0);
    boundary_pass("T3");
}

/* T4：同一地址改映射后，实际读写走的是新物理页，不命中旧翻译。
 * 额外持有 p1 的测试引用，防止重映射时 p1 被释放（避免 use-after-free）。 */
void test_t4_tlb_consistency(void) {
    struct Page *p1 = alloc_page();
    struct Page *p2 = alloc_page();
    uintptr_t la = 0x4000;
    assert(p1 != NULL && p2 != NULL);

    page_ref_inc(p1); /* 测试引用，重映射只释放映射引用 */

    assert(page_insert(boot_pgdir_va, p1, la, PTE_R | PTE_W) == 0);
    *(volatile char *)la = 'A';
    assert(*(volatile char *)la == 'A');

    assert(page_insert(boot_pgdir_va, p2, la, PTE_R | PTE_W) == 0);
    *(volatile char *)la = 'B';
    assert(*(volatile char *)la == 'B');
    assert(*(char *)(page2kva(p2) + PGOFF(la)) == 'B');
    assert(*(char *)(page2kva(p1) + PGOFF(la)) == 'A');

    page_remove(boot_pgdir_va, la);
    if (page_ref_dec(p1) == 0) {
        free_page(p1); /* 引用归零才真正释放，避免测试泄漏页面 */
    }
    boundary_pass("T4");
}

void test_lab4_boundary(void) {
    test_t1_same_page_remap();
    test_t2_remap_perm();
    test_t3_idempotent_remove();
    test_t4_tlb_consistency();
    cprintf("[Boundary] all PMM boundary tests done.\n");
}
