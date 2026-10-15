#include <assert.h>
#include <defs.h>
#include <list.h>
#include <mmu.h>
#include <pmm.h>
#include <slub_pmm.h>
#include <stdio.h>
#include <string.h>

//lab2 challenge 2-4 2412090
/* ===========================================================================
 * SLUB 实现（对象级缓存）
 *
 * 一、三层数据结构
 *   ① kmem_cache：一个“大小档次”对应一个缓存，记录该档次的对象大小、一个
 *      slab 占几页、以及属于它的所有 slab 构成的循环双向链表。
 *      全部 cache 静态驻留在内核 .bss（14 个），管理结构本身不再额外花页。
 *   ② kmem_slab：一个 slab 就是一段连续的物理页，被切成 nr_objects 个等大
 *      对象。slab 的元数据放在这段内存的最前面（64 字节），对象区从第 64 字节
 *      开始 —— 于是 free() 只要把指针向下按页对齐，就能 O(1) 找回它的 slab，
 *      不需要页号->slab 的全局映射表。（这条 O(1) 回溯依赖一条不变式：段首元
 *      数据与所有对象的“起始地址”都落在 slab 的第 0 页内，由
 *      slub_slab_capacity() 保证，详见该函数上方的说明。）
 *   ③ 对象自由链表：空闲对象本身的前 8 字节存下一个空闲对象的地址（侵入式
 *      链表），因此不需要额外的位图或空闲数组。
 *
 * 二、分配与释放
 *   alloc：大小 -> 档次 -> 在该 cache 的 slab 链上找第一个“没装满”的 slab ->
 *          从它的自由链表摘一个对象。找不到就向第一层要一段连续页，造一个新 slab。
 *   free ：指针向下页对齐 -> 校验魔数 -> 对象插回自由链表 -> in_use--。
 *          若整个 slab 空了，就把它整段还给第一层（页级分配器）并同步统计量，
 *          于是内存不会长期滞留在对象层。
 *
 * 三、与真实 Linux SLUB 的差距（本实验刻意简化的部分，指导书允许）
 *   - 没有 per-CPU 的 cpu_slab 与“页面冻结/批量刷新”机制；
 *   - 没有 NUMA 节点、没有 cgroup 记账、没有 slab 合并（slab merging）；
 *   - 没有“满 slab / 部分空 slab”分级链表，只有一条链（分配时线性找第一个未满）；
 *   - 没有任何并发保护：lab2 阶段尚未开启中断与多核调度，对象层只在单核、
 *     不可抢占的上下文里被调用（后续 lab 真正需要时应加自旋锁）。
 *   - 大于 64 KiB 的对象本实验不支持（返回 NULL）：真实内核在这一档会直接退回
 *     页级分配/vmalloc，那是另一套基于虚拟地址连续性的机制，不属于本 challenge。
 *   以上都不影响“两层架构 + 按大小分档 + 页内切分对象 + 空 slab 归还”这条主体
 *   思想——这正是指导书要求的“能够体现其主体思想即可”。
 * ========================================================================= */

/* 大小档次：8 B 起，按 2 的幂次一直到 64 KiB，共 14 档 */
#define SLUB_MIN_SHIFT   3      /* 2^3  = 8     B  */
#define SLUB_MAX_SHIFT   16     /* 2^16 = 65536 B  */
#define SLUB_NR_CLASSES  (SLUB_MAX_SHIFT - SLUB_MIN_SHIFT + 1)

/* slab 元数据在段内占据的前 64 字节（结构体 48 字节向上取整到 64，保证对象区
 * 起点整齐，并且至少满足 8 字节对齐） */
#define SLUB_META_SIZE   64

/* slab 元数据魔数：free() 用它校验“这个指针确实是我们发出去的” */
#define SLUB_SLAB_MAGIC  0x534C5542UL   /* 'S','L','U','B' */

typedef struct kmem_cache kmem_cache_t;
typedef struct kmem_slab  kmem_slab_t;

