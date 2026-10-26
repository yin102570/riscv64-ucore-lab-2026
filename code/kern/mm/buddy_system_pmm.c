#include <assert.h>
#include <buddy_system_pmm.h>
#include <list.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>

//lab2 challenge 2-3 2412090
/* ========================= 伙伴系统（Buddy System） =========================
 * 和 First-Fit / Best-Fit 的“一条按地址排序的空闲块链表”不同，伙伴系统把空闲
 * 物理页按 2 的幂次阶（order）组织成若干条链表：
 *
 *      order k 的块大小 = 2^k 页，且块首的物理页号必须按 2^k 对齐。
 *
 * 三条规则：
 *   ① 分配：请求 n 页时先取 need = ceil(log2(n))，从最小的有货的阶 j >= need
 *      开始，把大块不断对半劈开（split），右半块（buddy）挂进低阶链表，
 *      左半块继续往下劈，最终拿到 2^need 页的对齐块；
 *   ② 释放：把块挂回它所在阶的链表，然后沿阶往上检查“伙伴”是否也空闲，
 *      两个伙伴同阶且都空闲就合并（coalesce）成高一阶的块，直到不能再合并；
 *   ③ 记账：buddy_nr_free 记录空闲页总数，“块首页 + property = 块页数”标记空闲块。
 *
 * 与首次/最佳适配相比，伙伴系统牺牲了一部分内部碎片（最小分配单位按 2 的
 * 幂次对齐，请求 3 页会拿到 4 页），换来 O(log N) 的分配/回收——因为合并只需要
 * 检查一个固定的“伙伴”地址：buddy = index ^ (1 << order)。
 * ========================================================================= */
#define BUDDY_MAX_ORDER 11 /* 单块最大 2^11 = 2048 页 = 8MB */

/* 每个阶一条空闲链表（按块首物理页号升序），链表头 + 该阶的信用 free_area_t */
static free_area_t buddy_free_area[BUDDY_MAX_ORDER + 1];
/* 全部空闲物理页总数 */
static size_t buddy_nr_free = 0;

#define buddy_list(order) (buddy_free_area[(order)].free_list)

static size_t buddy_block_pages(int order) {
    return (size_t)1 << order;
}

/* 最小的 order，使得 2^order >= n（n=1 时 order=0） */
static int buddy_order_of(size_t n) {
    int order = 0;
    while (buddy_block_pages(order) < n) {
        order++;
    }
    return order;
}

/* 判断页号相对偏移 idx 是否按 2^order 对齐 */
static int buddy_aligned(size_t idx, int order) {
    return (idx & (buddy_block_pages(order) - 1)) == 0;
}

static void buddy_system_init(void) {
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        list_init(&buddy_list(order));
        buddy_free_area[order].nr_free = 0;
    }
    buddy_nr_free = 0;
}

/* 把 [base, base+n) 切成“最大且自身对齐”的自然块序列，逐块挂进对应阶链表。
 * 这是伙伴系统的规范初始化方式：任何一段连续空闲物理内存都能被唯一地表示成
 * 一组互不重叠、大小对齐的 2 的幂次块。 */
static void buddy_system_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    buddy_nr_free += n;

    struct Page *cur = base;
    size_t remain = n;
    while (remain > 0) {
        size_t idx = (size_t)(cur - pages); /* 相对内存起始的页偏移 */
        int order = BUDDY_MAX_ORDER;
        while (buddy_block_pages(order) > remain) {
            order--;
        }
        while (order > 0 && !buddy_aligned(idx, order)) {
            order--;
        }
        size_t size = buddy_block_pages(order);
        cur->property = (unsigned int)size;
        SetPageProperty(cur);
        list_add(&buddy_list(order), &(cur->page_link)); /* 头插（list_add 插到 head->next） */
        cur += size;
        remain -= size;
    }
}

static struct Page *buddy_system_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > buddy_nr_free) {
        return NULL;
    }
    int need = buddy_order_of(n);
    if (need > BUDDY_MAX_ORDER) {
        return NULL; /* 请求比单块上限还大 */
    }
    /* 找最小的、还有空闲块可用的阶 */
    int order = need;
    while (order <= BUDDY_MAX_ORDER && list_empty(&buddy_list(order))) {
        order++;
    }
    if (order > BUDDY_MAX_ORDER) {
        return NULL; /* 空闲页够，但被碎片切得凑不出一块连续的 */
    }

    /* 先从 order 阶链表里摘出块首（order 略大于 need 时它就是待劈开的大块，
     * order == need 时它就是要返回的块），再逐级对半劈开：
     * 右半块（buddy）挂进低阶链表，左半块继续往下劈 */
    struct Page *block = le2page(list_next(&buddy_list(order)), page_link);
    list_del_init(&block->page_link);
    ClearPageProperty(block);
    while (order > need) {
        order--;
        struct Page *buddy = block + buddy_block_pages(order);
        buddy->property = (unsigned int)buddy_block_pages(order);
        SetPageProperty(buddy);
        list_add(&buddy_list(order), &(buddy->page_link));
    }
    /* 此时 block 就是 need 阶的对齐块 */
    block->property = (unsigned int)buddy_block_pages(need);
    buddy_nr_free -= buddy_block_pages(need);
    return block;
}

