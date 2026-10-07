# Lab 1 提示词汇总

本文件汇总 Lab 1 使用过的全部提示词，与 [report.md](./report.md) 第四部分“最终提示词 / 实现迭代过程”一一对应。

## 环境

| 项目 | 内容 |
|---|---|
| AI 工具 | dsh（DeepSeek Harness）Web 界面 |
| 底层模型 | DeepSeek-V4-Flash |
| 工作区 | WSL2 Ubuntu 22.04.5 内的 `~/labcodes/lab1`（非 `/mnt/*` 挂载路径） |
| 运行环境 | riscv64-unknown-elf-gcc 10.2.0（SiFive GCC-Metal）+ qemu-system-riscv64 7.0.0 + OpenSBI v1.0 |
| 提示词规范 | 指导书 lab0.5 四段式（`[PROMPT] / [RELY] / [GUARANTEE] / [SPECIFICATION]`）；本组的"证据要求"与"禁止事项"写进 `[SPECIFICATION] → Requirements` 与 `[GUARANTEE]` |

## 记录格式

每完成一次有效迭代追加一条，全文件保持时间正序。

---

## 功能模块一：交叉编译与镜像生成（命令级取证与可复现性）

**负责人**：2412090-兰雨杉

### 功能模块一 · 最终提示词（全文）

```text
[PROMPT]
**任务**：产出 lab1 构建过程的"命令级取证"与可复现性结论：证明 riscv64 版内核镜像
是由哪些命令、以什么参数、按什么顺序生成的，并说明 ELF 与 BIN 的体积差从何而来。
**操作要求**：必须在项目内创建真实证据文件（logs/lab1/build-commands.txt）；
**不得修改** Makefile、tools/、kern/、libs/ 下任何文件；不得靠记忆复述编译参数，
所有参数必须来自实际回显。
**输出要求**：直接进行文件操作，使用下面 [RELY]、[GUARANTEE]、[SPECIFICATION] 的信息。

[RELY]
// Makefile 关键结构（原文）
V       := @                      # 所有 recipe 写成 $(V)命令 ⇒ 置空即可回显完整命令
CC      := riscv64-unknown-elf-gcc
LD      := riscv64-unknown-elf-ld
OBJCOPY := riscv64-unknown-elf-objcopy
CFLAGS  += -fno-builtin -Wall -O2 -nostdinc -fno-stack-protector -ffunction-sections -fdata-sections -g
LDFLAGS += -nostdlib --gc-sections
kernel  = bin/kernel ; UCOREIMG = bin/ucore.img

// 链接输入顺序（实测 make print-KOBJS）
obj/kern/init/entry.o obj/kern/init/init.o obj/kern/libs/stdio.o obj/kern/driver/console.o
obj/libs/printfmt.o obj/libs/readline.o obj/libs/sbi.o obj/libs/string.o      ← entry.o 排第一

// 已知产物实测值
bin/kernel    = 48752 B（ELF64, RISC-V, RVC, not stripped, Entry=0x80200000）
bin/ucore.img = 12296 B（BIN；四节之和仅 10048 B，差值 2248 B 为 . = ALIGN(0x1000) 填充）

[GUARANTEE]
必须产出的文件与数据：
```text
logs/lab1/build-commands.txt   # make V= 的完整命令行 + 前后 sha256 对照 + 参数逐条解释
logs/lab1/static-evidence.txt  # 节区表 / 符号表 / 体积账 / xxd 排布
```
必须给出的三个结论：
```text
1) 每个 CFLAGS/LDFLAGS 参数的作用与"去掉会怎样"
2) 入口落在 0x80200000 的直接原因 = 链接输入文件顺序（entry.o 第一）+ 链接脚本
3) 重编译前 vs 后：bin/kernel 与 bin/ucore.img 的 sha256 是否完全相同
```

[SPECIFICATION]
## logs/lab1/build-commands.txt
**Pre-Condition**：已在 labcodes/lab1 下成功执行过一次 make，bin/ 与 obj/ 存在。
**Post-Condition**：
- 记录构建前后两份产物的 sha256 与字节数；
- 记录 8 条 gcc 命令、1 条 ld 命令、1 条 objcopy 命令的**完整原文**；
- 给出每个参数的"作用 / 去掉会怎样"两列说明。

  **Case 1**（可复现）：前后 sha256 相同 ⇒ 明确写出"同一源码 + 同一工具链可逐字节复现"。
  **Case 2**（不可复现）：前后 sha256 不同 ⇒ 必须定位到具体原因（如调试信息含时间戳/路径），
  并在报告中如实说明，不得含糊带过。

**Requirements**：不得用 `make` 的默认（`+ cc`）输出充当"命令证据"——它不含参数。
```

