# 模块三：复制用户进程

负责人：2410749 宋秋实

## 1. 问题边界

模块三只回答一个问题：`fork()` 怎样在父子进程之间复制出两套互不干扰的执行现场。它不负责程序装载（模块二），也不负责退出回收（模块四）。复制必须同时覆盖三层：

1. PCB 与内核栈：子进程要有自己的 `proc_struct` 和能从陷阱返回的内核栈。
2. 地址空间：普通 `fork` 复制 VMA 和页表，`CLONE_VM` 共享同一张页表。
3. 返回现场：父进程从 `fork()` 得到子 PID，子进程从同一条用户指令返回 0。

## 2. Spec

### 2.1 `do_fork()` 的顺序与回滚

固定顺序：`alloc_proc` → `setup_kstack` → `copy_mm` → `copy_thread` → 在关中断区间内 `get_pid/hash_proc/set_links` → `wakeup_proc` → 返回 PID。

- 任一步失败，释放已经申请的资源，不能留下半个 PCB。
- `get_pid()` 必须在 `hash_proc()` 和 `set_links()` 之前调用，否则它会把正在分配的自己当成已占用 PID。
- PID 分配、挂哈希链、挂父子链必须在同一个 `local_intr_save/restore` 区间内完成。
- 父进程返回 `proc->pid`，子进程的 `tf->gpr.a0` 必须为 0。

### 2.2 `copy_mm()`

- `current->mm == NULL` 的内核线程直接返回，`pgdir` 保持 `boot_pgdir_pa`。
- `CLONE_VM`：`mm_count_inc(oldmm)`，`proc->mm = oldmm`，**同时** `proc->pgdir = PADDR(oldmm->pgdir)`。漏掉 `pgdir` 会让共享线程第一次被调度时 `satp` 仍指向旧页表。
- 普通 fork：`mm_create` + `setup_pgdir`（复制内核高半区、清空用户区）+ `dup_mmap`。失败时 `exit_mmap/put_pgdir/mm_destroy`。
- 复制期间对父 `mm` 加锁，避免 VMA 链表在遍历中被修改。

### 2.3 `copy_thread()`

- `proc->tf` 放在 `proc->kstack + KSTACKSIZE` 向下一个 `trapframe` 的位置。
- 整体复制父 trapframe，然后 `gpr.a0 = 0`。
- `gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp`：内核线程没有用户栈，指向自己的 trapframe；用户 fork 保留父进程保存的用户 `sp`。
- `context.ra = forkret`，`context.sp = proc->tf`。第一次被调度时 `switch_to` 的 `ret` 进入 `forkret`，再由 `forkrets` 恢复 trapframe。

### 2.4 不变量

- 子进程的 `satp` 必须指向它自己的 `pgdir`（`CLONE_VM` 除外）。
- 父子 `mm_count` 与页表实际共享关系一致，`exit_mmap` 不能提前释放共享页。
- 子进程的内核栈帧不能被父进程的后续调用覆盖。
- 普通 fork 默认走 COW；定义 `LAB5_NO_COW` 时走 `copy_range` 全量复制，作为对照路径。

## 3. 最终提示词

```text
在 ucore lab5 中实现 do_fork/copy_mm/copy_thread，只修改
kern/process/proc.c 的对应区域和 kern/mm 下必要的辅助函数。

约束：
1. do_fork 按 alloc_proc -> setup_kstack -> copy_mm -> copy_thread ->
   get_pid/hash_proc/set_links -> wakeup_proc 的顺序执行，每步失败
   都要回滚已经申请的资源。
2. get_pid 必须在挂哈希链和父子链之前调用，三段操作放在同一个
   关中断区间内。
3. copy_mm 对内核线程直接返回；CLONE_VM 增加 mm_count 并同时复制
   proc->pgdir；普通 fork 新建 mm、复制内核高半区、逐 VMA 复制。
4. copy_thread 把父 trapframe 复制到子内核栈顶，a0 清零，用户 sp
   保持父进程保存的值；context.ra=forkret，context.sp=proc->tf。
5. 子进程第一次被调度时从 fork() 返回 0，父进程返回子 PID。
6. 失败路径释放 kstack、mm、页表和 VMA，不泄漏、不双重释放。
7. 默认 COW；保留 LAB5_NO_COW 作为全量复制对照，不改 do_exit/do_wait
   的语义。
```

## 4. 迭代与 bug

### 4.1 `get_pid()` 放在挂链之后

第一版先 `set_links()` 再取 PID。`get_pid()` 遍历 `proc_list` 时会把当前进程也扫进去，刚分配的 PID 与自己的占位冲突，连续 fork 出现重复 PID。改为在关中断区间内先取 PID，再 `hash_proc/set_links`。

### 4.2 `CLONE_VM` 漏了 `pgdir`

只写了 `proc->mm = oldmm` 和 `mm_count_inc`，没有同步 `proc->pgdir`。共享线程第一次被调度时，`proc_run` 用旧的 `pgdir` 写 `satp`，访问的还是父进程之前的页表。补上 `PADDR(oldmm->pgdir)`。

### 4.3 子进程没有把 `a0` 清零

`copy_thread` 完整复制父 trapframe 后忘记改 `gpr.a0`。子进程从 `fork()` 返回时拿到父进程的 PID，`if (pid == 0)` 分支永远不成立，`forktest` 里父子都走父分支。补 `proc->tf->gpr.a0 = 0`。

### 4.4 `copy_range` 丢了页权限

第一版只把源 PTE 的 `PTE_V` 复制过去，目标页变成不可读或可写。正确做法是保留源的 `PTE_R/W/X/U`，只重新建立物理页号；只读代码段不能因为复制就获得写权限。

### 4.5 COW 第二次 fork 丢了 `PTE_COW`

这个问题是 `user/cowtest.c` 暴露的：父进程第一次 fork 后，可写页已经变成 `W=0, COW=1`；第二次 fork 时 `perm = (*ptep & PTE_USER)` 把软件位 `PTE_COW` 过滤掉了，新子进程拿到“只读但不带 COW”的页，第一次写就被 `do_pgfault` 判成非法访问并杀死。修复是 `perm = (*ptep & (PTE_USER | PTE_COW)) | PTE_V`，让后续 fork 继续共享 COW 页。

### 4.6 失败路径漏释放

`copy_mm` 失败时只 `kfree(proc)`，没有 `put_kstack`；`dup_mmap` 失败时没有 `exit_mmap`。用 `forktree` 反复 fork 可以把内存耗到分配失败，错误路径必须和成功路径对称。

## 5. 静态自查清单

- `do_fork()` 的每个失败标签只释放已经成功申请的资源。
- `get_pid()` 在 `hash_proc/set_links` 之前，且三段在同一个关中断区间。
- `CLONE_VM` 同时更新 `mm` 和 `pgdir`。
- 子进程 `tf->gpr.a0 == 0`，`context.ra == forkret`。
- `copy_range` 保留源页的 `R/W/X/U` 权限。
- `cow_copy_range` 保留 `PTE_COW`，二次 fork 仍能触发写时复制。
