# Lab3 Prompt 与 Spec 记录

本文件是 `report.md` 第六节的展开版，记录我们在本次实验中**实际使用**的 spec、prompt、审查清单和迭代过程。不是事后补写的模板，三段 prompt 都能直接复用到同类 trap 实验里。

## 0. 使用约定

- 每个模块先写 spec，再写 prompt。spec 描述"输入—输出—约束—验收"，prompt 是喂给 AI 的完整任务书。
- prompt 里同时写"要做什么"和"不能做什么"。AI 最容易犯的错不是不会写，而是顺手改了不该改的代码。
- 要求 AI 输出 `diff` 而不是整文件，减少无关改动，也便于我们逐行审。
- 最终验收只认两样东西：官方 `make grade` 分数、我们自己从串口日志里读出的证据。

三个模块的负责人与文件：

| 模块 | 文件 | 负责人 | 学号 |
|---|---|---|---|
| A：trap 入口与现场恢复 | `kern/trap/trapentry.S` | 殷佳仪 | 2410665 |
| B：中断/异常分发 | `kern/trap/trap.c` | 宋秋实 | 2410749 |
| Challenge 1：S → U → S | `kern/init/lab3_switch.c` | 兰雨杉 | 2412090 |

## 1. 模块 A 的 spec

**输入**：`SAVE_ALL` 已经在当前内核栈顶压好一个 `struct trapframe`，36 个 `uintptr_t` 槽位依次是 32 个通用寄存器、`sstatus`、`sepc`、`badvaddr`、`scause`。

**输出**：

- `RESTORE_ALL` 从 trapframe 恢复 CSR 与通用寄存器；
- `__alltraps` 把 `sp` 作为 `trapframe *` 传给 `trap()`，返回后跳到 `__trapret`；
- `__trapret` 执行 `RESTORE_ALL`，最后 `sret`。

**约束**：

1. 不修改 `SAVE_ALL`、`struct trapframe`、`trap()` 的函数签名。
2. `x0` 不恢复。
3. `sstatus`、`sepc` 必须在通用寄存器之前写回，临时寄存器只能用 `t0`。
4. `sp` 必须最后恢复，偏移是 `2*REGBYTES(sp)`。
5. 返回指令只能是 `sret`，不能改成 `ret` 或 `jr ra`。

**验收**：

- `make grade` 的 Test 1 为 `PASS (35/35)`；
- `objdump` 中 `RESTORE_ALL` 的最后两条指令是 `ld sp,16(sp)` 和 `sret`；
- 断点异常返回后，被测试的 32 个寄存器与进入前一致。

## 2. 模块 A 的 prompt（原文）

```text
你在 ucore/riscv64 的 kern/trap/trapentry.S 中工作。
已有 SAVE_ALL 把 32 个通用寄存器和 sstatus/sepc/badvaddr/scause
按 struct trapframe 的 36 个 uintptr_t 槽位保存在当前栈顶。

请只实现 RESTORE_ALL 和 __alltraps，要求：
1. 先恢复 sstatus、sepc，用 t0 做临时寄存器；
2. 恢复 x1、x3..x31，不恢复 x0；
3. sp 必须最后从 2*REGBYTES(sp) 恢复；
4. __alltraps 中 SAVE_ALL 后把 sp 放进 a0，jal trap，返回后 j __trapret；
5. 不修改 SAVE_ALL、struct trapframe、trap() 签名；
6. 输出 unified diff，不要重写整个文件。

验收：make grade 的 Test 1 必须 PASS (35/35)，且 objdump 中
最后一条恢复指令必须是 ld sp,16(sp)，下一条是 sret。
```

## 3. 模块 A 的审查与偏差

我们拿到 diff 后按固定顺序看：

1. diff 里是否出现 `SAVE_ALL` 的上下文行改动——出现就整段退回。
2. 每个 `ld` 的偏移是否与 `struct trapframe` 字段顺序一一对应，尤其 `sstatus` 是第 32 个槽（偏移 256）、`sepc` 是第 33 个（偏移 264）。
3. `sp` 是否真的在最后；有的版本会把 `sp` 放在 `x1` 后面"顺手"恢复，导致后续 `ld` 全部读错栈。
4. 末尾是否仍是 `sret`。

实际遇到的两个偏差：

- 生成的版本先恢复通用寄存器、最后才写 `sstatus`。这样 `sstatus.SPP`、`SIE` 的写回发生在恢复过程中，一旦中途触发中断，现场就不完整。我们改成"CSR 先写、通用寄存器后写"。
- 生成的版本用 `t0` 同时承担 `sstatus` 和 `sepc` 的临时寄存器，中间没有重新取址。我们保留 `t0`，但严格按"读一个 CSR、写一个 CSR、再读下一个"的顺序，避免值被覆盖。

