# Lab3 自建边界测试矩阵

官方 `make grade` 覆盖三项核心能力。为了线下演示和自查，我们另外在默认构建与 Challenge 构建下各走了一遍可复现路径，记录预期字符串与实测证据。表中"实测"列对应的原始输出都在 `report/logs/` 里，没有编造。

## 测试矩阵

| 编号 | 场景 | 触发方式 | 期望结果 | 实测证据 |
|---|---|---|---|---|
| T1 | 断点异常与现场恢复 | 官方 Test 1 注入 `ebreak` | 32 个通用寄存器逐一比对一致，`epc` 正确推进 | `logs/run/CONTEXT.final.log`，`PASS (35/35)` |
| T2 | 非法指令（2 字节压缩指令） | 官方 Test 2 注入非法指令 | 打印 `Illegal instruction at 0x...`，返回后继续执行 | `logs/run/ILLEGAL.final.log`，`PASS (25/25)` |
| T3 | 定时器续订与重复返回 | 官方 Test 3 | `ticks` 持续增长到 200，期间多次正常返回 | `logs/run/TIMER.final.log`，`ticks=200`，`PASS (40/40)` |
| T4 | 软件中断分支 | 触发 S 模式软件中断 | 打印 `Supervisor software interrupt` | `logs/run/TIMER.final.log` |
| T5 | 未知中断分支 | 触发未登记的 cause | 打印 `Unknown interrupt: cause 15`，不 panic | `logs/run/TIMER.final.log` |
| T6 | 未知异常分支 | 触发未登记异常 | 打印完整 trapframe（含 `cause 0x00000014`） | `logs/run/ILLEGAL.final.log` |
| T7 | 特权级往返 | `make DEFS=-DLAB3_CHALLENGE_SWITCH` | S → U → S 完整往返，`scause=0x8`、`a0=0x55` | `logs/run/CHALLENGE.serial.log` |
| T8 | 默认构建零影响 | 不打开宏直接 `make grade` | 仍为 100/100 | `logs/run/grade-final.log` |

## 演示顺序

1. `make grade`：先给助教看总分 100/100 与三项分项。
2. 打开 `logs/run/CONTEXT.final.log`：指到 `Breakpoint at 0xffffffffc0201a04` 与寄存器比对段。
3. 打开 `logs/run/ILLEGAL.final.log`：指到 `Illegal instruction at 0xffffffffc02019b6`，说明 2 字节推进。
4. 打开 `logs/run/TIMER.final.log`：指到 `ticks=200`、`Supervisor software interrupt`、`Unknown interrupt: cause 15`。
5. 最后跑 Challenge，展示 `scause=0x8` 与 `satp restored`。

## 判读方法

日志是 QEMU 串口原样输出，判读时只看三类信息：

- **分数行**：`PASS (xx/xx)` 与 `Total Score`。
- **地址与原因**：`Breakpoint at`、`Illegal instruction at`、`cause 0x...`。
- **计数**：`ticks=200` 说明定时器被重复续订，不是只进了一次中断。

如果 `ticks` 停在 100，说明 `clock_set_next_event()` 没有在中断入口续订；如果断点返回后立刻出现非法指令，说明 `epc` 被固定加了 4 而实际指令是 2 字节。这两种现象我们都真实遇到过，修复过程写在 `report/prompt.md` 第 9 节。