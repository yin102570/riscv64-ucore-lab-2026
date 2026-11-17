# Lab4 Challenge 1：`local_intr_save/restore` 如何实现开关中断

`local_intr_save(intr_flag)` 展开成 `intr_flag = __intr_save()`。`__intr_save()` 先读 `sstatus.SIE`，**只有原本开启中断时才**调 `intr_disable()` 关掉，并把"关之前是否开启"作为 `bool` 存进 `intr_flag` 返回。`local_intr_restore(intr_flag)` 展开成 `__intr_restore(intr_flag)`，它**只在 `intr_flag` 为真时**才 `intr_enable()` 重新开中断。

所以它保存的是**调用点的中断状态**，不是简单的"进来关、出去开"。关键在嵌套：外层已经关了中断时 `sstatus.SIE == 0`，内层 `__intr_save()` 返回 `false`，内层退出时 `__intr_restore(false)` 就不开中断——中断状态逐层归还，内层不会擅自把外层关掉的中断打开。`schedule()`/`proc_run()` 用它包住临界区，就是为了防止调度扫描到一半被时钟中断打断。

边界：`local_intr_save/restore` 只关本 CPU 的局部中断，**不是自旋锁**，解决不了多核间互斥。本实验只跑单核内核线程，"局部关中断"够用；把它当成多核同步手段是不对的。
