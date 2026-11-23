# Lab4 功能模块一：虚拟内存页操作

## 1. 范围

本模块只修改 `kern/mm/pmm.c`，完成：

```c
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm);
void page_remove(pde_t *pgdir, uintptr_t la);
```

不修改 `get_pte()`、`struct Page`、`struct pmm_manager`、`boot_map_segment()`，也不在本模块引入缺页异常、VMA 换页或用户进程地址空间。Lab4 是预映射：映射在建立时一次性完成。

## 2. Spec

### 2.1 `page_insert()`

**输入**

- `pgdir`：页表根，使用内核虚拟地址；
- `page`：要映射的物理页描述符；
- `la`：目标线性地址；
- `perm`：叶页表项权限位，不含 `PTE_V`；`PTE_V` 由 `pte_create()` 负责。

**成功语义**

1. 目标线性地址最终稳定映射到 `page`；
2. 叶页表项权限等于 `perm` 与 `pte_create()` 自动加入的 `PTE_V` 的组合；
3. 若目标地址原本没有映射，`page->ref` 增加 1；
4. 若目标地址原本映射到另一个物理页，旧页引用减少，必要时释放旧页，新页引用增加 1；
5. 若目标地址原本已映射到同一个 `page`，只更新权限和页表项，不改变引用计数；
6. 页表项更新后使对应 TLB 项失效。

**失败语义**

- `get_pte(pgdir, la, 1)` 返回 `NULL` 时返回 `-E_NO_MEM`；
- 失败时不能写入一张“已经指向新页、但调用者收到失败”的叶页表项；
- 当前骨架的 `get_pte()` 可能在第二级页表分配失败时留下一个空的中间页表页；本模块不擅自重写 `get_pte()`，但报告要把这个资源边界写清楚，不能声称完全没有中间页表开销。

### 2.2 `page_remove()`

**输入**：页表根 `pgdir` 和目标线性地址 `la`。

**成功语义**

1. 目标地址有有效映射时，清空叶页表项，减少物理页引用；
2. 引用归零时释放物理页；
3. 目标地址无映射、页表不存在或已经删除时安静返回；
4. 删除后使对应 TLB 项失效。

**明确不做的事**

- 不在这里回收空的中间页表页。`check_pgdir()` 在删除两个叶映射后仍断言 `boot_pgdir_va[0]` 指向的页表页引用为 1，说明页表页生命周期由更高层管理；顺手释放空页表会破坏既有语义。
- 不把“删除一个叶映射”扩大成 `mm_destroy()` 或进程地址空间销毁。

## 3. 必须保持的不变量

| 编号 | 不变量 |
|---|---|
| I1 | 同一地址、同一物理页重复 `page_insert()` 时，引用计数不先减后加，不能瞬间归零 |
| I2 | 同一地址改映射到另一物理页时，旧页只减一次，新页只加一次 |
| I3 | 叶页表项有效时，`pte2page(*ptep)` 必须指向引用计数大于 0 的 `Page` |
| I4 | `page_remove()` 对未映射地址幂等，不重复减引用 |
| I5 | 页表项权限以本次 `perm` 为准，旧权限不能残留 |
| I6 | 修改映射后必须失效对应 TLB，避免 CPU 命中旧翻译 |

## 4. 实际使用的 Prompt

```text
你在 ucore/riscv64 Lab4 的 kern/mm/pmm.c 中工作。
本实验采用预映射，不实现缺页异常和页面置换。

只实现以下两个函数，不重写整个文件：

int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm);
void page_remove(pde_t *pgdir, uintptr_t la);

约束：
1. 使用已有的 get_pte、pte_create、pte2page、page_ref_inc、
   page_ref_dec、assert、free_page、tlb_invalidate，不修改这些接口。
2. page_insert 先调用 get_pte(pgdir, la, 1)。返回 NULL 时返回
   -E_NO_MEM，不能留下已经指向新页的叶表项。
3. perm 不含 PTE_V；pte_create 会自动加入 PTE_V，不要重复发明权限语义。
4. 如果原地址已经有效映射到同一个 Page，只更新权限和页表项，
   绝对不能先 page_ref_dec 再 page_ref_inc，否则可能在重映射时释放
   仍在使用中的页。
5. 如果原地址映射到另一个 Page，先撤销旧映射，再增加新页引用并写入
   新页表项。
6. page_remove 必须幂等：get_pte(...,0) 返回 NULL 或叶项无效时直接返回。
7. page_remove 清空叶项并减少引用，归零时 free_page；不要回收空的中间
   页表页，check_pgdir 对页表页引用有既有断言。
8. 两个函数完成页表项修改后都调用 tlb_invalidate(pgdir, la)。
9. 保持 //LAB4 function1 注释，并把 YOUR CODE 替换为 2410665。
10. 输出 unified diff，逐条解释同页、异页、未映射、失败四条路径。

验收目标：官方 [Test PMM] PASS；另外检查同页重复映射、改映射、权限更新、
重复删除和空闲页数不泄漏。
```