struct kmem_cache {
    list_entry_t slabs;             /* 本 cache 的全部 slab（双向循环链表） */
    size_t objsize;                 /* 档次大小（字节，2 的幂次） */
    size_t slab_pages;              /* 一个 slab 占多少页（2 的幂次） */
    size_t capacity;                /* 一个 slab 能装多少个对象 */
    size_t nr_slabs;                /* 当前 slab 个数 */
    size_t nr_objects_total;        /* 当前全部 slab 的容量之和 */
    size_t nr_objects_used;         /* 当前已分配对象个数 */
};

struct kmem_slab {
    list_entry_t  link;             /* 挂进 kmem_cache.slabs */
    void         *freelist;         /* 段内空闲对象自由链表头 */
    uint32_t      magic;            /* SLUB_SLAB_MAGIC */
    uint32_t      nr_objects;       /* 本 slab 容量（对象个数） */
    uint32_t      in_use;           /* 已分配对象个数 */
    uint32_t      pad;              /* 对齐填充 */
    kmem_cache_t *cache;            /* 反向指针：free() 直接拿到归属缓存 */
};

static kmem_cache_t slub_caches[SLUB_NR_CLASSES];
static size_t slub_pages_held = 0;      /* 当前向第一层持有的页数 */
static size_t slub_objects_used = 0;    /* 当前已分配出去的对象数 */
static int    slub_check_failed = 0;    /* 自检失败标志 */

#define le2slab(le)  to_struct((le), kmem_slab_t, link)

/* ---------------------------------------------------------------------------
 * 档次计算
 * ------------------------------------------------------------------------- */

/* 档次 idx 对应的对象大小 */
static size_t
slub_class_objsize(int idx) {
    return (size_t)1 << (SLUB_MIN_SHIFT + idx);
}

/* 把请求大小向上取整到最近档次的“下标”；
 * 超出最大档次时返回 SLUB_NR_CLASSES（调用方据此拒绝请求） */
static int
slub_class_index(size_t size) {
    int idx = 0;
    size_t s = (size_t)1 << SLUB_MIN_SHIFT;
    while (s < size) {
        s <<= 1;
        idx++;
    }
    return idx;
}

/* 一个 slab 需要几页：取最小的 2 的幂次 k，使 k 页至少装得下“元数据 + 1 个对象”。
 * 取 2 的幂次是为了让第一层换成 Buddy System 时也能整除地服务；
 * 究竟一个 slab 装几个对象由 slub_slab_capacity() 决定。 */
static size_t
slub_slab_pages_for(size_t objsize) {
    size_t need = SLUB_META_SIZE + objsize;
    size_t pages = 1;
    while (pages * PGSIZE < need) {
        pages <<= 1;
    }
    return pages;
}

/* 一个 slab 能装多少个对象。
 *
 * 这里有一条贯穿全模块的关键不变式：
 *     **段首元数据与所有对象的“起始地址”都落在 slab 的第 0 页内。**
 * 因为 free() 手上只有一个对象指针，它是靠“指针向下按页对齐”去回溯段首元数据
 * 的（ptr & ~(PGSIZE-1)）；只有所有对象起点都在第 0 页，这个式子才一定等于
 * slab 段首。一旦允许对象的起点落到后面的页里，free() 就会把“后面的某一页”
 * 误当成段首，读到错误的魔数而拒绝释放，造成对象与整段页的泄漏。
 * 于是容量取下面两个上界的较小者：
 *     ① 整段装得下： (slab_pages*PGSIZE - SLUB_META_SIZE) / objsize
 *     ② 起点不越页： (PGSIZE - SLUB_META_SIZE - 1) / objsize + 1
 * 对 ≤1 KiB 的档次 ① 更紧，得到一个 slab 页内打包多个对象（如 16 B 档次一页
 * 放 252 个）；对 ≥2 KiB 的档次 ② 更紧，容量被压到 1，即“一个大对象独占一段
 * 连续页”——这与真实内核里大对象绕过 slab、直接走页级分配器的做法一致。
 * 代价是大对象会多占一段连续页（2 的幂次对齐，最坏 2 倍），换来的好处是
 * free() 严格 O(1)，且完全不需要额外的“页号 -> slab”反查表。 */
