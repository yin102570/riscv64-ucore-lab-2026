# 模块四：退出、让出、终止与等待

负责人：2412090 兰雨杉

## 1. 问题边界

模块四处理进程生命周期的收尾：一个进程怎样停止、怎样把 CPU 让给别人、怎样被父进程回收，以及父进程怎样等待子进程。它不创建进程，也不复制地址空间；所有动作都建立在模块三已经构造好的进程树上。

核心约束只有一句：**退出者不能释放自己正在使用的内核栈和 PCB，回收必须由父进程完成。** 这条约束把 `do_exit` 和 `do_wait` 分成两半，也决定了僵尸态存在的必要性。

## 2. Spec

### 2.1 `do_exit()`

1. `idleproc` 和 `initproc` 不允许退出，直接 panic。
2. 若当前进程有用户地址空间：先把 `satp` 切回 `boot_pgdir_pa`，再 `mm_count_dec`；计数归零才 `exit_mmap/put_pgdir/mm_destroy`。切换必须发生在释放页表之前。
3. 置 `PROC_ZOMBIE`，保存 `exit_code`。
4. 在关中断区间内把 `cptr` 链上的孤儿重挂到 `initproc`，维护 `optr/yptr` 双向关系。
5. 若父进程睡在 `WT_CHILD` 上，唤醒父进程。
6. 调 `schedule()`，永不返回；不能在这里 `put_kstack` 或 `kfree(current)`。

### 2.2 `do_wait(pid, code_store)`

- `pid == 0` 表示等待任意子进程；`pid > 0` 只匹配该 PID。
- 遍历 `current->cptr` 及其 `optr` 链：
  - 找到僵尸子进程：`unhash_proc`、`remove_links`、`put_kstack`、`kfree`，写回退出码，返回 0。
  - 找到仍存活的子进程：置 `PROC_SLEEPING`、`wait_state = WT_CHILD`，`schedule()` 后重试。
  - 被子进程退出或 `kill` 唤醒后，若当前进程带 `PF_EXITING`，返回 `-E_KILLED`。
- 没有任何匹配的子进程：返回 `-E_BAD_PROC`，不能返回 0，否则 `init_main` 的等待循环永远不结束。
- `code_store` 是用户指针，必须在 `sys_wait` 里先做写权限检查；`do_wait` 只负责写。

### 2.3 `do_yield()` 与 `do_kill()`

- `do_yield()` 只置 `need_resched = 1`，真正的切换由陷阱返回前的 `schedule()` 完成；在系统调用处理函数里直接 `switch_to` 会绕过 trapframe 恢复。
- `do_kill(pid)` 找到目标后置 `PF_EXITING`；若目标在 `PROC_SLEEPING`，唤醒它，让它在下一个安全点自行退出。找不到返回 `-E_INVAL`。
- `wakeup_proc()` 只唤醒 `PROC_SLEEPING` 的进程；对 `RUNNABLE` 重复唤醒会覆盖 `wait_state`，对 `ZOMBIE` 唤醒会让调度器选中一个已退出进程。

## 3. 最终提示词

```text
在 ucore lab5 中实现 do_exit/do_yield/do_kill/do_wait 和 wakeup_proc，
只修改 kern/process/proc.c 与 kern/schedule/sched.c 的对应区域。

约束：
1. do_exit 先切 satp 到 boot_pgdir_pa，再按 mm_count_dec 释放用户
   地址空间；置 ZOMBIE、保存 exit_code；孤儿重挂 initproc；
   父进程睡在 WT_CHILD 时唤醒；最后 schedule，函数不得返回。
2. do_exit 不能释放 current 的 kstack 和 proc_struct，这两项由
   do_wait 的父进程回收。
3. do_wait 支持 pid=0 和指定 pid；僵尸子进程要 unhash、remove_links、
   put_kstack、kfree；没有匹配子进程返回 -E_BAD_PROC；被 kill 唤醒
   返回 -E_KILLED。
4. do_yield 只置 need_resched；do_kill 置 PF_EXITING 并唤醒睡眠目标；
   wakeup_proc 只处理 PROC_SLEEPING。
5. sys_wait 在进入 do_wait 前检查 code_store 的写权限。
6. 不改 do_fork/copy_mm 的复制语义，不改 load_icode 的装载流程。
```

## 4. 迭代与 bug

### 4.1 `do_exit` 释放了自己的内核栈

第一版在 `do_exit` 末尾 `put_kstack(current)` 再 `schedule()`。调度器仍要在当前内核栈上保存 `context`，栈一释放，下一次切换就把返回地址写到已回收的物理页，表现为随机跑飞或双重释放。修复是把 PCB 和内核栈的回收移到 `do_wait`。

### 4.2 `wakeup_proc` 唤醒了僵尸

`wakeup_proc` 最初无条件 `state = PROC_RUNNABLE`。父进程在 `do_wait` 里被唤醒后，如果子进程刚好已经变成僵尸，调度器会把僵尸放回运行队列，下一次 `switch_to` 进入一个已经释放地址空间的进程。修复是先判断 `PROC_SLEEPING`，其它状态直接返回。

### 4.3 没有子进程时返回 0

`do_wait` 第一版在找不到子进程时也返回 0。`init_main` 的 `while (do_wait(0, NULL) == 0)` 因此永远不退出，内核卡在空转。改为返回 `-E_BAD_PROC`，让“成功回收一个”和“没有可等对象”区分开。

### 4.4 孤儿重挂时链表断裂

只改了 `proc->parent = initproc`，没有维护 `initproc->cptr` 的 `optr/yptr`。`forktree` 里父进程先退出、子进程继续运行时，`initproc` 的子进程链从中间断开，最后的 `initproc->cptr == NULL` 断言失败。修复是按 `cptr/optr/yptr` 三个指针同时插入。

### 4.5 `kill` 唤醒了等待者却没有出口

`do_kill` 只置 `PF_EXITING`，没有唤醒睡眠中的目标；目标永远睡在 `WT_CHILD` 上。补上 `wakeup_proc` 后，目标从 `do_wait` 返回 `-E_KILLED`，再由陷阱返回路径执行 `do_exit`。

### 4.6 用户程序把父分支又执行了一遍

`forktree` 的子进程在递归返回后没有 `exit`，继续执行父分支的 `assert(pid > 0)`，而它手里的 `pid` 是 0。问题不在内核，而在测试程序的控制流：`fork` 之后父子两条路必须显式分开。这个 bug 提醒我们，用户态测试失败不一定是内核错，先看分支是否闭合。

## 5. 静态自查清单

- `do_exit()` 在释放 mm 前切换 `satp`，且不释放自己的 kstack/PCB。
- 僵尸态、`exit_code`、父进程唤醒三者顺序正确。
- 孤儿重挂同时维护 `cptr/optr/yptr`。
- `do_wait()` 对“回收成功 / 没有子进程 / 被 kill”返回不同值。
- `wakeup_proc()` 只唤醒 `PROC_SLEEPING`。
- `sys_wait` 的 `code_store` 通过写权限检查。
