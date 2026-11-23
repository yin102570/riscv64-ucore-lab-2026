# Lab4 Challenge 1：`local_intr_save/restore` 的开关中断语义

## 1. 目标与范围

只解释 `kern/sync/sync.h` 与 `kern/driver/intr.c` 的实现，不修改评分路径。需要回答四件事：宏展开后做了什么、`sstatus.SIE` 如何被读写、嵌套调用为什么不会提前开中断、它与自旋锁的边界在哪里。

## 2. Spec

1. `local_intr_save(x)` 必须保存调用点的中断状态，而不是无条件关中断；
2. `local_intr_restore(x)` 只能在保存值为真时恢复开中断；
3. 嵌套时内层退出不能打开外层关闭的中断；
4. 只操作当前 hart 的 `sstatus.SIE`，不能把 `sie/sip` 或自旋锁混为一谈；
5. 结论必须对应到 `schedule()`/`proc_run()` 的实际调用链。

## 3. Prompt

我们给 AI 的约束是：

- 只读 `kern/sync/sync.h`、`kern/driver/intr.h`、`kern/driver/intr.c`、`kern/schedule/sched.c`、`kern/process/proc.c`；
- 先展开宏，再逐条解释 `read_csr(sstatus)`、`clear_csr`、`set_csr` 的作用；
- 必须给出 `schedule()` 调用 `proc_run()` 时的嵌套状态变化，不能只讲单层；
- 必须区分 `SIE` 与 `sie/sip`，并说明单核与多核的边界；
- 不修改任何代码，不把 Challenge 答案写进 `pmm.c`/`proc.c`。

## 4. 理解偏差与修正

只按宏的字面意思看，容易把它理解成进来关中断、出去开中断，漏掉保存调用点状态这一层。我们对照 `__intr_save()` 的返回值才发现：外层已经关中断时，内层保存的是 `false`，退出时不能调用 `intr_enable()`。随后又对照 `schedule()` 与 `proc_run()` 的嵌套调用，把状态变化写成可核对的三步，避免把结论停留在宏的字面意思上。

## 5. 核查结论

`__intr_save()` 读 `sstatus.SIE`：为 1 时执行 `clear_csr(sstatus, SSTATUS_SIE)` 并返回 `true`；为 0 时直接返回 `false`。`__intr_restore(flag)` 只在 `flag` 为真时执行 `set_csr(sstatus, SSTATUS_SIE)`。因此它保存的是调用点的中断使能状态，支持嵌套归还。

`schedule()` 先保存并关中断，随后调用 `proc_run()`；`proc_run()` 再次保存时读到 `SIE=0`，得到 `false`，退出时保持关中断；回到 `schedule()` 后由外层 `true` 恢复开中断。这个调用链直接证明了嵌套语义。

它只改 `SIE`，不改 `sie`（中断源使能）和 `sip`（挂起位）；也不提供多核间的原子互斥。单核上它防止异步陷阱打断临界区，多核上仍然需要自旋锁或原子指令。

## 6. 验收

- 能画出 `schedule -> proc_run` 的两层保存/恢复状态；
- 能解释为什么内层 `restore(false)` 不能开中断；
- 能指出 `SIE` 与 `sie/sip` 的区别；
- 能说明它不是自旋锁；
- 报告与代码一致，未修改评分路径。
