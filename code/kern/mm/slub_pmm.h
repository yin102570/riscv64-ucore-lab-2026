#ifndef __KERN_MM_SLUB_PMM_H__
#define __KERN_MM_SLUB_PMM_H__

#include <defs.h>

//lab2 challenge 2-4 2412090
/* ===========================================================================
 * SLUB：两层架构的任意大小内存对象分配器
 *
 *   第一层（页级）：复用框架既有的 pmm_manager（本 lab 的评分路径是 Best-Fit，
 *                   也可换成 Buddy System）以“页”为单位拿内存；
 *   第二层（对象级）：把整页切分成固定大小的对象（object），按大小档次
 *                   （size class，2 的幂次）建立 kmem_cache，每个 cache 用
 *                   “slab 链 + 页内对象自由链表”管理。
 *
 * 对外只暴露两个动作：
 *   slub_alloc(size)  按大小分配一个对象，成功返回对象首地址，失败返回 NULL；
 *   slub_free(ptr)    按指针释放，指针为 NULL 时安全无操作。
 *
 * 请求大小先向上取整到最近的大小档次，因此“任意大小”由 8 B ~ 64 KiB 共 14 个
 * 档次覆盖；超过 64 KiB 的请求返回 NULL 并打印诊断信息（真实内核在这一档会退化
 * 为按页分配/vmalloc，本实验不做，见 slub_pmm.c 顶部说明）。
 * ===========================================================================
 */

void slub_init(void);       /* 初始化对象级缓存；不申请任何物理页 */
void slub_check(void);      /* 完整自检：核心行为 + 边界情况 + 总量守恒 */

void *slub_alloc(size_t size);  /* 分配不小于 size 字节的对象；失败返回 NULL */
void slub_free(void *ptr);      /* 释放 slub_alloc() 返回的指针；NULL 安全 */

/* ---- 只读观测接口（自检与报告取证用）---- */
size_t slub_nr_caches(void);          /* 当前的“活跃”缓存个数（有 slab 的档次） */
size_t slub_total_pages(void);        /* 当前向第一层持有的物理页数 */
size_t slub_allocated_objects(void);  /* 当前已分配出去的对象数 */

#endif /* !__KERN_MM_SLUB_PMM_H__ */
