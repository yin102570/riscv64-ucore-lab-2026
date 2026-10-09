/* 页大小定义。全项目只有 entry.S 包含它，且本阶段未启用分页 —— 页只用来对齐内核栈。 */
#ifndef __KERN_MM_MMU_H__
#define __KERN_MM_MMU_H__

/* 一页 4096 字节（SV39 最小页大小），本实验的基本单位。 */
#define PGSIZE          4096                    // bytes mapped by a page
/* log2(PGSIZE)=12，页内偏移位数；地址右移 12 位即得物理页号。 */
#define PGSHIFT         12                      // log2(PGSIZE)

#endif /* !__KERN_MM_MMU_H__ */