## 5. 静态审查清单

1. `page_insert()` 是否在 `get_pte(..., 1)` 失败时立即返回 `-E_NO_MEM`。
2. 是否存在“先无条件 `page_ref_dec()`、再 `page_ref_inc()`”的写法；有则退回。
3. 同页快速路径是否更新 `*ptep` 的权限，而不是提前返回旧权限。
4. 异页路径是否调用 `page_remove()`，且之后只对新页增加一次引用。
5. `page_remove()` 是否先判断 `ptep == NULL` 和 `PTE_V`，再调用 `pte2page()`。
6. 是否错误地把空的中间页表页 `free_page()`；本实验不应回收。
7. 两个函数是否都调用了 `tlb_invalidate()`。
8. 学号是否已写入 `//LAB4 function1 2410665`，且没有残留 `YOUR CODE`。

## 6. 交给宋秋实运行验证的边界

按分工，本模块代码由殷佳仪编写，静态审查由兰雨杉完成，运行验证统一由宋秋实执行并留证。需要优先验证：

- 同一物理页在同一地址重复插入，`nr_free_pages()` 不变化；
- 同一地址从 `p2` 改为 `p1`，`p2->ref` 归零且 `p1->ref` 增加；
- 权限从 `PTE_U | PTE_W` 改为 `0` 后，叶页表项不再保留旧权限；
- 同一地址连续 `page_remove()` 两次不崩溃；
- 两个虚拟地址映射同一物理页时引用为 2，分别删除后归零；
- 修改映射后访问新地址，能够读到新页内容而不是旧 TLB 结果。

上述结果必须保存为 `report/logs/run/` 下的原始日志；本文档不预填任何“已通过”的结论。

## 7. 实现记录（2026-11-10）

实际修改文件：`kern/mm/pmm.c`。

### 7.1 `page_insert()` 的落地路径

1. `get_pte(pgdir, la, 1)` 返回 `NULL` 时直接返回 `-E_NO_MEM`，不写叶页表项。
2. 原叶项有效且 `pte2page(*ptep) == page` 时，走同页快速路径：用新的 `perm` 重建页表项并失效 TLB，不改变引用计数。
3. 原叶项有效但指向其他 `Page` 时，调用 `page_remove()` 撤销旧映射，再对新页 `page_ref_inc()`，写入新页表项并失效 TLB。
4. 原叶项无效时按新映射处理，增加一次引用后写入页表项。

这样避免了“先减后加”在单引用页上触发假释放，也不会在改映射时忘记释放旧页。

### 7.2 `page_remove()` 的落地路径

1. `get_pte(pgdir, la, 0)` 返回 `NULL` 或叶项无 `PTE_V` 时直接返回，保证未映射地址和重复删除都是幂等操作。
2. 有效映射先取出 `Page`，断言引用计数大于 0，再清空叶项、减引用；归零时调用 `free_page()`。
3. 不释放空的中间页表页。`check_pgdir()` 在删除叶映射后仍检查 `boot_pgdir_va[0]` 指向的页表页引用为 1，释放 PT 会破坏骨架既有生命周期约定。
4. 删除后调用 `tlb_invalidate(pgdir, la)`，防止 CPU 继续使用旧翻译。

### 7.3 已完成的静态核对

- 模块一源文件中的标记为 `//LAB4 function1 2410665`，模块一区域没有残留 `YOUR CODE`。
- `perm` 直接交给 `pte_create(page2ppn(page), perm)`；`PTE_V` 由 `pte_create()` 统一加入，没有重复拼权限。
- `page_remove()` 先判断 `ptep` 与 `PTE_V`，不会对无效页表项调用 `pte2page()`。
- 同页重复插入路径不调用 `page_ref_dec()`，符合官方 `test_lab4.c` 对 `page_ref(p3) == 1` 和空闲页数不变的要求。
- 交叉编译器 `-fsyntax-only` 检查返回 0，原始记录见 `report/logs/static/module1_syntax_check.log`；唯一警告是尚未回填的 Lab2 `page_init()` 声明，不属于模块一。

### 7.4 尚未完成的部分

本记录只证明代码和静态契约，不等同于运行结果。按小组分工，构建、QEMU、GDB 与 `make grade` 由宋秋实统一执行；兰雨杉负责只读静态评审。需要回传的原始证据仍是 §6 列出的 T1–T6，尤其是同页重映射、异页改映射、权限更新、重复删除和 TLB 生效情况。