另外，新版 binutils 不再认识 `sbadaddr` 这个旧别名，编译直接报 `unknown CSR`。我们没有改 `SAVE_ALL` 的原文，而是在文件头加了一行 `.equ sbadaddr, 0x143`，把别名补回来。这样既通过编译，也不破坏助教对照原骨架检查的便利。

## 4. 模块 B 的 spec

**输入**：`struct trapframe *tf`，其中 `tf->cause` 是 `scause`，`tf->epc` 是 `sepc`，`tf->gpr[]` 是通用寄存器现场。

**输出**：

- 中断：软件中断打印一行；定时器中断续订、计数、周期打印、到点关机；外部中断打印一行；未知中断打印原因号。
- 异常：断点、非法指令打印规定格式并推进 `epc`；用户/内核 `ecall` 推进 `epc`；其余打印整个 trapframe。

**约束**：

1. 不改 `interrupt_handler` / `exception_handler` 的签名，不改 `trap_dispatch`。
2. `scause` 最高位是"中断/异常"标志，进 switch 前必须先掩掉。
3. `epc` 推进不能写死 `+4`：RISC-V 压缩指令是 2 字节。
4. 官方脚本按字符串匹配，格式串必须逐字一致。

**验收**：

- Test 2 `PASS (25/25)`，日志含 `Illegal instruction at 0x...` 且返回后继续执行；
- Test 3 `PASS (40/40)`，日志含 `ticks=200`；
- 日志中出现 `Supervisor software interrupt` 与 `Unknown interrupt: cause 15`。

## 5. 模块 B 的 prompt（原文）

```text
你在 ucore/riscv64 的 kern/trap/trap.c 中实现两个函数：
void interrupt_handler(struct trapframe *tf);
void exception_handler(struct trapframe *tf);

背景：trap_dispatch 已经用 (intptr_t)tf->cause < 0 区分中断/异常。
要求：
1. 中断分支先 mask 掉 scause 最高位，再按 IRQ_S_TIMER/IRQ_S_SOFT/
   IRQ_S_EXT/default 处理；
2. 定时器分支第一行调用 clock_set_next_event()，然后 ticks++，
   ticks % TICK_NUM == 0 时 print_ticks()，ticks >= SHUTDOWN_AFTER
   时 sbi_shutdown()；
3. 异常分支处理 CAUSE_BREAKPOINT、CAUSE_ILLEGAL_INSTRUCTION、
   CAUSE_USER_ECALL、CAUSE_SUPERVISOR_ECALL，其余 print_trapframe(tf)；
4. 断点和非法指令的 epc 推进必须按指令长度：低两位为 11 是 4 字节，
   否则是 2 字节；不要固定 +4；
5. 输出格式严格用：
   "Breakpoint at 0x%016lx\n"
   "Illegal instruction at 0x%016lx\n"
   "Supervisor software interrupt\n"
   "Unknown interrupt: cause %d\n"
6. 只输出 diff，不要改 trap_dispatch 和函数签名。

验收：make grade 的 Test 2/Test 3 必须 PASS，日志里要有
"cause    0x00000014" 和 "ticks=200"。
```

## 6. 模块 B 的审查与偏差

- 第一版把 `clock_set_next_event()` 放在 `ticks++` 之后。功能上"看起来"也能跑，但第一次中断响应时还没续订，QEMU 里只打印了一次 `100 ticks` 就停住。改成"续订放在分支第一行"后，`ticks` 稳定到 200。
- 第一版对 `ebreak` 直接 `epc += 4`。`ebreak` 本身是 2 字节压缩指令，返回地址落到指令中间，立刻触发非法指令。改成按指令低两位判断长度后，Test 1 恢复通过。
- 字符串格式上，AI 一开始写成 `"Unknown interrupt: cause %d\n"` 但把 `cause` 传成了未掩码的 `tf->cause`，负数被打印成 `-2147483633`。我们改成先掩码再传入，日志才与脚本期望的 `15` 对上。

## 7. Challenge 1 的 spec

**目标**：不依赖进程系统，演示一次完整的 S → U → S 特权级往返。

**输入**：内核已建立启动页表，`pmm` 可以分配物理页。

**输出**：

- 构造独立 Sv39 根页表，复制内核高半区映射，额外映射用户代码页（`0x1000`）和用户栈页（`0x2000`/`0x3000`），并置 `PTE_U`；
- 清 `sstatus.SPP` 后 `sret` 进入 U 模式；
- U 模式执行 `ecall`，`scause=8`，`a0=0x55`；
- trap 处理把 `SPP` 置 1、`sp` 换回内核栈、`sepc` 指向恢复桩；
- 恢复桩切回内核页表，打印证据后关机。

**约束**：

