#include <best_fit_pmm.h>
#include <buddy_system_pmm.h>
#include <default_pmm.h>
#include <defs.h>
#include <dtb.h>
#include <error.h>
#include <list.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <riscv.h>
#include <slub_pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>

// virtual address of physical page array
struct Page *pages;
// amount of physical memory (in pages)
size_t npage = 0;
// the kernel image is mapped at VA=KERNBASE and PA=info.base
uint64_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
// DRAM_BASE defined in riscv.h as 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;
// physical address of boot-time page directory
uintptr_t satp_physical;

// physical memory management
const struct pmm_manager *pmm_manager;


static void check_alloc_page(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
//lab2 function2-2 2410749
    /* 本 lab 的评分脚本 tools/grade.sh 会检查 [Test 2] Best-Fit: PASS，
     * 即要求 pmm_init() 执行时 pmm_manager 指向 best_fit_pmm_manager，
     * 所以这里默认选择 Best-Fit（不再是框架默认的 First-Fit）。
     *
     * 为了能独立复现两个 Challenge（Buddy System / SLUB）的算法自测，
     * 另外两种物理内存管理器用编译期宏留成可选，默认全部关闭，
     * 不影响评分路径：
     *     make DEFS=-DUSE_BUDDY_PMM        → 用伙伴系统替换页级分配器
     *     make DEFS=-DCHALLENGE_SLUB_TEST  → 在 Best-Fit 之上跑 SLUB 自测
     */
#if defined(USE_BUDDY_PMM)
    pmm_manager = &buddy_system_pmm_manager;
#else
    pmm_manager = &best_fit_pmm_manager;
#endif
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
}

//lab2 function1 2410665
/* page_init - 物理内存探测与页描述符初始化
 *
 * 上下游关系：dtb_init() 已经把设备树探测到的物理内存起止写入 get_memory_base()
 * / get_memory_size()；init_pmm_manager() 已经选好并初始化了页级分配器；本函数把
 * “一段真实可用的空闲物理页区间”交给它，并准备好全部地址转换所需的全局状态。
 *
 * 四件必须做对的事：
 *   ① va_pa_offset 必须等于内核线性映射偏移 PHYSICAL_MEMORY_OFFSET，
 *      否则 PADDR/KADDR 之后全部失效；
 *   ② npage 是“内存末端对应的物理页号”，pages[] 只描述 [nbase, npage)
 *      这段真实存在的物理页（下标 i ↔ 物理页号 nbase + i）；
 *   ③ 页描述符数组放在内核镜像 end 之后、且必须页对齐，数组自身占用的页
 *      绝不能被分配出去；
 *   ④ 先把 [nbase, npage) 全部置为“保留”，再把扣掉内核镜像与描述符数组
 *      之后的完整空闲区间交给 init_memmap()；没有完整空闲页时不得调用它。
 */
static void page_init(void) {
    extern char end[]; /* 链接脚本 tools/kernel.ld 定义的“内核镜像末尾”符号 */

    /* ① 内核镜像按 va - pa = PHYSICAL_MEMORY_OFFSET 做线性映射 */
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;

    /* ② 设备树探测结果；无效则终止初始化 */
    uint64_t mem_base = get_memory_base();
    uint64_t mem_size = get_memory_size();
    if (mem_base == 0 || mem_size == 0) {
        panic("page_init: invalid physical memory info from DTB");
    }

    uintptr_t pbegin = (uintptr_t)mem_base;
    uintptr_t pend = (uintptr_t)(mem_base + mem_size);
    /* 可管理上界向下页对齐：末尾不足一页的残段不构成完整物理页 */
    pend = ROUNDDOWN(pend, PGSIZE);
    if (pend <= pbegin) {
        panic("page_init: physical memory range is empty");
    }

    /* ③ npage = PPN(内存末端)；pages[] 长度为 npage - nbase */
    npage = PPN(pend);
    if (npage <= nbase) {
        panic("page_init: no manageable physical page");
    }

    cprintf("physical memory map:\n");
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size,
            mem_base, mem_base + mem_size - 1);

    /* ④ 页描述符数组：紧跟内核镜像 end 之后，页对齐 */
    uintptr_t pages_va = ROUNDUP((uintptr_t)end, PGSIZE);
    uintptr_t pages_pa = PADDR(pages_va);
    size_t pages_num = npage - nbase;
    uintptr_t pages_end_pa = pages_pa + pages_num * sizeof(struct Page);
    if (pages_end_pa > pend) {
        panic("page_init: page descriptor array does not fit in memory");
    }
    pages = (struct Page *)pages_va;

    /* ⑤ 先把 [nbase, npage) 的每个物理页都标记为“保留”，
     *    这样内核镜像区间和描述符数组区间天然不会被分配出去，
     *    同时满足 default/best_fit_init_memmap 里的 assert(PageReserved(p))。 */
    for (size_t i = 0; i < pages_num; i++) {
        pages[i].flags = 0;
        pages[i].property = 0;
        set_page_ref(&pages[i], 0);
        list_init(&pages[i].page_link);
        SetPageReserved(&pages[i]);
    }

    /* ⑥ 空闲区 = [描述符数组末尾向上取整, 内存末尾) */
    uintptr_t free_start_pa = ROUNDUP(pages_end_pa, PGSIZE);
    if (free_start_pa >= pend) {
        cprintf("page_init: warning: no free page available\n");
        return;
    }
    init_memmap(pa2page(free_start_pa), (pend - free_start_pa) / PGSIZE);
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();

//lab2 challenge 2-4 2412090
#if defined(CHALLENGE_SLUB_TEST)
    /* 在第一层（页级分配器）之上跑 SLUB 第二层自测 */
    slub_init();
    slub_check();
#endif

    extern char boot_page_table_sv39[];
    satp_virtual = (pte_t*)boot_page_table_sv39;
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}
