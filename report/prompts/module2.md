# Lab4 功能模块二：进程创建及初始化

## 1. 范围

本模块只修改 `kern/process/proc.c`，完成：

```c
static struct proc_struct *alloc_proc(void);
void proc_init(void);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
static void copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf);
static int copy_mm(uint32_t clone_flags, struct proc_struct *proc);
```

不修改 `struct proc_struct` / `struct context` / `struct trapframe` 的布局；不实现用户态 `mm`、swap、`do_wait`、`do_exit`；不改动模块三区域（`cpu_idle`、`proc_run`）与 `switch.S`、`sched.c`。本实验只有内核线程，`mm` 全部为 `NULL`。

## 2. Spec

### 2.1 `alloc_proc()`

**输入**：无。

**成功语义**：`kmalloc()` 得到 PCB 后，把它置为明确初始状态，不依赖未定义内存：

- `state = PROC_UNINIT`、`pid = -1`、`runs = 0`、`need_resched = 0`；
- `kstack = 0`（等待 `setup_kstack()` 分配）；
- `parent = NULL`、`mm = NULL`、`tf = NULL`；
- `pgdir = boot_pgdir_pa`（**物理地址**，供 `satp` 使用，不是内核虚拟地址）；
- `context` 清零（14 个字段）、`flags = 0`、`name` 清空；
- `list_link` 与 `hash_link` 用 `list_init()` 初始化。

**失败语义**：`kmalloc()` 返回 `NULL` 时返回 `NULL`。

### 2.2 `proc_init()`

**输入**：无。调用时机在 `pmm_init/vmm_init` 之后、`clock_init/intr_enable/cpu_idle` 之前。

**成功语义**：

1. `list_init(&proc_list)`；对 `hash_list[HASH_LIST_SIZE]` 的每一项 `list_init()`；
2. `idleproc = alloc_proc()`，立即 `current = idleproc`；
3. `idleproc->pid = 0`、`state = PROC_RUNNABLE`、`kstack = (uintptr_t)bootstack`、`need_resched = 1`、`set_proc_name(idleproc, "idle")`；
4. `nr_process++`；
5. `kernel_thread(init_main, "Hello world!!", 0)`，断言返回 pid == 1；
6. `initproc = find_proc(1)`，`set_proc_name(initproc, "init")`。

**失败语义**：`alloc_proc()` 返回 `NULL` 或 `kernel_thread()` 返回非 1 时 `panic`。

**关键点**：`idleproc` 不是 `fork` 出来的，它复用当前执行现场与 `bootstack`；它的 `context` 保持 `alloc_proc()` 清零后的状态（`ra == 0`），因为 `idleproc` 永远不通过 `switch_to` 被切入，官方测试断言 `idleproc->context.ra == 0`。

### 2.3 `kernel_thread()`

**输入**：`fn`（目标函数）、`arg`（参数）、`clone_flags`。

**成功语义**：

1. 栈上准备临时 `struct trapframe tf`，`memset` 清零；
2. `tf.gpr.s0 = (uintptr_t)fn`；
3. `tf.gpr.s1 = (uintptr_t)arg`；
4. `tf.epc = (uintptr_t)kernel_thread_entry`；
5. `tf.status = read_csr(sstatus)`，置位 `SSTATUS_SPP` 与 `SSTATUS_SPIE`，清除 `SSTATUS_SIE`；
6. `return do_fork(clone_flags, 0, &tf)`。

**失败语义**：透传 `do_fork()` 的负错误码。

**关键点**：临时 `tf` 在函数返回后失效；真正生效的是 `copy_thread()` 复制到新内核栈顶部的那一份。`s0/s1` 与 `kernel_thread_entry`（`move a0, s1; jalr s0`）严格对应，不能颠倒，否则目标函数拿到错误参数或跳到错误地址。

### 2.4 `do_fork()`

**输入**：`clone_flags`、`stack`（本实验恒为 0）、`tf`（`kernel_thread()` 构造的模板）。

**成功语义**，按七步执行且每步失败回滚：

1. `alloc_proc()`，失败返回 `-E_NO_FREE_PROC`；
2. `setup_kstack(proc)`，失败 `kfree(proc)` 并返回 `-E_NO_MEM`；
3. `copy_mm(clone_flags, proc)`，失败 `put_kstack(proc); kfree(proc)` 并返回错误码；
4. `copy_thread(proc, stack, tf)`；
5. 先 `proc->pid = get_pid()`，再 `hash_proc(proc)`、`list_add(&proc_list, &(proc->list_link))`、`nr_process++`；
6. `wakeup_proc(proc)`；
7. `return proc->pid`。

**失败语义**：见每步。已分配的内核栈和 PCB 必须回收，不能污染 `proc_list`、哈希表和 `nr_process`。

