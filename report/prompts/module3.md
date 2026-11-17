# Lab4 功能模块三：进程调度与上下文切换

## 1. 范围

本模块修改三个位置：

```c
// kern/process/switch.S
void switch_to(struct context *from, struct context *to);
// kern/schedule/sched.c
void schedule(void);
// kern/process/proc.c 的 function3 区域
void cpu_idle(void);
void proc_run(struct proc_struct *proc);
```

不改 `struct context` / `struct proc_struct` 布局，不动模块一（`pmm.c`）和模块二（`proc.c` 的 function2 区域），不实现抢占式调度、时间片轮转或用户态进程。本实验只有内核线程，在显式调度点 `cpu_idle` 主动让出 CPU。

## 2. Spec

### 2.1 `switch_to()`

**输入**：`a0 = from`（当前线程的 `struct context *`），`a1 = to`（目标线程的 `struct context *`）。

**成功语义**：

1. 把 `from` 的 14 个 callee-saved 寄存器 `ra, sp, s0~s11` 按 `struct context` 字段顺序存到 `from`（偏移 0~13 × REGBYTES）；
2. 从 `to` 按同样顺序恢复这 14 个寄存器；
3. `ret` 跳转到 `to->context.ra`。

**关键点**：只保存/恢复 callee-saved 寄存器。`ra` 就是返回地址，首次切入时 `to->context.ra == forkret`，所以 `ret` 会走 `forkret → forkrets → __trapret` 恢复新线程现场。字段顺序必须和 `struct context` 完全一致，错一位整个上下文就乱。

### 2.2 `schedule()`

**输入**：无。

**成功语义**：

1. `local_intr_save` 关中断保护临界区；
2. 清 `current->need_resched`；
3. 环形扫描 `proc_list` 找第一个 `PROC_RUNNABLE`。起点：`current == idleproc` 时从表头开始，否则从 `current` 的下一个开始；
4. 一整圈没找到就回退到 `idleproc`；
5. `next->runs++`，若 `next != current` 则 `proc_run(next)`；
6. `local_intr_restore` 恢复中断状态。

**关键点**：调度决策全程关中断，避免扫描到一半被时钟打断。Round-Robin 的公平性靠"从自己下一个开始找"保证。

### 2.3 `cpu_idle()`

**输入**：无。

**成功语义**：死循环，只要 `current->need_resched` 就调用 `schedule()`。

**关键点**：这是唯一显式调度点，`kern_init` 最后进入这里，之后 CPU 在 idle 和可运行线程之间切换，函数永不返回。

### 2.4 `proc_run()`

**输入**：`proc`（目标线程）。

**成功语义**（`proc != current` 时）：

1. `local_intr_save`；
2. `current = next`；
3. `write_csr(satp, 0x8000000000000000 | (next->pgdir >> RISCV_PGSHIFT))` 切页表根；
4. `switch_to(&(prev->context), &(next->context))`；
5. `local_intr_restore`。

**关键点**：必须**先**设好 `current` 和 `satp`、**再** `switch_to`——`switch_to` 返回时已经站在新线程栈上，那时 `current`/`satp` 还指向旧线程就错了。`satp` 用 Sv39 编码（高 4 位模式为 8），和 `pmm.c` 的 `enable_paging()` 一致；`next->pgdir` 是物理地址。内核线程共享 boot 页表，所以这个值对每个线程都一样，但写法要按"页表根物理地址右移 PGSHIFT"来。

## 3. 必须保持的不变量

| 编号 | 不变量 |
|---|---|
| I1 | `switch_to` 只存/取 `ra,sp,s0~s11` 共 14 个 callee-saved 寄存器，字段偏移与 `struct context` 严格一致 |
| I2 | `switch_to` 的 `ret` 跳 `to->context.ra`，首次切入是 `forkret` 不是 `kernel_thread_entry` |
| I3 | `schedule` 的扫描与 `proc_run` 全程关中断，退出前恢复原中断状态 |
| I4 | `schedule` 先清 `need_resched`，找到 `RUNNABLE` 才切，一圈没有则回退 `idleproc` |
| I5 | `proc_run` 先设 `current` 与 `satp`，再 `switch_to` |
| I6 | `satp` 用 Sv39 编码 `0x8000000000000000`，`next->pgdir` 当物理地址右移 `RISCV_PGSHIFT` |
| I7 | 只有 `next != current` 才真正切换，避免把自己切给自己 |

## 4. 实际使用的 Prompt