### 功能模块一 · 第一次迭代

**提示词**：见本模块“最终提示词（全文）”——该次迭代**没有重写整段提示词**，只按下列改动点调整了对应段落。

**结果（遇到的问题）**：

- 问题 1：默认 `make` 的输出只有 `+ cc kern/init/entry.S` 这类概要，**看不到任何编译参数**，无法支撑"每个参数为什么必须有"的论证。
- 原因分析：Makefile 里 `V := @`，recipe 写成 `$(V)命令`，`@` 让命令不被回显。

**下一步调整**：

- 针对问题 1：把"如何取得命令行原文"写进 `[PROMPT] → 操作要求`，并在提示词中给出 **`make V=`（把 V 置空）** 这一可验证做法；同时要求把 8 条 gcc 命令全部落盘。

**产物**：见 report.md 该模块的“模块功能描述 / 实现迭代过程”与 `lab1/logs/` 下的同名日志。

### 功能模块一 · 第二次迭代

**提示词**：见本模块“最终提示词（全文）”——该次迭代**没有重写整段提示词**，只按下列改动点调整了对应段落。

**结果（遇到的问题）**：

- 问题 2：拿到完整命令后，仍然无法回答"这份构建是否可复现"——只有产物没有指纹，别人无法验证我们引用的体积/符号/反汇编结论。

**下一步调整**：

- 针对问题 2：在 `[SPECIFICATION]` 中新增 `Case 1/Case 2`：**构建前后各取一次 sha256**，并规定若不一致必须定位原因。实测结果落在 Case 1。

**最终结果**：

-  8+1+1 条完整命令落盘（`logs/lab1/build-commands.txt`）
-  参数解释表覆盖 8 个关键参数（含"去掉会怎样"）
-  **逐字节可复现**结论成立，且反向证明后续取证未污染工作副本

**产物**：见 report.md 该模块的“模块功能描述 / 实现迭代过程”与 `lab1/logs/` 下的同名日志。

**关键改进点（提示词层面的沉淀）**：

1. 把"怎么取得证据"写进提示词（`make V=`），避免 AI 只给结论不给命令；
2. 用 `Case 1/Case 2` 把"可复现/不可复现"两种结果都预先定义，避免只写顺耳的那种；
3. 把 sha256 前后对照作为**硬交付物**，使"源码零改动"从声明变成可验证事实。

---

## 功能模块二：启动链 GDB 观测脚本与会话证据

**负责人**：2410749-宋秋实

### 功能模块二 · 最终提示词（全文）