**关键点**：`get_pid()` 扫描 `proc_list` 找未用 PID，所以必须**先分配 PID、后挂链表**，否则 `get_pid()` 会把新进程自己当作冲突源。

### 2.5 `copy_thread()`

**输入**：`proc`、`esp`（本实验 `kernel_thread()` 传入 0）、`tf`。

**成功语义**：

1. `proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1`（新内核栈顶部向下预留 trapframe）；
2. `*(proc->tf) = *tf`（复制模板）；
3. `proc->tf->gpr.a0 = 0`（表示“从 fork 返回 0”）；
4. `proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp`（`__trapret` 之后新线程的栈指针必须有效）；
5. `proc->context.ra = (uintptr_t)forkret`；
6. `proc->context.sp = (uintptr_t)proc->tf`。

**失败语义**：无（不分配资源）。

**关键点**：`context.ra` 必须指向 `forkret`（不是 `kernel_thread_entry`），让第一次被 `switch_to` 切入时走 `forkret -> forkrets -> __trapret` 链路；`gpr.sp` 若保持 0，`__trapret` 恢复后栈指针为 0，内核直接跑飞。

### 2.6 `copy_mm()`

**输入**：`clone_flags`、`proc`。

**成功语义**：`return 0`（占位）。

**失败语义**：无。

**关键点**：内核线程共享内核地址空间，`current->mm` 本为 `NULL`。这里不能虚构用户地址空间，也不能把 `clone_flags` 当成已经完成用户态 `fork`。接口保留是为后续实验扩展。

## 3. 必须保持的不变量

| 编号 | 不变量 |
|---|---|
| I1 | `alloc_proc()` 必须把所有字段置为明确初始值，不能依赖 `kmalloc()` 的未定义内存 |
| I2 | `idleproc` 复用当前现场与 `bootstack`，不经过 `do_fork`；其 `context` 保持清零（`ra == 0`） |
| I3 | `proc->pgdir` 存物理地址 `boot_pgdir_pa`（供 `satp`），不存内核虚拟地址 |
| I4 | `do_fork()` 每步失败必须回收已取得资源（`setup_kstack` 失败 `kfree(proc)`，`copy_mm` 失败回滚 kstack） |
| I5 | `get_pid()` 必须在 `list_add`/`hash_proc` 之前调用，否则 PID 查找基准被污染 |
| I6 | 进程完成 `copy_thread` + PID 分配 + 挂链表后，才 `wakeup_proc` 置 `RUNNABLE` |
| I7 | `kernel_thread` 的 `s0=fn`、`s1=arg` 与 `kernel_thread_entry` 的 `move a0,s1; jalr s0` 严格对应 |
| I8 | `copy_thread` 的 `context.ra` 指向 `forkret`（不是 `kernel_thread_entry`），`context.sp` 指向 `proc->tf` |
| I9 | 子线程 `trapframe` 的 `gpr.a0` 置 0、`gpr.sp` 指向有效栈 |

## 4. 实际使用的 Prompt