static size_t
slub_slab_capacity(const kmem_cache_t *c) {
    size_t by_fit = (c->slab_pages * PGSIZE - SLUB_META_SIZE) / c->objsize;
    size_t by_page = (PGSIZE - SLUB_META_SIZE - 1) / c->objsize + 1;
    return by_fit < by_page ? by_fit : by_page;
}

/* ---------------------------------------------------------------------------
 * 初始化：只初始化管理结构，不申请任何物理页（页在第一次分配该档次时才借）
 * ------------------------------------------------------------------------- */
void
slub_init(void) {
    static_assert(sizeof(kmem_slab_t) <= SLUB_META_SIZE);
    for (int i = 0; i < SLUB_NR_CLASSES; i++) {
        kmem_cache_t *c = &slub_caches[i];
        list_init(&c->slabs);
        c->objsize = slub_class_objsize(i);
        c->slab_pages = slub_slab_pages_for(c->objsize);
        c->capacity = slub_slab_capacity(c);
        c->nr_slabs = 0;
        c->nr_objects_total = 0;
        c->nr_objects_used = 0;
    }
    slub_pages_held = 0;
    slub_objects_used = 0;
    slub_check_failed = 0;
}

/* ---------------------------------------------------------------------------
 * 造一个新 slab：第一层拿页，第二层把页切成对象串成自由链表
 * ------------------------------------------------------------------------- */
static kmem_slab_t *
slub_new_slab(kmem_cache_t *c) {
    struct Page *page = alloc_pages(c->slab_pages);
    if (page == NULL) {
        return NULL;                    /* 第一层也没有内存了：OOM 向上传递 */
    }

    /* KADDR 宏在本 lab 的 pmm.h 里被注释掉了，这里用 page2pa 加上内核线性
     * 映射偏移量手工做到“物理页 -> 内核虚拟地址”。 */
    kmem_slab_t *slab = (kmem_slab_t *)((uintptr_t)page2pa(page) + va_pa_offset);

    /* 容量在 slub_init() 里就按“对象起点不越页”的不变式算好了，这里直接用 */
    size_t capacity = c->capacity;
    assert(capacity > 0);

    slab->magic = SLUB_SLAB_MAGIC;
    slab->nr_objects = (uint32_t)capacity;
    slab->in_use = 0;
    slab->cache = c;
    slab->freelist = NULL;
    slab->pad = 0;

    /* 从对象区尾部往前串，串完后 freelist 指向第 0 个对象：
     * 分配时先给低地址，便于人工核对页内布局。 */
    uint8_t *area = (uint8_t *)slab + SLUB_META_SIZE;
    for (size_t i = capacity; i > 0; i--) {
        void *obj = area + (i - 1) * c->objsize;
        *(void **)obj = slab->freelist;
        slab->freelist = obj;
    }

    list_add(&c->slabs, &slab->link);
    c->nr_slabs++;
    c->nr_objects_total += capacity;
    slub_pages_held += c->slab_pages;
    return slab;
}

/* ---------------------------------------------------------------------------
 * 分配：size -> 档次 -> 找一个没装满的 slab -> 摘对象
 * ------------------------------------------------------------------------- */