```text
[PROMPT]
**任务**：在 labcodes/lab1 工程内产出一套可复跑的 GDB 观测脚本与完整会话记录，
用于验证"加电复位 → OpenSBI → 内核入口 0x80200000"这条启动链。
**操作要求**：必须在项目中创建真实文件（脚本放 logs/gdb/ 下），而不是只给命令片段；
**不得修改** kern/、libs/、tools/、Makefile 下的任何文件（本 lab 不允许改源码）。
**输出要求**：直接进行文件操作，使用下面 [RELY]、[GUARANTEE]、[SPECIFICATION] 的信息；
所有结论必须来自命令的实际输出，不得凭记忆或教材描述填写。

[RELY]
// 地址事实（指导书 + 本机实测一致）
复位地址 = 0x1000；OpenSBI 固件基址 = 0x80000000；内核镜像加载地址 = 0x80200000
// 复位向量实测（6 条指令，0x1000~0x1014，数据区自 0x1018 起）
0x1000 auipc t0,0x0 ; 0x1004 addi a2,t0,40 ; 0x1008 csrr a0,mhartid
0x100c ld a1,32(t0) ; 0x1010 ld t0,24(t0) ; 0x1014 jr t0
0x1018 = 0x80000000（固件入口） 0x1020 = 0x87000000（设备树） 0x1038 = next_addr

// 调试入口（Makefile 原文）
make debug : $(QEMU) -machine virt -nographic -bios default \
             -device loader,file=bin/ucore.img,addr=0x80200000 -s -S
make gdb   : riscv64-unknown-elf-gdb -ex 'file bin/kernel' -ex 'set arch riscv:rv64' \
             -ex 'target remote localhost:1234'

// 符号来源必须是未 strip 的 ELF
bin/kernel     = ELF with debug_info, not stripped   ← 符号来自这里
bin/ucore.img  = objcopy --strip-all -O binary       ← 无符号，不可用作符号来源

// 关键符号实测值
kern_entry = 0x80200000 ; kern_init = 0x8020000a
bootstack  = 0x80201000 ; bootstacktop = 0x80203000 ; edata = end = 0x80203008

[GUARANTEE]
必须产出的文件：
```text
logs/gdb/lab1-session-B.gdb     # 可被 `make gdb < 该文件` 直接执行的命令脚本
logs/gdb/lab1-session-B.txt     # 该脚本的真实输出（命令 + 输出，原样保留，不美化）
```
必须在脚本中打出并留证的四条断言：
```text
1) 连接后 pc == 0x1000
2) x/8i 0x1000 反汇编出 6 条指令；x/gx 0x1018 读出的值是 0x80000000
3) 前 5 次 si 后 pc 依次为 0x1004 → 0x1008 → 0x100c → 0x1010 → 0x1014（停在第 6 条 jr t0）
4) b *0x80200000 + c 命中 kern_entry () at kern/init/entry.S:7
```

[SPECIFICATION]
## logs/gdb/lab1-session-B.gdb
**Pre-Condition**：① 已 make，bin/kernel 存在且带调试符号；② QEMU 已用 -s -S 启动并监听 1234。
**Post-Condition**：会话输出（含命令回显与全部输出）完整落盘；退出前 detach，且无残留 qemu 进程。

  **Case 1**（正常路径）：按 S0（连接与复位落点）→ S1（反汇编复位向量与读 0x1018）
  → S2（单步前 5 条）→ S3（进入固件 0x80000000）→ S4（断在内核入口并快照）顺序执行，逐条落盘。

  **Case 2**（连接失败）：明确报错退出，不得静默"成功"，不得用上一次运行的输出冒充本次结果。

**Requirements**：
- 命令文件中**不得出现空行**——gdb 从 stdin 逐行读命令时，空行等价于"重复上一条命令"；
- 必须 set pagination off / set confirm off；建议 set trace-commands on 以回显命令；
- 单步范围限定为复位代码的前 5 条（只为看清复位代码，不穿越 OpenSBI）。
```

> 注：以上是**老师原始 Makefile** 的写法；本机 QEMU 7.0 下 `-bios default` 为 `fw_dynamic`，
> 该写法会导致 `next_addr = 0`，故已适配为 `-kernel $(UCOREIMG)`（见功能模块四）。
> GDB 部分原版用 `riscv64-unknown-elf-gdb`，本组仓库改为 `gdb-multiarch`，两者对本实验等价。

### 功能模块二 · 第一次迭代

**提示词**：见本模块“最终提示词（全文）”——该次迭代**没有重写整段提示词**，只按下列改动点调整了对应段落。

**结果（遇到的问题）**：

- 问题 1：把命令写成 `.gdb` 文件后用 `make gdb < 文件` 批处理时，输出里出现**重复的观察点**（`Hardware watchpoint 1/2: *0x80200000`）与**多余的 `x`**（`(gdb) +x`）。
- 原因分析：gdb 从 stdin 读命令时，**空行被当成"重复上一条命令"**，而最初的命令文件为排版留了空行。

**下一步调整**：

- 针对问题 1：把这条经验写进提示词的 `[SPECIFICATION] → Requirements`："命令文件中不得出现空行"，并要求 `set pagination off` / `set trace-commands on`。重跑后输出干净。

**产物**：见 report.md 该模块的“模块功能描述 / 实现迭代过程”与 `lab1/logs/` 下的同名日志。

### 功能模块二 · 第二次迭代

**提示词**：见本模块“最终提示词（全文）”——该次迭代**没有重写整段提示词**，只按下列改动点调整了对应段落。

**结果（遇到的问题）**：

- 问题 2：脚本里最初把复位代码写成"5 条指令，0x1000~0x1010"——这是**凭记忆写的**，与 `x/8i` 实测的 6 条（0x1000~0x1014）不符。

