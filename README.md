# 操作系统实验 3：断，都可以断（lab3）

本目录是 lab3 的完整交付：可编译源码、官方评分日志、串口证据截图、实验报告与 Prompt 记录。

## 目录结构

```text
lab3/
├── README.md                 # 本文件
├── code/                     # 可编译的 ucore lab3 源码
│   ├── kern/trap/trapentry.S # 模块 A：SAVE_ALL / RESTORE_ALL / __alltraps
│   ├── kern/trap/trap.c      # 模块 B：中断与异常分发
│   ├── kern/init/lab3_switch.c  # Challenge 1：S -> U -> S 往返
│   ├── Makefile
│   └── tools/grade.sh
└── report/
    ├── report.md             # 实验报告（课程 7 条要求的逐条回答）
    ├── prompt.md             # 每个模块的 spec / prompt / 审查清单 / bug 记录
    ├── 分工与架构设计.md      # 三人的分工、接口契约、时间线与验收标准
    ├── logs/                 # 构建、运行、静态反汇编原始日志
    ├── images/               # 与日志数值一致的截图
    └── tests/                # 自建边界测试说明
```

## 环境

- `riscv64-unknown-elf-gcc` 工具链
- `qemu-system-riscv64` 7.0（使用 `-kernel bin/ucore.img` 启动）
- GNU Make、Python 3（官方评分脚本需要）

## 构建与评分

```bash
cd code
make                 # 默认构建，产出 bin/ucore.img
make qemu            # 启动 QEMU，Ctrl-A X 退出
make grade           # 官方三项评分
```

## Challenge 1

Challenge 默认不参与构建，需显式打开宏：

```bash
cd code
make clean
make DEFS=-DLAB3_CHALLENGE_SWITCH
make DEFS=-DLAB3_CHALLENGE_SWITCH qemu
```

串口预期输出：

```text
[Challenge 1] user ecall: scause=0x8, a0=0x55
[Challenge 1] back to S-mode, satp restored to kernel page table
[Challenge 1] PASS: S -> U -> S round trip completed
```

## 最终结果

```text
trap entry, register restore, and breakpoint EPC: PASS (35/35)
illegal instruction EPC advance and return: PASS (25/25)
re-armed supervisor timer and repeated trap return: PASS (40/40)
Total Score: 100/100
```

Challenge 1 单独构建实测 `PASS`，默认评分路径不受影响。

## 证据入口

- 官方评分原始输出：`report/logs/run/grade-final.log`
- 断点现场恢复：`report/logs/run/CONTEXT.final.log`
- 非法指令返回：`report/logs/run/ILLEGAL.final.log`
- 定时器重装：`report/logs/run/TIMER.final.log`
- Challenge 串口：`report/logs/run/CHALLENGE.serial.log`
- 静态反汇编：`report/logs/static/`
- 截图：`report/images/shot-L3-01` 至 `shot-L3-06`

## 分工

| 成员 | 学号 | 负责内容 |
|---|---|---|
| 殷佳仪 | 2410665 | 总体架构、模块 A、报告统稿、最终审核 |
| 宋秋实 | 2410749 | 模块 B、全组运行与验证 |
| 兰雨杉 | 2412090 | Lab2 依赖移植、QEMU 适配、Challenge 1、仓库整理 |

细则见 `report/分工与架构设计.md`。