void *
slub_alloc(size_t size) {
    if (size == 0) {
        return NULL;
    }
    int idx = slub_class_index(size);
    if (idx >= SLUB_NR_CLASSES) {
        cprintf("[SLUB] alloc(%lu B) rejected: max object size is %lu B\n",
                (unsigned long)size,
                (unsigned long)slub_class_objsize(SLUB_NR_CLASSES - 1));
        return NULL;
    }
    kmem_cache_t *c = &slub_caches[idx];

    /* 在 slab 链上找第一个还有空对象的 slab */
    kmem_slab_t *slab = NULL;
    list_entry_t *le = &c->slabs;
    while ((le = list_next(le)) != &c->slabs) {
        kmem_slab_t *s = le2slab(le);
        if (s->in_use < s->nr_objects) {
            slab = s;
            break;
        }
    }
    if (slab == NULL) {                 /* 链上没有空位：向第一层要页造新 slab */
        slab = slub_new_slab(c);
        if (slab == NULL) {
            return NULL;
        }
    }

    void *obj = slab->freelist;
    assert(obj != NULL);
    slab->freelist = *(void **)obj;      /* 自由链表是侵入式的：头 8 字节存 next */
    slab->in_use++;
    c->nr_objects_used++;
    slub_objects_used++;
    return obj;
}

/* ---------------------------------------------------------------------------
 * 释放：页对齐找回 slab -> 对象回链 -> 整段空的 slab 还给第一层
 * ------------------------------------------------------------------------- */
void
slub_free(void *ptr) {
    if (ptr == NULL) {
        return;
    }
    /* slab 元数据就在这段内存第一页的页首，所以向下页对齐即可找回 slab */
    kmem_slab_t *slab = (kmem_slab_t *)((uintptr_t)ptr & ~(uintptr_t)(PGSIZE - 1));
    if (slab->magic != SLUB_SLAB_MAGIC) {
        warn("slub_free: %p is not a slub object (magic=0x%lx)", ptr,
             (unsigned long)slab->magic);
        return;
    }
    assert(slab->in_use > 0);
    kmem_cache_t *c = slab->cache;

    *(void **)ptr = slab->freelist;      /* 对象头 8 字节改存下一个空闲对象 */
    slab->freelist = ptr;
    slab->in_use--;
    c->nr_objects_used--;
    slub_objects_used--;

    /* 整个 slab 都空了：整段归还第一层，避免对象层长期占页 */
    if (slab->in_use == 0) {
        list_del(&slab->link);
        c->nr_slabs--;
        c->nr_objects_total -= slab->nr_objects;
        slub_pages_held -= c->slab_pages;
        slab->magic = 0;
        free_pages(pa2page(PADDR((uintptr_t)slab)), c->slab_pages);
    }
}

/* ---------------------------------------------------------------------------
 * 只读观测接口
 * ------------------------------------------------------------------------- */
size_t
slub_nr_caches(void) {
    size_t n = 0;
    for (int i = 0; i < SLUB_NR_CLASSES; i++) {
        if (slub_caches[i].nr_slabs > 0) {
            n++;
        }
    }
    return n;
}

size_t
slub_total_pages(void) {
    return slub_pages_held;
}

size_t
slub_allocated_objects(void) {
    return slub_objects_used;
}
/* ===========================================================================
 * 自检 slub_check()
 *
 * 覆盖三类内容：
 *   A. 核心行为：档次映射 / 首次分配建 slab / 同 slab 打包 / 档次隔离 /
 *                LIFO 复用 / 空 slab 整段归还 / 跨页大 slab / 全档次遍历；
 *   B. 边界情况：size == 0、超出最大档次、远大于一页的请求、free(NULL)、
 *                第一层 OOM（页级分配失败）；
 *   C. 总量守恒：全部释放后对象层不再持有任何页，页级空闲页数回到初值。
 * ========================================================================= */

#define SLUB_EXPECT(cond, ...)                                  \
    do {                                                        \
        if (cond) {                                             \
            cprintf("  [ok]   ");                               \
        } else {                                                \
            cprintf("  [FAIL] ");                              \
            slub_check_failed = 1;                              \
        }                                                       \
        cprintf(__VA_ARGS__);                                   \
        cprintf("\n");                                          \
    } while (0)