```text
你在 ucore/riscv64 Lab4 中实现进程调度，只改三个位置，不重写文件，不碰
模块一（pmm.c）和模块二（proc.c 的 function2 区域）：

kern/process/switch.S 的 switch_to(from, to)：
1. 按 struct context 字段顺序，把 from 的 ra/sp/s0~s11 共 14 个
   callee-saved 寄存器存到 from（偏移 0~13*REGBYTES，用 STORE 宏）；
2. 从 to 按同样顺序 LOAD 恢复这 14 个寄存器；
3. ret 结束（跳到 to->context.ra）。

kern/schedule/sched.c 的 schedule()：
1. local_intr_save 关中断；
2. current->need_resched = 0；
3. Round-Robin 环形扫描 proc_list 找 PROC_RUNNABLE：current==idleproc
   时从表头开始，否则从 current 的下一个开始；
4. 一整圈没找到回退 idleproc；
5. next->runs++，next!=current 时 proc_run(next)；
6. local_intr_restore。

kern/process/proc.c 的 function3 区域（cpu_idle + proc_run）：
1. cpu_idle 死循环，current->need_resched 时调用 schedule()；
2. proc_run(proc)：proc!=current 时关中断，先 current=proc，再
   write_csr(satp, 0x8000000000000000 | (proc->pgdir >> RISCV_PGSHIFT))，
   再 switch_to(&(old->context), &(proc->context))，最后恢复中断。

约束：
- 保持 //LAB4 function3 注释，YOUR CODE 换成 2412090；
- switch_to 只处理 callee-saved，不要动 caller-saved；
- satp 用 Sv39 编码（高 4 位模式 8），不要用 libs/riscv.h 里那个
  SATP32 的 lsatp()，本骨架实际是三级页表；
- schedule 和 proc_run 的临界区用 local_intr_save/restore 包住。

验收：配合模块一/二，[Test Schedule] PASS，两个测试线程都被调度运行，
首次切入 initproc 走 forkret→forkrets→__trapret 链（GDB 可证明）。
```

## 5. 静态审查清单

1. `switch_to` 的存/取寄存器顺序是否与 `struct context`（`ra,sp,s0~s11`）一致。
2. `switch_to` 是否只用 callee-saved，没有误存 caller-saved。
3. `schedule` 是否先清 `need_resched`，扫描起点是否正确、能否完整绕一圈。
4. `schedule` 一整圈没找到是否回退 `idleproc`。
5. `proc_run` 是否先设 `current` 和 `satp` 再 `switch_to`。
6. `satp` 是否用 Sv39 编码、`next->pgdir` 当物理地址，而不是误用 `lsatp()`。
7. 临界区是否被 `local_intr_save/restore` 包裹且退出前恢复。
8. 学号是否写入 `//LAB4 function3 2412090`，且模块三区域无残留 `YOUR CODE`、未触碰模块一/二区域。

## 6. 分工与验证边界

- **作者**：兰雨杉（2412090），负责 `switch.S`、`sched.c`、`proc.c` 的 function3 区域，以及 Lab2/Lab3 依赖回填。
- **静态评审**：殷佳仪（2410665）；**运行验证**：宋秋实（2410749）。
- 与模块二共用 `proc.c`，按分工 §3.3 只改 function3 区域（`cpu_idle`/`proc_run`），不整文件覆盖、不碰模块二的 `alloc_proc`/`do_fork` 等。

宋秋实统一运行验证并留证，优先验证（对应 T6/T7）：

- `[Test Schedule] PASS`，两个测试线程都被调度；
- GDB 断在 `switch_to`，记录 `from/to` 的 `context.ra/sp`，证明首次运行链 `forkret→forkrets→__trapret`；
- 反汇编核对 `struct context` 14 个字段的偏移（见 `report/logs/static/kernel.disasm.txt`）。

## 7. 实现记录

实际修改文件：`kern/process/switch.S`、`kern/schedule/sched.c`、`kern/process/proc.c`（function3），以及 Lab2/Lab3 依赖回填的 `kern/mm/default_pmm.c`、`kern/mm/pmm.c`、`kern/trap/trapentry.S`、`kern/trap/trap.c`。

关键决策：

1. `switch_to` 只保存 callee-saved 14 个寄存器，`ret` 直接跳 `to->context.ra`。
2. `schedule` 用 `local_intr_save/restore` 保护整个调度决策，Round-Robin 从"自己下一个"开始找。
3. `proc_run` 里 `satp` 直接用 Sv39 编码，绕开 `libs/riscv.h` 里那个 SATP32 的 `lsatp()`（骨架实际是三级页表，见 Challenge 2）。
4. 依赖回填补了 Lab2 的 best-fit 物理页分配器（官方测试 `best_fit_check` 的断言只有 best-fit 能满足）和 Lab3 的陷阱恢复（`RESTORE_ALL`/`__alltraps`）。

`make grade 30/30` 的原始日志见 `report/logs/run/grade-20261115-0017.log`。