**下一步调整**：

- 针对问题 2：在 `[RELY]` 中把复位向量**逐条列出**（而不是写"5 条"），并在 `[GUARANTEE]` 中断言"`x/8i 0x1000` 反汇编出 **6 条**指令"。随后修改脚本标签并**重跑会话**，使原始记录与结论一致；台账 EV-14 同步更正，EV-31 用 QEMU 自己的 `-d in_asm` 日志独立印证了"6 条"。

**最终结果**：

-  脚本可原样重跑（`make gdb < logs/gdb/lab1-session-B.gdb`）
-  四条断言全部通过（`pc=0x1000` → 复位 6 条指令 → 移交 `0x80200000`）
-  会话记录落盘，每次运行后残留 qemu 进程数均为 0

**产物**：见 report.md 该模块的“模块功能描述 / 实现迭代过程”与 `lab1/logs/` 下的同名日志。

**关键改进点（提示词层面的沉淀）**：

1. 把"gdb 命令文件空行语义"写成硬约束，而不是靠人记住；
2. 在 `[RELY]` 里用**逐条指令清单**替代**计数**——计数会被记忆污染，指令清单可以被 `x/8i` 直接比对；
3. 发现错误后**重跑证据**而不是只改结论，保证"原始记录 ↔ 台账 ↔ 报告"三者自洽。

---

## 功能模块三：启动链证据台账与验收判据

**负责人**：2412090-兰雨杉

### 功能模块三 · 最终提示词（全文）

```text
[PROMPT]
**任务**：在 lab1/ 下产出启动链证据台账，把"内核启动"拆成可复核条目，
并给出验收判据与"不可当判据"的量。
**操作要求**：必须创建真实文件（logs/lab1/boot-chain-evidence.md 等），不得只给结论；
不得修改任何源码。
**输出要求**：使用下面 [RELY]、[GUARANTEE]、[SPECIFICATION] 的信息；凡引用指导书的一律注明
"教程原文"，凡本机结论一律给出命令或日志路径。

[RELY]
// 教程原文（"期望"列只能来自这里）
lab1 报告要求 5 条：markdown 文本为主 / 整体逻辑线 / 每个功能的核心函数理解 /
                   知识点与 OS 原理对照 / 原理中重要但本实验没有的知识点
练习 1 原文：说明 la sp, bootstacktop 与 tail kern_init 完成了什么、目的是什么
练习 2 原文：用 GDB 跟踪从加电到内核第一条指令（0x80200000），并回答
            "加电后最初执行的几条指令位于什么地址、完成了哪些功能"
教程 tips 原文：① 复位地址 0x1000；② "可以使用 watch *0x80200000 观察内核加载瞬间"；
               ③ "使用 b *0x80200000 可在此中断，验证内核开始执行"

// 本机实测（"实际"列只能来自这里）
logs/run/02A-qemu-教程原命令.log   → Domain0 Next Address : 0x0，无 os is loading
logs/run/02B-qemu-本机适配命令.log → Domain0 Next Address : 0x80200000，有 os is loading
logs/gdb/lab1-session-D1.txt       → fw_dynamic_info.next_addr(0x1038) = 0x0
logs/gdb/lab1-session-D2.txt       → 同一字段 = 0x80200000
logs/lab1/qemu-inasm-excerpt.txt   → Priv 3 → Priv 1（mret 之后）→ Priv 3（ecall 之后）

[GUARANTEE]
```text
logs/lab1/boot-chain-evidence.md   # 台账：EV-1…EV-33，四列格式
logs/lab1/static-evidence.txt      # 节区表/反汇编/符号表/体积账/xxd
logs/lab1/shot-EV*.png             # 每条证据对应一张终端截图（附加证据）
```
必须给出的判据结论：
```text
可当判据：pc == 0x80200000 <kern_entry>；Domain0 Next Address == 0x80200000；
         屏幕出现 (THU.CST) os is loading ...；重编译 sha256 不变
