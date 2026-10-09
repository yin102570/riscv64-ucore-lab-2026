/* 内核栈尺寸常量。被 .S 包含，故只能有宏；KSTACKSIZE 用到 PGSIZE，
   但本文件没 #include <mmu.h>，依赖包含者（entry.S）先引入 —— 属隐式依赖。 */
#ifndef __KERN_MM_MEMLAYOUT_H__
#define __KERN_MM_MEMLAYOUT_H__

/* 内核栈占 2 个物理页。 */
#define KSTACKPAGE          2                           // # of pages in kernel stack
/* = 2 × 4096 = 8192 字节，entry.S 的 .space KSTACKSIZE 用它预留空间。 */
#define KSTACKSIZE          (KSTACKPAGE * PGSIZE)       // sizeof kernel stack

#endif /* !__KERN_MM_MEMLAYOUT_H__ */