static void buddy_system_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    int order = buddy_order_of(n);
    size_t size = buddy_block_pages(order);
    /* 伙伴系统按 2 的幂次整块回收：起始页必须按块大小对齐 */
    assert(buddy_aligned((size_t)(base - pages), order));

    struct Page *block = base;
    block->property = (unsigned int)size;
    SetPageProperty(block);
    buddy_nr_free += size;

    /* 沿阶往上合并：伙伴页号 = 本块页号 ^ 块大小 */
    while (order < BUDDY_MAX_ORDER) {
        size_t idx = (size_t)(block - pages);
        size_t buddy_idx = idx ^ size;
        if (buddy_idx >= (size_t)(npage - nbase)) {
            break; /* 伙伴落在可管理内存之外 */
        }
        struct Page *buddy = &pages[buddy_idx];
        if (!PageProperty(buddy) || buddy->property != size) {
            break; /* 伙伴不是同阶空闲块，本阶就是最终归属 */
        }
        list_del_init(&buddy->page_link);
        ClearPageProperty(buddy);
        if (buddy < block) {
            ClearPageProperty(block); /* 旧块首变成块内普通页，清除空闲标记 */
            block = buddy; /* 合并后取地址较小的那个作为新块首 */
        }
        size <<= 1;
        order++;
        block->property = (unsigned int)size;
        SetPageProperty(block);
    }
    list_add(&buddy_list(order), &(block->page_link));
}

static size_t buddy_system_nr_free_pages(void) {
    return buddy_nr_free;
}

//lab2 challenge 2-3 2412090
/* ------------------------- 针对伙伴系统设计的自测 -------------------------
 * 这份测试是“第二份提示词”的产物：它不满足于“能分配能释放”，而是针对伙伴
 * 系统特有的几条不变量逐条设卡：
 *   B1 初始切块：阶链表里的块必须大小对齐、property 与阶一致、总额守恒；
 *   B2 往返不变性：分配 1 页再释放，阶分布必须与分配前逐阶一致（说明 split
 *      与 coalesce 互为逆操作，且链表未被破坏）；
 *   B3 2 的幂次上取整：alloc_pages(3) 必须返回 4 页、按 4 页对齐的块；
 *   B4 拆分正确性：拆到 order 0 的过程中，每个低阶兄弟块都真的在链表里；
 *   B5 合并正确性：按 LIFO 归还后必须重新合成最初的大块；
 *   B6 边界：请求超过空闲总量要返回 NULL，而不是返回一个小块；
 *   B7 压力：连续分配 64 个单页再逆序释放，空闲页数与阶分布都必须回到原点。
 * ----------------------------------------------------------------------- */
static int buddy_check_failed = 0;

#define BUDDY_EXPECT(cond, text)                                            \
    do {                                                                    \
        if (cond) {                                                         \
            cprintf("  [ok]   %s\n", text);                                 \
        } else {                                                            \
            cprintf("  [FAIL] %s (line %d)\n", text, __LINE__);             \
            buddy_check_failed = 1;                                         \
        }                                                                   \
    } while (0)

/* 计算阶分布指纹：每个阶的块数（用于 B2 / B7 的“往返不变”判据） */
static void buddy_order_fingerprint(size_t *blocks) {
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        blocks[order] = 0;
        list_entry_t *le = &buddy_list(order);
        while ((le = list_next(le)) != &buddy_list(order)) {
            blocks[order]++;
        }
    }
}

static int buddy_order_same(size_t *a, size_t *b) {
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        if (a[order] != b[order]) {
            return 0;
        }
    }
    return 1;
}