不可当判据：sp/ra/tp 的具体数值、OpenSBI 横幅的版本与字段排布、x/10x $sp 的内容
```

[SPECIFICATION]
## logs/lab1/boot-chain-evidence.md
**Pre-Condition**：模块二、四、五的证据已落盘。
**Post-Condition**：每条证据都能由"证据形式"列的一条命令重放；"实际"列可在日志中找到原文；
无法观察到的现象被明确记为"未观察到"并给出机制解释与替代证据。

  **Case 1（能观察到）**：给出命令、输出、结论与对应截图文件名。
  **Case 2（未观察到）**：必须写清三件事——用了什么命令、为什么没观察到、用什么替代证据达到同等目的。
  例：`watch *0x80200000` 命中 0 次 → 因为镜像在 CPU 执行第一条指令前已写入物理内存
  → 替代证据：读 fw_dynamic_info.next_addr 判断"谁把入口地址告诉固件"。
  **Case 3（属于边界/环境相关）**：标注"随环境变化，不作为判据"，并给出本机实测值作参考。

**Requirements**：禁用"应该/通常/大概"；截图只作附加证据，正文证据必须是可被脚本复核的文本日志。
```

### 功能模块三 · 第一次迭代

**提示词**：见本模块“最终提示词（全文）”——该次迭代**没有重写整段提示词**，只按下列改动点调整了对应段落。

**结果（遇到的问题）**：

- 问题 1：教程 tips 说可用 `watch *0x80200000` 观察"内核加载瞬间"，但本机实测**命中 0 次**。

**下一步调整**：

- 针对问题 1：在 `[SPECIFICATION]` 中专设 **Case 2（未观察到）**，强制"未观察到"也必须写成结论并给出机制解释与替代证据；把"禁用应该/通常"写进 Requirements。

**产物**：见 report.md 该模块的“模块功能描述 / 实现迭代过程”与 `lab1/logs/` 下的同名日志。

### 功能模块三 · 第二次迭代

**提示词**：见本模块“最终提示词（全文）”——该次迭代**没有重写整段提示词**，只按下列改动点调整了对应段落。

**结果（遇到的问题）**：

- 问题 2：台账里出现"复位代码共 5 条指令"这一条，与模块二重跑后的 6 条不一致。

**下一步调整**：

- 针对问题 2：确立"**原始记录 ↔ 台账 ↔ 报告三者必须自洽**"的规则：凡计数类结论，必须能在原始日志里 `grep` 到对应证据；EV-14 更改为 6 条，并新增 EV-31（QEMU in_asm 独立印证）。

**最终结果**：

-  台账 **33 条证据**（EV-1…EV-33）全部给出可重放命令
-  判据表明确区分"可当判据 / 不可当判据"
-  两条"未观察到"如实保留并附机制解释；一处计数错误被查出并修正

**产物**：见 report.md 该模块的“模块功能描述 / 实现迭代过程”与 `lab1/logs/` 下的同名日志。

**关键改进点（提示词层面的沉淀）**：

1. 把"未观察到"列为必须处理的正常分支（Case 2），而不是当作失败；
2. 用格式约束（期望/实际分列）从源头杜绝"用教材结论冒充实测"；
3. 建立"原始记录↔台账↔报告"三方自洽检查，使报告自己就能发现内部矛盾。

---

## 功能模块四：QEMU 7.0 环境适配排障（根因定位到字段级）

**负责人**：2410665-殷佳仪

### 功能模块四 · 最终提示词（全文）