1. 全部代码置于 `#ifdef LAB3_CHALLENGE_SWITCH` 内，默认 `make grade` 不受影响。
2. 不改 `trap_dispatch` 的既有分支语义，只在 U-mode `ecall` 且挑战激活时接管。
3. 切 `satp` 后必须 `sfence.vma`。
4. 用户页必须是 `PTE_U | PTE_R | PTE_W | PTE_X | PTE_V`，否则 U 模式取指就 fault。

## 8. Challenge 的 prompt（两轮）

第一轮，设计：

```text
设计一个不依赖进程系统的 S->U->S 演示，放在 kern/init/lab3_switch.c：
- 独立 Sv39 根页表，复制内核高半区映射；
- 用户代码页和用户栈页加 PTE_U；
- sret 前设置 SPP=0、SUM=1；
- U 模式执行 ecall，trap 处理里把 SPP 置 1、sp 换内核栈、epc 指向恢复桩；
- 恢复桩先切内核栈，再清 SUM，再恢复 satp；
- 用 LAB3_CHALLENGE_SWITCH 宏隔离，默认 make grade 不变。
```

第二轮，修 bug 时追加的约束：

```text
现象：Challenge 构建下 scause=0xd（load page fault），且无限递归 Trap。
已知 sstatus.SUM 在 lab3_switch_back() 里被提前清零。
请分析 RESTORE_ALL 的执行顺序，说明为什么会 fault，并给出最小修复：
SUM 必须保持到 trapframe 从用户栈读完之后；恢复桩要先切到内核栈，
再清 SUM，最后才恢复 satp。
```

这两轮的区别很关键：第一轮只描述"正常路径"，第二轮把**已经观测到的故障现象**写进 prompt，并要求 AI 先解释再改。后者得到的答案质量明显更高，也更不容易"改一处坏一处"。

## 9. 实际 bug 与修复记录

| 编号 | 现象 | 根因 | 修复 | 回归证据 |
|---|---|---|---|---|
| B1 | `make grade` 0/100，OpenSBI 打印 `Next Address : 0` | QEMU 7.0 的 `fw_dynamic` 不认 `-device loader` | `tools/grade.sh` 改用 `-kernel bin/ucore.img` | `logs/run/grade-final.log` 100/100 |
| B2 | `unknown CSR sbadaddr` | 新版 binutils 删除旧 CSR 别名 | 文件头 `.equ sbadaddr, 0x143` | `logs/build/build.log` 无报错 |
| B3 | Challenge `scause=0xd` 无限递归 | `lab3_switch_back()` 提前清 `SUM`，`RESTORE_ALL` 写回 `sstatus` 后再读用户栈上的 trapframe，触发 load page fault | 保持 `SUM` 到现场恢复完成；恢复桩先切内核栈再清 `SUM` | `logs/run/CHALLENGE.serial.log` PASS |
| B4 | 只打印一次 `100 ticks` | 定时器分支未在入口续订 | `clock_set_next_event()` 放到分支第一行 | `logs/run/TIMER.final.log` `ticks=200` |
| B5 | 断点返回后跑飞 | `ebreak` 被固定当作 4 字节 | 按指令低两位判断 2/4 字节 | `logs/run/CONTEXT.final.log` PASS |
| B6 | 恢复后寄存器值错乱 | `sp` 提前恢复 / 漏掉 `x31` | `sp` 最后恢复，逐槽核对 | `logs/static/trapentry.disasm.txt` |

## 10. 通用审查清单

每次 AI 返回 diff，我们按这张表过一遍，任一项不通过就退回重写，不在原 diff 上打补丁：

- [ ] 改动范围是否只在允许的文件和函数内。
- [ ] 是否动了 `SAVE_ALL`、`struct trapframe`、`trap_dispatch`、函数签名。
- [ ] 每个栈偏移是否与 trapframe 布局一致（32 个 GPR + 4 个 CSR，共 36 槽）。
- [ ] CSR 与通用寄存器的恢复顺序是否正确。
- [ ] `sp` 是否最后恢复。
- [ ] 指令长度判断是否覆盖 2 字节压缩指令。
- [ ] 官方匹配字符串是否逐字一致，参数是否已掩码。
- [ ] 宏隔离是否完整，默认构建是否零影响。
- [ ] `make grade` 是否 100/100，Challenge 是否单独 PASS。
- [ ] 日志里的数值是否与报告、截图一致。

## 11. 复现命令

```bash
cd code
make grade                     # 官方三项，期望 100/100
make clean && make             # 默认构建
make LAB3_CHALLENGE=1 && make qemu   # Challenge 1，串口应打印 PASS
```

对应的原始日志在 `report/logs/`，截图在 `report/images/`，静态反汇编在 `report/logs/static/`。