static void buddy_system_check(void) {
    buddy_check_failed = 0;
    cprintf("[Test B] Buddy System self-test\n");
    cprintf("  total free pages = %lu, max order = %d\n",
            (unsigned long)buddy_nr_free, BUDDY_MAX_ORDER);

    size_t fingerprint[16], fp_after[16];
    size_t total = 0;
    int bad_block = 0;
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        list_entry_t *le = &buddy_list(order);
        while ((le = list_next(le)) != &buddy_list(order)) {
            struct Page *p = le2page(le, page_link);
            if (!PageProperty(p) ||
                p->property != (unsigned int)buddy_block_pages(order) ||
                !buddy_aligned((size_t)(p - pages), order)) {
                bad_block = 1;
            }
            total += p->property;
        }
    }
    buddy_order_fingerprint(fingerprint);
    BUDDY_EXPECT(!bad_block, "B1 每个空闲块都按阶对齐、property 等于块大小");
    BUDDY_EXPECT(total == buddy_nr_free, "B1 阶链表块页数之和 == 空闲页总数");

    /* B2 分配 1 页再释放：阶分布必须逐阶不变 */
    struct Page *one = alloc_page();
    BUDDY_EXPECT(one != NULL, "B2 alloc_page() 成功");
    BUDDY_EXPECT(one != NULL && !PageProperty(one), "B2 已分配的页不再是空闲块首页");
    BUDDY_EXPECT(buddy_nr_free + 1 == total, "B2 分配后空闲页数 -1");
    if (one != NULL) {
        free_page(one);
    }
    buddy_order_fingerprint(fp_after);
    BUDDY_EXPECT(buddy_order_same(fingerprint, fp_after),
                 "B2 split 与 coalesce 互为逆操作（阶分布回到原点）");
    BUDDY_EXPECT(buddy_nr_free == total, "B2 释放后空闲页数复原");

    /* B3 请求 3 页 → 必须返回 4 页、4 页对齐的块 */
    struct Page *three = alloc_pages(3);
    BUDDY_EXPECT(three != NULL, "B3 alloc_pages(3) 成功");
    if (three != NULL) {
        BUDDY_EXPECT(three->property == 4, "B3 3 页请求被上取整为 order-2（4 页）");
        BUDDY_EXPECT(buddy_aligned((size_t)(three - pages), 2),
                     "B3 返回块按 4 页对齐");
        free_pages(three, 4);
        BUDDY_EXPECT(buddy_nr_free == total, "B3 归还 4 页后空闲页数复原");
    }

    /* B4 拆分：连续分配 8 个单页，检查每一页都对齐且互不相同 */
    struct Page *v[8];
    int distinct = 1, all_ok = 1;
    for (int i = 0; i < 8; i++) {
        v[i] = alloc_page();
        if (v[i] == NULL) {
            all_ok = 0;
            break;
        }
        for (int j = 0; j < i; j++) {
            if (v[j] == v[i]) {
                distinct = 0;
            }
        }
    }
    BUDDY_EXPECT(all_ok, "B4 连续分配 8 个 order-0 块");
    BUDDY_EXPECT(distinct, "B4 8 个块的页描述符互不重复（拆分没有重叠）");
    for (int i = 7; i >= 0; i--) {
        if (v[i] != NULL) {
            free_page(v[i]);
        }
    }
    buddy_order_fingerprint(fp_after);
    BUDDY_EXPECT(buddy_order_same(fingerprint, fp_after),
                 "B5 LIFO 归还后逐级合并回最初的块（阶分布复原）");
    BUDDY_EXPECT(buddy_nr_free == total, "B5 合并后空闲页总数复原");

    /* B5+ 正序释放 + 二次整块释放：先低后高地还回两个伙伴半块，
     * 再分配并还回合并后的整块。低半块先归还时高半块还不是空闲，
     * 归还高半块时低地址伙伴已空闲，会命中 free 合并里 buddy < block
     * 的分支——旧高半块块首若不清除 PG_property，下面这次整块 free 的
     * assert(!PageProperty) 会直接 panic。 */
    struct Page *lo = alloc_pages(2), *hi = alloc_pages(2);
    BUDDY_EXPECT(lo != NULL && hi != NULL && lo < hi, "B5+ 分配两个 order-1 伙伴半块");
    if (lo != NULL && hi != NULL) {
        free_pages(lo, 2); /* 低半块先还 */
        free_pages(hi, 2); /* 高半块后还，触发 buddy < block 合并 */
        struct Page *whole = alloc_pages(4);
        BUDDY_EXPECT(whole == lo, "B5+ 两个半块合并回 order-2 整块");
        if (whole != NULL) {
            free_pages(whole, 4); /* 无修复时此处 assert(!PageProperty) panic */
        }
    }
    buddy_order_fingerprint(fp_after);
    BUDDY_EXPECT(buddy_order_same(fingerprint, fp_after),
                 "B5+ 正序归还后阶分布复原（覆盖 buddy < block 分支）");
    BUDDY_EXPECT(buddy_nr_free == total, "B5+ 正序释放后空闲页总数复原");

    /* B6 边界：请求超过空闲总量必须返回 NULL */
    BUDDY_EXPECT(alloc_pages(buddy_nr_free + 1) == NULL,
                 "B6 请求超过空闲总量返回 NULL");
    BUDDY_EXPECT(buddy_nr_free == total, "B6 失败的请求不改变空闲页数");

    /* B7 压力：64 次分配 + 逆序释放 */
    struct Page *v64[64];
    int ok64 = 1;
    for (int i = 0; i < 64; i++) {
        v64[i] = alloc_page();
        if (v64[i] == NULL) {
            ok64 = 0;
            break;
        }
    }
    for (int i = 63; i >= 0; i--) {
        if (v64[i] != NULL) {
            free_page(v64[i]);
        }
    }
    buddy_order_fingerprint(fp_after);
    BUDDY_EXPECT(ok64, "B7 连续分配 64 个单页全部成功");
    BUDDY_EXPECT(buddy_order_same(fingerprint, fp_after),
                 "B7 压力测试后阶分布回到原点（无泄漏、无碎片残留）");
    BUDDY_EXPECT(buddy_nr_free == total, "B7 压力测试后空闲页数守恒");

    if (buddy_check_failed) {
        cprintf("[Test B] Buddy System: FAIL\n");
    } else {
        cprintf("[Test B] Buddy System: PASS\n");
    }
}

/* 注册伙伴系统管理器；.check 直接指向上面这份自测 */
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = buddy_system_check,
};