```text
[PROMPT]
**任务**：定位并修复"教程原命令 make qemu 在本机 QEMU 7.0.0 上不启动内核"的问题；
要求给出**字段级根因**与**零源码改动**的修复方案，并说明 0x80200000 这个地址与固件占用区的关系。
**操作要求**：不得修改 kern/、libs/、tools/、Makefile；排障必须用"只改一个变量"的对照实验，不得猜测。
**输出要求**：使用下面 [RELY]、[GUARANTEE]、[SPECIFICATION] 的信息；每个结论都要有日志或 GDB 读数。

[RELY]
// 现象（实测）
$ make qemu
OpenSBI v1.0
Domain0 Next Address      : 0x0000000000000000      ← 交给地址 0，内核一行未执行
（此后无输出，15 秒后被 timeout 强杀）

// 环境事实（实测）
/opt/qemu/share/qemu/ 下只有 opensbi-riscv64-generic-fw_dynamic.bin（105296 B），**没有 fw_jump**
⇒ -bios default 加载的是 fw_dynamic：它必须从 fw_dynamic_info.next_addr 取跳转地址

// Makefile 结构（原文）
ifndef QEMU
QEMU := qemu-system-riscv64
endif
⇒ 命令行或环境里已有的 QEMU 会覆盖它（命令行变量优先；环境变量使 ifndef 失效）

// 复位向量布局（实测，6 条指令 + 0x1018 起数据区）
0x1018 = 0x80000000（固件入口） 0x1020 = 0x87000000（设备树）
0x1028 = "OSBI"  0x1030 = 2  0x1038 = next_addr ← 唯一变量  0x1040 = 1（S-mode）

// 固件占用（OpenSBI 横幅实测）
Firmware Base = 0x80000000 ; Firmware Size = 252 KB
Domain0 Region01 = 0x0000000080000000-0x000000008003ffff（固件保留区）
内核入口 0x80200000 = 0x80000000 + 2 MiB（在保留区之上，不重叠）

[GUARANTEE]
```text
logs/run/02A-qemu-教程原命令.log        # 失败现场（Domain0 Next Address = 0x0）
logs/run/02B-qemu-本机适配命令.log      # 修复后成功现场
logs/run/03-qemu-adapted-make.log       # diff -r 证明源码零改动 + 官方 make qemu 目标跑通
logs/gdb/lab1-session-D1.txt            # 原命令下 next_addr = 0x0（GDB 直接读 0x1038）
logs/gdb/lab1-session-D2.txt            # -kernel 下 next_addr = 0x80200000（其余字段相同）
```

[SPECIFICATION]
## 修复方案：make 命令行变量覆盖
**Pre-Condition**：已确认本机 -bios default 是 fw_dynamic；未修改任何源码文件。
**Post-Condition**：
- `make qemu QEMU='qemu-system-riscv64 -kernel bin/ucore.img'` 输出中同时出现
  `Domain0 Next Address : 0x0000000080200000` 与 `(THU.CST) os is loading ...`；
- `diff -r --brief <收到的干净源码> <工作副本>` 无源码差异。

  **Case 1（教程原命令，-device loader）**：`-device loader` 只把文件写进物理内存，
  **不设置** fw_dynamic_info；于是 next_addr 保持 0，OpenSBI 打印 Domain0 Next Address = 0x0
  并跳到 0，内核永不执行。
  **Case 2（本机适配，-kernel）**：QEMU 把内核入口写进 next_addr（实测 0x80200000），
  OpenSBI 据此 mret 到 0x80200000，内核开始执行并打印。
  **Case 3（只用环境变量）**：由于 Makefile 用 `ifndef QEMU`，把 QEMU 放进环境变量同样生效
  （`export QEMU='qemu-system-riscv64 -kernel bin/ucore.img'` 后原生 `make qemu` 即可跑通）——
  本组 harness 正是靠这一条在不改 Makefile、不改 harness 的前提下跑出 ALL PASS。

**Requirements**：排障必须"只改一个变量"（D1/D2 读的是同一个地址 0x1038）；
不得用"可能是 QEMU 版本问题"这种未证结论收尾，必须落到具体字段。
```

### 功能模块四 · 第一次迭代

**提示词**：见本模块“最终提示词（全文）”——该次迭代**没有重写整段提示词**，只按下列改动点调整了对应段落。

**结果（遇到的问题）**：

- 问题 1：`make qemu` 编译全绿、OpenSBI 横幅完整，但**没有** `(THU.CST) os is loading ...`，进程一直不退出（被 `timeout -s KILL` 强杀，退出码 137）；横幅显示 `Domain0 Next Address : 0x0000000000000000`。

**下一步调整**：

- 针对问题 1：先按教程 tips 尝试 `watch *0x80200000`——**未命中**。这一步虽未解决问题，但排除了一个错误假设（"内核根本没被写进内存"），因为实测 0x80200000 里已有内核机器码。于是把问题重新表述为："镜像确在内存，但固件不知道该跳到哪" → 去找固件读取入口地址的地方（`fw_dynamic_info`），而不是继续猜 QEMU 行为。

**产物**：见 report.md 该模块的“模块功能描述 / 实现迭代过程”与 `lab1/logs/` 下的同名日志。

### 功能模块四 · 第二次迭代

**提示词**：见本模块“最终提示词（全文）”——该次迭代**没有重写整段提示词**，只按下列改动点调整了对应段落。

**结果（遇到的问题）**：

- 问题 2：如何证明根因就是 `next_addr`，而非别的差异（固件版本、PMP 配置、镜像本身）？

**下一步调整**：