/* 一个“永远拿不到页”的桩管理器：用来在自检里真实触发第一层的 OOM 分支 */
static void slub_stub_init(void) { }
static void slub_stub_init_memmap(struct Page *base, size_t n) { (void)base; (void)n; }
static struct Page *slub_stub_alloc_pages(size_t n) { (void)n; return NULL; }
static void slub_stub_free_pages(struct Page *base, size_t n) { (void)base; (void)n; }
static size_t slub_stub_nr_free_pages(void) { return 0; }
static void slub_stub_check(void) { }

static const struct pmm_manager slub_oom_pmm_manager = {
    .name = "slub_oom_stub_pmm_manager",
    .init = slub_stub_init,
    .init_memmap = slub_stub_init_memmap,
    .alloc_pages = slub_stub_alloc_pages,
    .free_pages = slub_stub_free_pages,
    .nr_free_pages = slub_stub_nr_free_pages,
    .check = slub_stub_check,
};

void
slub_check(void) {
    size_t free_before = nr_free_pages();
    size_t pages0 = slub_total_pages();
    size_t caches0 = slub_nr_caches();
    slub_check_failed = 0;

    cprintf("[Test S] SLUB self-test\n");
    cprintf("  classes: %d, min = %lu B, max = %lu B\n", SLUB_NR_CLASSES,
            (unsigned long)slub_class_objsize(0),
            (unsigned long)slub_class_objsize(SLUB_NR_CLASSES - 1));

    /* ---------- S1 大小档次映射 ---------- */
    SLUB_EXPECT(slub_class_index(1) == 0, "S1 alloc(1 B)  -> 8 B 档次");
    SLUB_EXPECT(slub_class_index(8) == 0, "S1 alloc(8 B)  -> 8 B 档次（边界值正好命中）");
    SLUB_EXPECT(slub_class_index(9) == 1, "S1 alloc(9 B)  -> 16 B 档次（向上取整）");
    SLUB_EXPECT(slub_class_index(17) == 2, "S1 alloc(17 B) -> 32 B 档次");
    SLUB_EXPECT(slub_class_index(4096) == 9, "S1 alloc(4096 B) -> 4 KiB 档次");
    SLUB_EXPECT(slub_class_index(65536) == SLUB_NR_CLASSES - 1, "S1 alloc(64 KiB) -> 最大档次");
    SLUB_EXPECT(slub_class_index(65537) == SLUB_NR_CLASSES, "S1 alloc(64 KiB + 1) 已在档次表之外");

    /* ---------- S2 首次分配：只花 slab_pages 页 ---------- */
    void *a = slub_alloc(16);
    SLUB_EXPECT(a != NULL, "S2 首次 slub_alloc(16) 成功");
    SLUB_EXPECT(slub_nr_caches() == caches0 + 1, "S2 首次分配建立 1 个 16 B 缓存");
    SLUB_EXPECT(slub_total_pages() == pages0 + 1, "S2 首块 slab 只占 1 页");
    SLUB_EXPECT(slub_allocated_objects() == 1, "S2 已分配对象计数 = 1");

    /* ---------- S3 同 slab 打包：32 个 16 B 对象应落在同一页 ---------- */
    void *packed[31];
    const uintptr_t page_of_a = (uintptr_t)a & ~(uintptr_t)(PGSIZE - 1);
    int packed_ok = 1, same_page = 1;
    for (int i = 0; i < 31; i++) {
        packed[i] = slub_alloc(16);
        if (packed[i] == NULL) {
            packed_ok = 0;
            break;
        }
        if (((uintptr_t)packed[i] & ~(uintptr_t)(PGSIZE - 1)) != page_of_a) {
            same_page = 0;
        }
    }
    SLUB_EXPECT(packed_ok, "S3 连续分配 32 个 16 B 对象全部成功");
    SLUB_EXPECT(same_page, "S3 32 个 16 B 对象打包在同一个 slab 页内");
    SLUB_EXPECT(slub_total_pages() == pages0 + 1, "S3 打包过程没有再向第一层要页");

    /* ---------- S4 对象互不重叠、至少 8 字节对齐 ---------- */
    int distinct = 1, aligned = 1;
    for (int i = 0; i < 31; i++) {
        if (packed[i] == NULL) {
            continue;
        }
        if (((uintptr_t)packed[i] % 8) != 0) {
            aligned = 0;
        }
        if (packed[i] == a) {
            distinct = 0;
        }
        for (int j = 0; j < i; j++) {
            if (packed[j] != NULL && packed[j] == packed[i]) {
                distinct = 0;
            }
        }
    }
    SLUB_EXPECT(aligned, "S4 对象地址均满足 8 字节对齐");
    SLUB_EXPECT(distinct, "S4 32 个对象两两不重叠");

    /* ---------- S5 档次隔离 ---------- */
    void *b = slub_alloc(200);          /* 200 B -> 256 B 档次 */
    SLUB_EXPECT(b != NULL, "S5 分配 200 B 对象成功（上取整到 256 B 档次）");
    SLUB_EXPECT(((uintptr_t)b & ~(uintptr_t)(PGSIZE - 1)) != page_of_a,
                "S5 256 B 档次与 16 B 档次使用不同的 slab");
    SLUB_EXPECT(slub_nr_caches() == caches0 + 2, "S5 活跃缓存数 = 2");

    /* ---------- S6 释放后 LIFO 复用 ---------- */
    void *first = packed[0];
    slub_free(first);
    packed[0] = NULL;
    void *reused = slub_alloc(16);
    SLUB_EXPECT(reused == first, "S6 释放后立刻分配，原样复用同一个对象（自由链表 LIFO）");

    /* ---------- S7 空 slab 整段归还第一层 ---------- */
    slub_free(a);
    for (int i = 1; i < 31; i++) {
        slub_free(packed[i]);
    }
    slub_free(reused);                  /* reused 就是原来的 packed[0] */
    SLUB_EXPECT(slub_allocated_objects() == 1, "S7 16 B 档全部释放后只剩 1 个 256 B 对象在用");
    SLUB_EXPECT(slub_total_pages() == pages0 + 1, "S7 空的 16 B slab 已整段归还，只剩 256 B 那一页");

    slub_free(b);
    SLUB_EXPECT(slub_allocated_objects() == 0, "S7 全部释放后已分配对象数为 0");
    SLUB_EXPECT(slub_total_pages() == pages0, "S7 全部释放后对象层不再持有任何物理页");
    SLUB_EXPECT(slub_nr_caches() == 0, "S7 全部释放后没有活跃缓存残留");

    /* ---------- S8 全档次遍历（覆盖跨页大 slab，直到 64 KiB） ---------- */
    {
        size_t pages_before_s8 = slub_total_pages();
        int all_ok = 1;
        for (int cls = 0; cls < SLUB_NR_CLASSES; cls++) {
            size_t sz = slub_class_objsize(cls);
            void *o0 = slub_alloc(sz);
            void *o1 = slub_alloc(sz);
            if (o0 == NULL || o1 == NULL || o0 == o1) {
                all_ok = 0;
                cprintf("  [--]   S8 档次 %lu B 分配异常\n", (unsigned long)sz);
            }
            if (o0 != NULL) {
                slub_free(o0);
            }
            if (o1 != NULL) {
                slub_free(o1);
            }
        }
        SLUB_EXPECT(all_ok, "S8 全部 %d 个档次都能分配出 2 个互不相同的对象", SLUB_NR_CLASSES);
        SLUB_EXPECT(slub_total_pages() == pages_before_s8, "S8 全档次遍历后持有的页数复原");
    }

    /* ---------- S9 边界：非法请求 ---------- */
    SLUB_EXPECT(slub_alloc(0) == NULL, "S9 slub_alloc(0) 返回 NULL（尺寸不合法）");
    SLUB_EXPECT(slub_alloc(65537) == NULL, "S9 超出最大档次（64 KiB + 1）的请求返回 NULL");
    SLUB_EXPECT(slub_alloc((size_t)1 << 20) == NULL, "S9 1 MiB 请求返回 NULL");
    slub_free(NULL);
    SLUB_EXPECT(slub_allocated_objects() == 0 && slub_total_pages() == pages0,
                "S9 slub_free(NULL) 安全，且非法请求没有留下记账残留");

    /* ---------- S10 第一层 OOM：页级分配失败必须干净地向上传递 ---------- */
    {
        const struct pmm_manager *saved = pmm_manager;
        size_t pages_before_oom = slub_total_pages();
        size_t objs_before_oom = slub_allocated_objects();
        pmm_manager = &slub_oom_pmm_manager;
        void *oom = slub_alloc(1024);   /* 1 KiB 档此前没被用过 -> 必须新建 slab */
        pmm_manager = saved;
        SLUB_EXPECT(oom == NULL, "S10 第一层无页可取时 slub_alloc 返回 NULL");
        SLUB_EXPECT(slub_total_pages() == pages_before_oom &&
                    slub_allocated_objects() == objs_before_oom,
                    "S10 OOM 失败没有留下记账残留");
        SLUB_EXPECT(pmm_manager == saved, "S10 自检结束后 pmm_manager 已复原");
    }

    /* ---------- S11 总量守恒 ---------- */
    {
        void *v[8];
        int ok = 1;
        for (int i = 0; i < 8; i++) {
            v[i] = slub_alloc(128);
            if (v[i] == NULL) {
                ok = 0;
            }
        }
        SLUB_EXPECT(ok, "S11 8 个 128 B 对象全部分配成功");
        for (int i = 0; i < 8; i++) {
            if (v[i] != NULL) {
                slub_free(v[i]);
            }
        }
    }
    SLUB_EXPECT(slub_allocated_objects() == 0, "S11 全部释放后已分配对象数为 0");
    SLUB_EXPECT(slub_total_pages() == pages0, "S11 对象层持有的页数回到初值");
    SLUB_EXPECT(slub_nr_caches() == 0, "S11 没有活跃缓存残留");
    SLUB_EXPECT(nr_free_pages() == free_before, "S11 页级空闲页数回到自检开始时的值（无泄漏）");

    /* ---------- S12 设计不变式：所有对象的起点都落在 slab 第 0 页内 ----------
     * 这是 free() 能靠“向下页对齐”O(1) 找回段首元数据的前提，也是本次自检
     * 抓到过的那个 bug 的正面对应断言（当时 4 KiB 及以上档次的第 2 个对象起点
     * 落在第 1 页，free() 读错了页的魔数，对象和整段页都泄漏了）。 */
    {
        int inv_ok = 1;
        for (int i = 0; i < SLUB_NR_CLASSES; i++) {
            const kmem_cache_t *c = &slub_caches[i];
            size_t last_start = SLUB_META_SIZE + (c->capacity - 1) * c->objsize;
            if (c->capacity == 0 || last_start >= PGSIZE ||
                SLUB_META_SIZE + c->capacity * c->objsize > c->slab_pages * PGSIZE) {
                inv_ok = 0;
                cprintf("  [--]   档次 %lu B 违反不变式（capacity=%lu, pages=%lu）\n",
                        (unsigned long)c->objsize, (unsigned long)c->capacity,
                        (unsigned long)c->slab_pages);
            }
        }
        SLUB_EXPECT(inv_ok,
                    "S12 设计不变式：全部 %d 个档次的对象起点都落在 slab 第 0 页内",
                    SLUB_NR_CLASSES);
    }

    if (slub_check_failed) {
        cprintf("[Test S] SLUB: FAIL\n");
    } else {
        cprintf("[Test S] SLUB: PASS\n");
    }
}
