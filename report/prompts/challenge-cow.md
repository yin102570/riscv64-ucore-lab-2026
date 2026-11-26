# Challenge：Copy on Write

负责人：2412090 兰雨杉

## 1. 问题边界

COW 要解决的是 `fork()` 的复制成本：父子进程先共享同一批物理页，只把页表改成只读并打上软件标记；任何一方真正写入时，才在页故障里复制一份私有页。它同时牵动四个对象：

1. 页表项权限：`PTE_W` 必须清掉，`PTE_COW` 必须置上。
2. 物理页引用计数：共享几个地址空间，计数就是几。
3. TLB：改完页表必须让旧翻译失效。
4. `do_pgfault()`：必须能区分“COW 写故障”和“非法访问”。

## 2. Spec

### 2.1 页表标记

`PTE_COW` 使用软件保留位 `0x200`，不占用 R/W/X/U。`cow_copy_range(to, from, start, end)` 对源页表逐页处理：

- 源 PTE 无效：跳过。
- 源页可写：把源 PTE 改成 `W=0, COW=1`，刷新源地址空间的 TLB；目标 PTE 用同一权限，`page_insert` 会增加引用计数。
- 源页已经只读且带 `PTE_COW`：说明这是第二次（或第 N 次）fork，目标必须继续带 `PTE_COW`，否则新子进程写的时候无法被识别。
- 源页只读且不带 `PTE_COW`（代码段、只读数据）：直接共享，不加 COW。

### 2.2 写故障处理

`do_pgfault()` 在 PTE 有效且带 `PTE_COW` 时：

- `page_ref(page) == 1`：当前进程是唯一持有者，直接把 PTE 恢复为 `W=1`，清掉 `PTE_COW`，刷新 TLB，不复制。
- `page_ref(page) > 1`：分配新页、`memcpy` 整页、`page_insert` 到当前地址空间，权限取源的 `R/X/U` 加 `W`，不加 `COW`。
- 其它有效 PTE 的写故障：真正的非法访问，返回 `-E_FAULT`，由上层杀死进程。

### 2.3 状态转换

| 状态 | 页表项 | 引用计数 | 事件 | 下一状态 |
|---|---|---|---|---|
| 独占可写 | `W=1, COW=0` | 1 | `fork` | 共享只读（父、子） |
| 共享只读 | `W=0, COW=1` | 2 | 任一进程写 | 写故障 |
| 写故障、多引用 | `W=0, COW=1` | 2 | 分配新页并拷贝 | 写者独占可写，另一侧仍共享只读 |
| 写故障、单引用 | `W=0, COW=1` | 1 | 直接恢复 `W=1` | 独占可写 |
| 共享只读 | `W=0, COW=1` | 2 | 再次 `fork` | 共享只读，计数 3（COW 位必须保留） |

### 2.4 Dirty COW 的启示

Dirty COW 的本质是“检查”和“使用”之间存在窗口：内核确认了页是 COW，却在把它改成可写之后、复制之前被另一个线程写入。ucore 单核关中断让这个窗口很小，但设计上仍应把“确认 COW、确认引用计数、复制、重映射”看成一个不可分割的决策。多核实现需要页表锁或引用计数原子操作，不能只靠“现在只有单核”。

## 3. 最终提示词

```text
在 ucore lab5 中实现 COW，修改 kern/mm/pmm.c、kern/mm/vmm.c、
kern/mm/mmu.h，保留 LAB5_NO_COW 全量复制路径作为对照。

要求：
1. 定义 PTE_COW 软件位，cow_copy_range 逐页共享可写页，源和
   目标都改成 W=0|COW，刷新源 TLB，page_insert 增加引用计数。
2. 源页已经是 COW 时，目标必须继续保留 PTE_COW，不能因为
   PTE_USER 掩码把它过滤掉。
3. do_pgfault 对 COW 页：引用计数为 1 时直接恢复写权限；
   大于 1 时分配新页、整页拷贝、重映射并刷新 TLB。
4. 只有带 PTE_COW 的有效 PTE 才能走复制路径，其它写故障返回
   -E_FAULT。
5. 不改变只读代码段的权限，不为只读页设置 COW。
6. 提供 user/cowtest.c：两个子进程在父进程仍持有共享页时分别写
   .data 和栈页，父进程必须读到原值。
```

## 4. 迭代与 bug

### 4.1 只改父页表，没有刷新 TLB

第一版把父进程的 PTE 改成只读后没有 `tlb_invalidate`。父进程写同一页时仍命中旧的“可写”翻译，直接写进共享页，子进程随后读到被改过的值。页表、引用计数、TLB 三者必须一起更新。

### 4.2 第二次 fork 丢了 COW 位

`perm = (*ptep & PTE_USER) | PTE_V` 会把软件位 `PTE_COW` 过滤掉。父进程第一次 fork 后页面已经是 `W=0, COW=1`，第二次 fork 的子进程拿到“只读但不带 COW”的页，写的时候 `do_pgfault` 判成非法访问并杀死。`cowtest` 里 `pid 4: bad memory access at 0x803000` 就是这个原因。修复为 `(*ptep & (PTE_USER | PTE_COW)) | PTE_V`。

### 4.3 单引用也复制

最初不判断 `page_ref`，只要写 COW 页就分配新页。语义没错，但多了一次无意义的复制；更严重的是，复制后旧页引用计数没有按预期下降，`exit_mmap` 时出现提前释放。补上 `page_ref == 1` 的快速路径。

### 4.4 只读段被错误标记

第一版对所有有效页都加 COW，包括代码段。代码段本来就没有写权限，加上 COW 后，一次非法写会被当成“可复制的 COW 写”，进程反而逃过了保护。修复是只在 `perm & PTE_W` 时降级并加 COW。

## 5. 测试

`user/cowtest.c` 覆盖三条路径：

1. 第一次 fork 后父子共享 `.data` 页和栈页。
2. 父进程在第一个子进程仍存活时再次 fork，引用计数达到 3。
3. 两个子进程分别写共享页，父进程最后仍读到 `shared=1, local=10`。

运行方式：

```sh
make clean
make TEST=cowtest
make qemu
```

通过标志是 `cowtest pass.`，同时不能出现 `bad memory access`。原始串口输出归档在 `report/logs/runtime/qemu-cowtest.log`。