- 针对问题 2：做**只改一个变量**的对照实验——两次 GDB 会话（D1 = 教程原命令，D2 = 加 `-kernel`），都只读 `0x1018/0x1020/0x1028/0x1030/0x1038` 五个字段：前四个完全相同，**只有 `next_addr` 从 `0x0` 变成 `0x80200000`** ⇒ 根因不可再争辩。

**最终结果**：

-  根因定位到字段级（`fw_dynamic_info.next_addr`，偏移 `0x1038`）
-  修复后 `Domain0 Next Address = 0x80200000`，内核成功打印并进入 `while(1)`
-  **源码零改动**：`diff -r --brief` 无差异，21 个源文件 sha256 与存档逐一相同
-  该结论也解释了"为什么教程作者的机器上可以"（老版本 `-bios default` 是 `fw_jump`，跳转地址写死在固件里；此条为**推断**，已在本报告与台账中标注核对）

**产物**：见 report.md 该模块的“模块功能描述 / 实现迭代过程”与 `lab1/logs/` 下的同名日志。

**关键改进点（提示词层面的沉淀）**：

1. 在 `[RELY]` 里把"本机固件是 fw_dynamic、且目录里没有 fw_jump"作为硬事实写入，让"为何教程能跑"从一开始就有解释力；
2. 要求"只改一个变量"的对照实验，避免多因素混在一起导致误判；
3. 把"源码零改动"变成可证伪的交付物（`diff -r` 日志），而不是口头声明。

---

## 功能模块五：六组深度对照实验与两处结论修正

**负责人**：2410665-殷佳仪

### 功能模块五 · 最终提示词（全文）

```text
[PROMPT]
**任务**：为 lab1 设计并执行若干"对照实验"，把教材中只给结论、不给观测方法的说法
（S→M 特权级陷入、tail 与 call 的差别、.bss 清零、设备树内容、多 hart）变成可复现的实测结论；
若实验推翻了我们此前的写法，必须如实修正并留痕。
**操作要求**：涉及改代码的对照实验**只能在 /tmp 的副本上进行**（`cp -a` 后再改），
lab1 工作副本必须保持逐字节不变；每个实验都要有"改了什么（diff）、观察到什么（原始输出）、结论"。
**输出要求**：使用下面 [RELY]、[GUARANTEE]、[SPECIFICATION] 的信息；不得给出未实测的结论。

[RELY]
// 已有工具与地址
gdb + QEMU -s -S（远程调试）；QEMU -d in_asm -D <file>（记录真实执行流，含 Priv 字段）
qemu-system-riscv64 -machine virt,dumpdtb=<file> -display none（导出设备树）
// 关键地址（此前实测）
kern_entry=0x80200000 ; ecall 位于 0x80200492 ; OpenSBI 陷阱入口 0x80000408 ; mret 位于 0x8000968e
// harness 里 -smp 默认 1；OpenSBI 横幅会给出 Platform HART Count / Domain0 Boot HART / Domain0 HARTs

[GUARANTEE]
```text
logs/lab1/deep-evidence.txt        # 实验 1（tail vs call）
logs/lab1/deep-evidence-2.txt      # 实验 2/3/4（.bss 两连 / ecall 陷入 / DTB）
logs/lab1/extra-evidence.txt       # 实验 6（多 hart + in_asm）
logs/lab1/qemu-inasm-excerpt.txt   # 实验 5（特权级轨迹节选，完整日志 ~900KB 不入库）
logs/lab1/excerpt-EV27…EV30*.txt   # 各实验的"忠实节选"（只删行不改写）
```
必须产出的四条硬结论：
```text
1) tail = c.j（2 字节、不写 ra）；call = jal ra（写返回地址）
2) .bss=0 的机制是"未被引用 + --gc-sections"，不是"源码里没有零初始化全局量"
3) ecall 后 pc 进入 0x8000xxxx，且 mstatus.MPP=1（来自 S 模式）
4) QEMU in_asm 日志中 Priv 3→1 的切换点紧跟在 mret 之后
```

[SPECIFICATION]
## logs/lab1/deep-evidence*.txt
**Pre-Condition**：模块二/四的证据已在位；`/tmp` 可写；lab1 工作副本未改动。
**Post-Condition**：每个实验都留下"diff（改了什么）+ 原始输出（看到什么）+ 结论"三段；
对照实验结束后 lab1 工作副本的 21 个源文件 sha256 与存档一致。

  **Case 1（实验支持原有结论）**：直接给出证据，并在台账中标注"已用对照实验加强"。
  **Case 2（实验推翻原有结论）**：必须写清"原写法 → 实测事实 → 修正后的写法"，
  并同步修改所有受影响的位置（脚本标签、台账、报告），**不允许只改一处**。

**Requirements**：改码实验一律在 /tmp 副本；原始会话记录不得事后手改（必要时重跑生成）。
```