```text
你在 ucore/riscv64 Lab4 的 kern/process/proc.c 中工作。
本实验创建的是内核线程，mm 全部为 NULL，不实现用户态地址空间和 swap。

只实现以下六个函数，不重写整个文件，也不改动模块三区域
（cpu_idle、proc_run）以及 switch.S、sched.c：

static struct proc_struct *alloc_proc(void);
void proc_init(void);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
static void copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf);
static int copy_mm(uint32_t clone_flags, struct proc_struct *proc);

约束：
1. 使用已有的 kmalloc、kfree、memset、memcpy、list_init、list_add、
   set_proc_name、find_proc、get_pid、wakeup_proc、setup_kstack、
   put_kstack、hash_proc、read_csr(sstatus)、boot_pgdir_pa、bootstack、
   KSTACKSIZE、forkret、kernel_thread_entry，不修改这些接口。
2. alloc_proc 必须把 PCB 完全清零初始化：state=PROC_UNINIT、pid=-1、
   runs=0、need_resched=0、kstack=0、parent/mm/tf=NULL、
   pgdir=boot_pgdir_pa（物理地址）、context 清零、flags=0、name 清空、
   list_link 与 hash_link 用 list_init 初始化。kmalloc 失败返回 NULL。
3. proc_init 先 list_init(&proc_list) 并对 hash_list 每项 list_init；
   idleproc=alloc_proc 后立即 current=idleproc；idleproc 设 pid=0、
   state=PROC_RUNNABLE、kstack=(uintptr_t)bootstack、need_resched=1、
   set_proc_name(idleproc,"idle")；nr_process++；再
   kernel_thread(init_main,"Hello world!!",0)，断言返回 1；最后
   initproc=find_proc(1)，set_proc_name(initproc,"init")。
   idleproc 不是 fork 出来的，context 保持清零。
4. kernel_thread 用局部 struct trapframe tf，memset 清零后设置：
   tf.gpr.s0=fn、tf.gpr.s1=arg、tf.epc=kernel_thread_entry、
   tf.status=read_csr(sstatus) 后置 SSTATUS_SPP、SSTATUS_SPIE，清
   SSTATUS_SIE；最后 do_fork(clone_flags, 0, &tf)。
5. do_fork 严格七步，每步失败回滚：alloc_proc（失败 -E_NO_FREE_PROC）→
   setup_kstack（失败 kfree(proc) 返回 -E_NO_MEM）→ copy_mm（失败
   put_kstack+kfree）→ copy_thread → get_pid 后 hash_proc、list_add、
   nr_process++ → wakeup_proc → 返回 pid。
   注意先分配 PID 再挂链表，wakeup_proc 放在最后。
6. copy_thread 把 trapframe 放到新内核栈顶：proc->tf =
   (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1；复制 *tf；
   proc->tf->gpr.a0=0；proc->tf->gpr.sp=(esp==0)?(uintptr_t)proc->tf:esp；
   proc->context.ra=forkret；proc->context.sp=(uintptr_t)proc->tf。
   context.ra 是 forkret 不是 kernel_thread_entry。
7. copy_mm 本实验只 return 0，不虚构用户地址空间。
8. 保持 //LAB4 function2 注释，并把 YOUR CODE 替换为 2410749。
9. 输出 unified diff，逐条解释 alloc_proc 的初始化字段、proc_init 的
   idleproc 特殊语义、kernel_thread 的 s0/s1/epc/status、do_fork 的失败
   回滚、copy_thread 的首次运行现场、copy_mm 的占位理由。

验收目标：官方 [Test Process Create] PASS（idleproc pid=0/RUNNABLE/
kstack==bootstack/tf=NULL/runs=0/context.ra==0；initproc pid=1/RUNNABLE/
parent==idleproc/context.ra!=0/context.sp!=0）；并配合模块三让
initproc 首次被调度后打印 Hello world，且 [Test Schedule] PASS。
```

## 5. 静态审查清单

1. `alloc_proc()` 是否覆盖了全部 14 个字段，尤其是 `pgdir` 用的是 `boot_pgdir_pa` 还是内核虚拟地址。
2. `proc_init()` 中 `current = idleproc` 是否紧跟在 `alloc_proc()` 之后；`idleproc->kstack` 是否等于 `(uintptr_t)bootstack`。
3. `idleproc` 的 `context` 是否保持清零（不能被赋 `forkret`）。
4. `kernel_thread()` 的 `s0/s1` 是否与 `kernel_thread_entry` 一致；`status` 是否置 `SPP/SPIE`、清 `SIE`。
5. `do_fork()` 是否先 `get_pid()` 再 `list_add`；`wakeup_proc` 是否在最后。
6. `do_fork()` 三步失败路径是否都正确回收（`kfree(proc)` / `put_kstack`）。
7. `copy_thread()` 的 `context.ra` 是否为 `forkret`（不是 `kernel_thread_entry`）；`context.sp` 是否指向 `proc->tf`；`gpr.a0` 是否为 0、`gpr.sp` 是否有效。
8. `copy_mm()` 是否只 `return 0`，没有引入用户态 mm。
9. 学号是否已写入 `//LAB4 function2 2410749`，且模块二区域无残留 `YOUR CODE`，也未触碰模块三区域。

## 6. 分工与验证边界

- **作者**：宋秋实（2410749），负责实现与运行验证。
- **静态评审**：殷佳仪（2410665）；**独立检查**：兰雨杉（2412090）。
- 本模块与模块三共用 `proc.c`，按分工 §3.3 只改 `//LAB4 function2` 区域，不得整文件覆盖、不得改 `cpu_idle`/`proc_run`。

宋秋实统一运行验证并留证，优先验证（对应 T5/T7/T8）：

- `idleproc`/`initproc` 的 PID、状态、栈、父指针、`mm`、`tf`、`context` 与官方断言一致；
- GDB 断在 `switch_to`、`forkret`、`kernel_thread_entry`，记录 `context.ra/sp`、`s0/s1`、`epc`，证明首次运行链成立；
- 在临时副本中令 `alloc_proc()` 或 `setup_kstack()` 返回失败，确认不挂半初始化 PCB、不丢空闲页；
- 首次切入 `initproc` 后打印 `this initproc, pid = 1, name = "init"` 与 `Hello world!!`。

结果保存为 `report/logs/run/` 下原始日志；本文档不预填任何“已通过”结论。

## 7. 实现记录（待实现后回填）

按 §5.3 的五行格式记录实际 bug（现象/根因/修复/回归/反思），重点落在 `status` 位、`switch_to` 首次恢复链、`gpr.sp` 是否有效、`do_fork` 失败回滚这几类问题上。