### 功能模块五 · 第一次迭代

**提示词**：见本模块“最终提示词（全文）”——该次迭代**没有重写整段提示词**，只按下列改动点调整了对应段落。

**结果（遇到的问题）**：

- 问题 1：第一版 `ecall` 实验只单步了 6 次，停在 `0x80200490`（`mv a2,a5`），**根本没跨过 `ecall`**，却已经打印了"若 PC 已在 0x800xxxxx"的说明——属于"结论先行"。
- 问题 2：`.bss` 实验中加了一个零初始化大数组，结果 `objdump -h` 里**仍然没有 `.bss`**，与"加了数组就会出现 .bss"的预期不符。

**下一步调整**：

- 针对问题 1：改用"单步直到 PC 跨区"的写法（单步 12 次并逐次打印 `pc`），实测第 8 步 `pc` 才跳到 `0x80000408`；并追加 `mstatus.MPP` 读数作为**判据**（而不是看现象说话）。
- 针对问题 2：**把失败本身变成实验**——设计"两连实验"：不引用 → 无 `.bss`；引用 → 有 `.bss`。由此不但解决了疑问，还**精确复现了 lab1 `.bss` 为空的机制**。

**产物**：见 report.md 该模块的“模块功能描述 / 实现迭代过程”与 `lab1/logs/` 下的同名日志。

### 功能模块五 · 第二次迭代

**提示词**：见本模块“最终提示词（全文）”——该次迭代**没有重写整段提示词**，只按下列改动点调整了对应段落。

**结果（遇到的问题）**：

- 问题 3：`-d in_asm` 日志抓到后，用 `grep "^IN: 0x..."` 找不到任何地址块（计数全为 0），说明检索假设与 QEMU 的真实格式不符。

**下一步调整**：

- 针对问题 3：查看日志原文后发现格式是 `IN:` 换行 + `Priv: N; Virt: 0` + 指令行，于是改按 `Priv:` 与 `^0x...:` 检索，并把 `Priv` 字段**升级为实验目标**（特权级轨迹）。

**产物**：见 report.md 该模块的“模块功能描述 / 实现迭代过程”与 `lab1/logs/` 下的同名日志。

### 功能模块五 · 第三次迭代

**提示词**：见本模块“最终提示词（全文）”——该次迭代**没有重写整段提示词**，只按下列改动点调整了对应段落。

**结果（遇到的问题）**：

- 问题 4：在 `-smp 4` 实验里，我们事先写好的解读是"只有 hart0 属于 Domain0"，但实测横幅是 `Domain0 HARTs : 0*,1*,2*,3*`、**`Domain0 Boot HART : 1`**——预设解读与事实不符。

**下一步调整**：

- 针对问题 4：**保留实测、删除预设**。最终表述改为："`-smp 4` 时 4 个 hart 都归 Domain0，且**引导 hart 是 1 号**（`Boot HART ID : 1`），内核仍正常打印 ⇒ `a0` 里的 hartid 不一定是 0；本组单 hart 运行时为 0。"（EV-32）

**最终结果**：

-  六组实验全部完成并落盘，四条硬结论全部拿到原始证据
-  查出并修正两处结论错误（复位向量条数、`.bss` 机制），并连带修正脚本/台账/报告
-  对照实验全程在 `/tmp` 副本进行，lab1 源码 21/21 sha256 始终未变

**产物**：见 report.md 该模块的“模块功能描述 / 实现迭代过程”与 `lab1/logs/` 下的同名日志。

**关键改进点（提示词层面的沉淀）**：

1. 单步实验必须**以判据收尾**（如 `mstatus.MPP`），不能只"看着像"就下结论；
2. 实验"失败"往往比成功更值钱——`.bss` 的两次实验就是由一次失败催生的；
3. 预先写好的解读必须在实测后复核，**宁可删掉预设，也不能让预设覆盖事实**。


