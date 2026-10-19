# Lab2 提示词归档（`prompt.md`）

> 本文件是 lab2 实验的**提示词（prompt）与规格说明（spec）全量归档**，与
> `report/report.md` 同源。正文各章节只摘引关键段，完整原文以本文件为准。
>
> 归档规范（延续 lab1）：
> 1. 每位成员的**最终 prompt** 与**每次迭代追加的 prompt** 都追加进来，不删历史；
> 2. 每条 prompt 前面写清"**负责模块 / 学号 / 用在哪一步**"，便于助教对照代码；
> 3. 报告里凡是引用 prompt 的地方，都指向本文件的具体小节。

---

## 0. 使用说明

本实验的 AI 协作方式统一沿用 lab0.5 定下的**四段式**
`[RELY] → [GUARANTEE] → [SPECIFICATION] → [PROMPT]`：

| 段 | 含义 | 归档位置 |
|---|---|---|
| `[RELY]` | 可以依赖什么——宏定义、数据结构、已有函数（**只许用，不许重新实现**） | 每个编程模块的 X.1 |
| `[GUARANTEE]` | 必须实现或修改什么——交付函数清单、修改点、禁止改动项 | 每个编程模块的 X.2 |
| `[SPECIFICATION]` | 每个函数的详细行为规格——函数语义 / 不变式 / 边界与异常 | 每个编程模块的 X.3 |
| `[PROMPT]` | 做什么、改哪里、怎么改——实际发给模型的完整文本（末尾引用上面三段全文） | 每个编程模块的 X.4 |
| 迭代追加 | 踩坑之后的追问 prompt（只补差量，不重发全文） | 本文件 §7 |
| 裁定 | 编译（`-Werror`）+ 官方判据 / 自测判据的实测结果 | `lab2/logs/` |

同一份 spec/prompt 在报告正文中的引用位置：模块一 → §四 1.2/1.3；Best-Fit → §四 2-2.1/2-2.2；
Buddy → §四 3.2/3.3；SLUB → §四 4.2/4.3；GDB 分支 → §四 分支任务·要求⑥。

### 0.1 与仓库骨架约定的字段对应

仓库里的 `prompt.md` 骨架要求"每完成一次有效迭代追加一条，记录**提示词 / 结果 / 下一步调整 / 产物 / 截图**"。本文件按同一份信息来组织，只是把字段拆到两处，这样报告正文引用起来更直接：

| 骨架字段 | 本文件里的对应位置 |
|---|---|
| 提示词 | §1~§5 各编程模块的 `[RELY]` / `[GUARANTEE]` / `[SPECIFICATION]` / `[PROMPT]` 全文；§6 GDB 问答 prompt；§7 迭代追加 prompt |
| 结果 | 报告 §四 1.5 / 2-2.4 / 4.4 的迭代过程，以及 `lab2/logs/` 里的原始输出 |
| 下一步调整 | 每条追加 prompt 开头写清的"上一轮哪里不对、这一轮只补什么" |
| 产物 | 各节标题下标注的目标文件（如 `kern/mm/pmm.c`）与报告 §四 对应实现小节 |
| 截图 | `report/images/shot-EV*.png`，编号与报告正文一一对应 |

---

## 1. 模块一：`page_init()` 物理内存探测与页描述符初始化

**负责人**：2410665 殷佳仪　**目标文件**：`kern/mm/pmm.c`，替换 `//lab2 function1 YOUR CODE`

### 1.1 `[RELY]` 全文（可依赖的宏 / 数据结构 / 已有函数）

```text
[RELY] kern/mm/pmm.c :: static void page_init(void)

目标平台: ucore/riscv64, Sv39, PGSIZE=4096, DRAM_BASE=0x80000000
          PHYSICAL_MEMORY_OFFSET=0xFFFFFFFF40000000, KERNBASE=0xFFFFFFFFC0200000
          nbase = DRAM_BASE / PGSIZE = 0x80000

可依赖的已有函数（直接调用，不重新实现）:
  get_memory_base(), get_memory_size()  —— DTB 探测到的物理内存 base/size（字节）
  init_memmap(struct Page *base, size_t n) —— 把 n 个空闲页登记进分配器
  PADDR(kva) / pa2page(pa) / ROUNDUP / ROUNDDOWN / PPN / PGSIZE

可依赖的数据结构与宏:
  struct Page 的 flags/property/ref/page_link 及 SetPageReserved 等宏
  extern char end[];  —— 链接脚本定义的"内核镜像末尾"符号
```

### 1.2 `[GUARANTEE]` 全文（必须实现 / 修改的交付清单）

```text
[GUARANTEE] kern/mm/pmm.c :: static void page_init(void)

交付: 实现 static void page_init(void)，函数返回时必须成立的全局状态:
  va_pa_offset == PHYSICAL_MEMORY_OFFSET
  npage  == PPN(ROUNDDOWN(mem_base + mem_size, PGSIZE))
  pages  == 指向位于内核 end 之后、页对齐的 struct Page 数组
  pages 描述 [nbase, npage) 共 (npage - nbase) 个物理页
  空闲区 = [ROUNDUP(pages 数组末尾, PGSIZE), ROUNDDOWN(mem_base+mem_size, PGSIZE))
  上述空闲区已全部通过 init_memmap() 登记，且每页进入前都是 PageReserved

禁止改动项（违反即视为不合规）:
  * 不得修改 struct Page 的定义与 memlayout.h 的常量
  * 不得修改 tools/test_lab2.c 里的 test_page_init() 及其判据
  * 不得在 pmm.c 里 #include <test_lab2.h>
  * 不得在 Makefile 中出现 kern/test 相关目标名
  * 必须保留 //lab2 注释点，只替换 YOUR CODE
```

### 1.3 `[SPECIFICATION]` 全文（函数详细行为规格）

```text
[SPECIFICATION] kern/mm/pmm.c :: static void page_init(void)

不变式（必须逐条自检）:
  I1  va_pa_offset 被赋值；否则 PADDR 全部失效
  I2  npage > nbase，且 npage == PPN(mem_end)
  I3  (uintptr_t)pages % PGSIZE == 0 且 pages >= ROUNDUP((uintptr_t)end, PGSIZE)
      空闲区起点 >= pages 数组末尾（即数组自身占用的页不在空闲区）
  I4  先把 [nbase,npage) 全部 SetPageReserved，再调用 init_memmap
      没有"完整页"时不得调用 init_memmap（n==0 会让 assert(n>0) 失败）

边界与异常:
  mem_base==0 || mem_size==0            -> panic
  npage <= nbase                        -> panic
  pages 数组放不进内存 (pages_end > mem_end) -> panic
  空闲区为空 (free_start >= mem_end)     -> 打印 warning 并直接返回，不调用 init_memmap
  mem_end 未页对齐                       -> 向下取整，残段不构成完整物理页
```

### 1.4 `[PROMPT]` 全文（做什么、改哪里、怎么改）

```text
请你以一位写 ucore/riscv64 实验代码的助教身份，严格按照我给出的
[RELY]/[GUARANTEE]/[SPECIFICATION] 实现 kern/mm/pmm.c 中的 static void page_init(void)。

要求：
1) 只输出这一个函数的完整 C 代码（含注释），不要输出其它文件的修改。
2) 每一行都要能对应到我给的某条不变式，请在代码里用一句话注释说明它在满足哪条不变式。
3) 必须处理我列出的全部边界与异常分支（panic / warning / 不调用 init_memmap）。
4) 必须把 [nbase, npage) 先整段标成 Reserved，再单独把"完整空闲区"交给 init_memmap()；
   请用注释说明"为什么顺序不能反"。
5) 不允许修改 struct Page、memlayout.h 常量、tools/ 下任何内容、以及 test 函数。
6) 时间复杂度控制在 O(npage - nbase) 以内，不要做嵌套遍历。
7) 最后用 3 句话回答：
   a) 为什么 pages[] 要覆盖整段物理内存，而不是只覆盖空闲区？
   b) 为什么空闲区下界要用 ROUNDUP、上界要用 ROUNDDOWN？
   c) 如果不做 (b) 的两处取整，最坏会出现什么后果（不必崩溃，只说要错在哪里）。

[RELY] / [GUARANTEE] / [SPECIFICATION]
（……上文 1.1 / 1.2 / 1.3 的全文……）
```

---

## 2. Challenge 1-2：硬件的可用物理内存范围获取（思考题）

**负责人**：2410665 殷佳仪　**性质**：思考题（不产出代码）

本题我们**没有让模型直接给答案**，而是让它先给出**候选路径清单与每条路径的验证方式**，
再由我们逐条实测取证（结论见 §四 Challenge 1-2，实测见 `logs/gdb/gdb-memory-probe.log`、
`logs/static/dtb-memory-node.txt`）。

### 2.1 `[PROMPT]` 全文

```text
背景：我正在做 ucore/riscv64 的 OS 实验，已经看到内核启动时能打印出物理内存范围
（128 MB，0x80000000 起）。老师的问题是：

"如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？"

请你不要直接给结论文章，而是按下面的格式给我一份"候选清单"：

1) 列出在 RISC-V 平台上所有可能可行的途径（标准做法 + 兜底做法 + 体系结构类比）；
2) 每条途径分别给出：
   - 机制原理（谁探测、结果怎么交给 OS、OS 侧读哪里）；
   - 在本实验环境（QEMU virt + OpenSBI v1.0 + ucore/riscv64）下，
     我可以通过什么具体手段**当场验证**这条途径（例如读某个寄存器、读某个节点的某个属性、
     或做一次写-回读实验），给出可执行的操作步骤；
   - 这条途径的局限/风险（什么时候不该用它）；
3) 明确指出"哪些看起来很合理、但实际上拿不到内存大小"的做法，并说明为什么
   （例如某条 CSR 到底给不给内存总量），我需要知道边界在哪，避免写错。

约束：不要给我无法验证的断言。凡是"某个标准规定……"，请说明是哪个标准的哪一条。
```

---

## 3. 模块二 2-2：Best-Fit 连续物理内存分配

**负责人**：2410749 宋秋实　**目标文件**：`kern/mm/best_fit_pmm.c` + `kern/mm/pmm.c` 的 `init_pmm_manager()`

### 3.1 `[RELY]` 全文（可依赖的宏 / 数据结构 / 已有函数）

```text
[RELY] kern/mm/best_fit_pmm.c :: Best-Fit 连续物理内存分配器

背景: 框架不提供任何管理函数的声明/注册结构，需要自行设计。

可依赖的已有代码（直接使用，不重新实现）:
  basic_check() / best_fit_check()  —— 框架测试函数（tools/test_lab2.c，禁止修改）
  libs/list.h 的双向循环链表宏（list_init / list_add / list_del / list_next / le2page 等）
  struct Page（kern/mm/memlayout.h）及其 PG_property / property 字段
  struct pmm_manager（kern/mm/pmm.h）的成员函数签名与注册结构
```

### 3.2 `[GUARANTEE]` 全文（必须实现 / 修改的交付清单）

```text
[GUARANTEE] kern/mm/best_fit_pmm.c :: Best-Fit 连续物理内存分配器

必须自行设计并提供:
  ① 内部状态: free_area_t（free_list 头 + nr_free 计数）
  ② 六个成员函数: init / init_memmap / alloc_pages / free_pages / nr_free_pages / check
  ③ 注册实例: const struct pmm_manager best_fit_pmm_manager

额外修改点:
  在 kern/mm/pmm.c 的 init_pmm_manager() 中把默认管理器切到
  best_fit_pmm_manager（否则内核与评分仍走 First-Fit）。

禁止改动项:
  * basic_check() 与 best_fit_check() 一个字都不许改
  * 不得新增/修改 struct Page 的字段
  * 必须保留 lab2 注释点，把 YOUR CODE 换成学号 2410749
```

### 3.3 `[SPECIFICATION]` 全文（每个函数的详细行为规格）

```text
[SPECIFICATION] kern/mm/best_fit_pmm.c :: Best-Fit 连续物理内存分配器

每个函数的详细行为（必须与测试函数的用法一致）:
  init()                    : 清空链表, nr_free = 0
  init_memmap(base, n)      : base 起 n 页作为一个空闲块登记; 进入前 assert(PageReserved)
                              进入后该块首页 PageProperty=1 且 property=n; nr_free += n
  alloc_pages(n)            : n > nr_free -> NULL; 否则在各 property>=n 的块中选
                              property 最小的（并列取地址最小者，保证确定行为）
                              剩余部分留在原地址尾部并挂回链表（保持地址升序）
  free_pages(base, n)       : 归还并合并物理相邻的前驱/后继空闲块
  nr_free_pages()           : 返回 nr_free
  check()                   : 直接用框架的 best_fit_check（禁止修改它）

必须成立的不变式:
  I1 空闲链表始终按物理页号升序
  I2 只有块首页 PageProperty==1；块内其余页 PageProperty==0
  I3 链表所有 property 之和 == nr_free
  I4 分配走后首页 PageProperty==0（表示"已分配"）
  I5 重复分配-释放后，链表结构（块数与各块大小）必须回到原点
```

### 3.4 `[PROMPT]` 全文（做什么、改哪里、怎么改）

```text
你现在是 ucore/riscv64 实验的助教。请根据下面的 [RELY]/[GUARANTEE]/[SPECIFICATION]，
在 kern/mm/best_fit_pmm.c 中实现一个完整的 Best-Fit 连续物理内存分配器。

要求：
1) 先阅读我给你的 libs/list.h（双向循环链表宏）与 kern/mm/pmm.h 里的
   struct pmm_manager 定义，按各成员职责自行设计内部状态；
2) 关键：Best-Fit 与 First-Fit 的唯一差别在"选块"。请在 alloc_pages 里
   **扫描完整条链表**，在所有 property >= n 的块中挑 property 最小的那个；
   若并列，取物理地址最小的，保证行为确定、可复现。请在代码注释里写清这一点。
3) init_memmap / free_pages 里的插入必须保持链表按地址升序，否则相邻合并会失效；
   请在注释里解释"为什么升序是合并的前提"。
4) free_pages 需要合并物理相邻的前驱与后继，合并后旧的块头要 ClearPageProperty。
5) 每个函数上方用两行注释写明它满足哪条不变式。
6) 不得修改 basic_check() 与 best_fit_check()；保留 lab2 注释点。
7) 最后给出 best_fit_pmm_manager 的注册结构，并说明为什么把它放在文件末尾。

[RELY] / [GUARANTEE] / [SPECIFICATION]
（……上文 3.1 / 3.2 / 3.3 的全文……）

另外请回答：如果我把"并列取地址最小者"这一条去掉，best_fit_check() 里哪一条
断言可能变成不确定的？为什么？
```

---

## 4. Challenge 2-3：Buddy System 伙伴系统（两份 prompt）

**负责人**：2412090 兰雨杉　**目标文件**：`kern/mm/buddy_system_pmm.c` / `.h`
**接入**：`make DEFS=-DUSE_BUDDY_PMM`（默认路径不变，仍是 Best-Fit）

### 4.1 第一份 prompt：从零生成模块并接入内核

#### 4.1.1 `[RELY]` 全文

```text
[RELY] Challenge 2-3 :: Buddy System 页级分配器

可依赖的已有代码（直接使用，不重新实现）:
  struct pmm_manager（kern/mm/pmm.h）—— 六个成员函数的签名与注册结构
  struct Page（kern/mm/memlayout.h）—— 用 PG_property 标记"空闲块首页"，
    用 property 字段记录"本块有多少页"
  libs/list.h 的双向循环链表宏
  free_area_t 组织每个阶的链表
  上层接口 alloc_pages(n) / free_pages(page, n) 与其它分配器保持一致
```

#### 4.1.2 `[GUARANTEE]` 全文

```text
[GUARANTEE] Challenge 2-3 :: Buddy System 页级分配器

交付清单:
  buddy_system_pmm.h 与 buddy_system_pmm.c 完整代码
  实现 struct pmm_manager 全部六个成员函数:
    init / init_memmap / alloc_pages / free_pages / nr_free_pages / check
  导出 const struct pmm_manager buddy_system_pmm_manager 供 pmm.c 引用

修改点:
  在 kern/mm/pmm.c 的 init_pmm_manager() 中加编译期开关:
    make DEFS=-DUSE_BUDDY_PMM 时用 buddy_system_pmm_manager，
    否则保持默认（默认必须是 best_fit_pmm_manager，不能破坏评分路径）

纪律与禁止改动项:
  * 保留所有 lab2 注释；新增代码用 //lab2 challenge 2-3 2412090 标注
  * 不要修改 tools/ 下任何文件
  * 不要修改 basic_check / best_fit_check
```

#### 4.1.3 `[SPECIFICATION]` 全文

```text
[SPECIFICATION] Challenge 2-3 :: Buddy System 页级分配器

算法参数:
  阶数 0..11（单块最大 2048 页 = 8MB）

每个函数的详细行为:
  init()                    : 初始化每个阶的空闲链表, nr_free = 0
  init_memmap(base, n)      : 把 [base, base+n) 切成"最大且自身按阶对齐"的自然块
                              序列，逐块挂进对应阶链表（伙伴系统的规范初始化方式）
  alloc_pages(n)            : n > 空闲总数返回 NULL；取 need = ceil(log2(n))；
                              从最小有块可用的阶 j >= need 开始，逐级对半劈开，
                              右半块挂入低阶链表，左半块继续劈，返回 need 阶对齐块
  free_pages(base, n)       : 挂回对应阶，然后循环 buddy_idx = idx ^ size 检查伙伴；
                              伙伴同阶空闲则合并并升阶；新块首取地址较小者；
                              伙伴超出可管理内存 (npage-nbase) 时终止
  nr_free_pages()           : 各阶块页数之和
  check()                   : buddy_system_check()（见第二份 prompt 的 4.2）

必须成立的不变式:
  I1 各阶块页数之和 == nr_free
  I2 只有块首页 PageProperty=1；块内其余页 PageProperty==0
```

#### 4.1.4 `[PROMPT]` 全文

```text
你是 ucore/riscv64 实验的助教。请参考现有 ucore 物理内存管理框架，从零生成一个
完整的 Buddy System（伙伴系统）页级分配器，并接入内核。

要求：
1) 严格按照下面的 [RELY]/[GUARANTEE]/[SPECIFICATION] 实现，不得偏离阶数上限、
   切块方式与合并终止条件。
2) 每个函数上方用注释说明它维护了哪条不变式。
3) 保留所有 lab2 注释；新增代码用 //lab2 challenge 2-3 2412090 标注。
4) 说明：为什么 init_memmap 要把空闲区切成"最大且自身按阶对齐"的自然块序列。

[RELY] / [GUARANTEE] / [SPECIFICATION]
（……上文 4.1.1 / 4.1.2 / 4.1.3 的全文……）

【输出】
给出 buddy_system_pmm.h 与 buddy_system_pmm.c 的完整代码，每个函数上方用注释
说明它维护了哪条不变量。
```

### 4.2 第二份 prompt：针对该算法设计测试

#### 4.2.1 `[RELY]` 全文

```text
[RELY] Challenge 2-3 :: buddy_system_check() 自测设计

可依赖（已生成并接入的模块与接口）:
  buddy_system_pmm 模块（alloc_pages / free_pages / nr_free_pages）
  cprintf 输出
  nr_free_pages() 与各阶链表的观测
```

#### 4.2.2 `[GUARANTEE]` 全文

```text
[GUARANTEE] Challenge 2-3 :: buddy_system_check() 自测设计

交付:
  buddy_system_check() 作为 pmm_manager 的 .check 成员被调用
  输出格式: 用 cprintf 逐条打印 "  [ok] xxx" / "  [FAIL] xxx (line N)"
  最后打印 [Test B] Buddy System: PASS/FAIL

禁止改动项:
  * 不得修改框架的 basic_check / best_fit_check
  * 不得修改 tools/ 下任何文件
```

#### 4.2.3 `[SPECIFICATION]` 全文

```text
[SPECIFICATION] Challenge 2-3 :: buddy_system_check() 自测设计

每个测试用例的详细行为（必须覆盖的核心行为）:
  B1 初始切块：遍历每个阶的链表，检查
     - 每个块的 property == 2^order；
     - 块首页号 (p - pages) 按 2^order 对齐；
     - 所有阶的 property 之和 == nr_free_pages()。
  B2 往返不变性：先记录"阶分布指纹"（每个阶的块数），分配 1 页再释放，
     指纹必须逐阶一致 —— 说明 split 与 coalesce 互为逆操作。
  B3 2 的幂次上取整：alloc_pages(3) 必须返回 property==4 且页号按 4 页对齐的块。
  B4 拆分正确性：连续分配 8 个单页，8 个页描述符必须两两不同（拆分不重叠）。
  B5 合并正确性：按 LIFO 顺序把这些页归还后，阶分布指纹必须回到原点。
  B6 边界：alloc_pages(nr_free + 1) 必须返回 NULL，且不改变 nr_free。
  B7 压力：连续分配 64 个单页、再逆序全部释放，指纹与 nr_free 都必须复原。
```

#### 4.2.4 `[PROMPT]` 全文

```text
请针对你刚才生成的 Buddy System 实现，设计一份能真正抓住伙伴系统特有错误的
自测函数 buddy_system_check()（作为 pmm_manager 的 .check 成员被调用），
在【能分配能释放】之外，逐条实现 [SPECIFICATION] 里的 B1~B7。
测试必须用 cprintf 逐条打印 "  [ok] xxx" / "  [FAIL] xxx (line N)"，
最后打印 [Test B] Buddy System: PASS/FAIL。

[RELY] / [GUARANTEE] / [SPECIFICATION]
（……上文 4.2.1 / 4.2.2 / 4.2.3 的全文……）

另外请回答：
- 为什么"阶分布指纹前后比对"能抓住 split/coalesce 不对称的 bug，
  而仅仅"分配返回非 NULL"抓不住？
- 为什么 B6 必须用 nr_free+1 而不是别的数？
```

---

## 5. Challenge 2-4：SLUB 任意大小内存分配（两份 prompt）

**负责人**：2412090 兰雨杉　**目标文件**：`kern/mm/slub_pmm.c` / `.h`（全新文件）
**接入**：`make DEFS=-DCHALLENGE_SLUB_TEST`（在 `pmm_init()` 的 `check_alloc_page()` 之后追加 `slub_init(); slub_check();`）

### 5.1 第一份 prompt：从零生成 SLUB 模块并接入内核

#### 5.1.1 `[RELY]` 全文

```text
[RELY] Challenge 2-4 :: SLUB 任意大小内存分配模块

可依赖（第一层页级分配，SLUB 不允许自己碰 DRAM）:
  alloc_pages(n) / free_pages(page, n) —— 已实现的页分配器
    （架在 Best-Fit 或 Buddy System 之上，SLUB 必须完全通过它拿页/还页）
  struct Page / libs/list.h / pmm.h 等既有框架
```

#### 5.1.2 `[GUARANTEE]` 全文

```text
[GUARANTEE] Challenge 2-4 :: SLUB 任意大小内存分配模块

交付清单:
  slub_pmm.h 与 slub_pmm.c 完整代码
  第二层（对象级）对外只暴露两个函数:
    void *slub_alloc(size_t size);   // 成功返回对象地址，失败返回 NULL
    void  slub_free(void *ptr);      // ptr==NULL 时安全无操作
  观测接口（供自检与取证）:
    slub_nr_caches() / slub_total_pages() / slub_allocated_objects()

修改点:
  在 kern/mm/pmm.c 的 pmm_init() 末尾加编译期钩子:
    #if defined(CHALLENGE_SLUB_TEST) → slub_init(); slub_check(); #endif
  默认关闭，绝不影响 [Test 1]/[Test 2] 的评分路径。

纪律与禁止改动项:
  * 保留 lab2 注释；新增代码标注 //lab2 challenge 2-4 2412090
  * 不得修改 tools/ 下任何文件
```

#### 5.1.3 `[SPECIFICATION]` 全文

```text
[SPECIFICATION] Challenge 2-4 :: SLUB 任意大小内存分配模块

两层架构:
  第二层（对象级）只通过第一层拿页/还页；第一层不碰 DRAM，
  完全通过 alloc_pages / free_pages。

档次与 slab:
  大小档次: 8 B 起按 2 的幂次到 64 KiB，共 14 档；请求向上取整到最近档次；
  超过 64 KiB 的请求返回 NULL 并打印一行诊断。
  每个档次一个 kmem_cache；slab 元数据（kmem_slab）放在 slab 段首，
  内含 magic（0x534C5542）、容量、已用数、自由链表头、反向 cache 指针。
  slab 占页数取"最小的 2 的幂次"，使其至少装得下 64 字节元数据 + 1 个对象。
  对象区使用侵入式自由链表（空闲对象头 8 字节存下一个空闲对象地址），
  分配/释放都是 O(1)（LIFO）。
  当某个 slab 的 in_use 降为 0 时，把整段页 free_pages() 归还第一层。

关键不变式（最重要）:
  I1 段首元数据与所有对象的起始地址都必须落在 slab 的第 0 页内。
     因为 free() 手上只有对象指针，靠"指针向下按页对齐"(ptr & ~(PGSIZE-1))
     回溯段首；若对象起点落到后面的页，就会读错页的 magic 造成泄漏。
     为此容量 capacity 必须取两个上界的较小者：
       ① (slab_pages*PGSIZE - 64) / objsize
       ② (PGSIZE - 64 - 1) / objsize + 1
```

#### 5.1.4 `[PROMPT]` 全文

```text
你是 ucore/riscv64 实验的助教。请在没有现成代码框架的前提下，从零生成一个 SLUB
内存对象分配模块（两层架构），并接入现有内核。

要求：
1) 严格按照下面的 [RELY]/[GUARANTEE]/[SPECIFICATION] 实现，两层架构不得越界
   （对象层绝不自己碰 DRAM，只通过 alloc_pages/free_pages）。
2) 请在代码注释里解释容量公式"取两个上界较小者"这条推导。
3) 每个函数上方用注释说明它维护了哪条不变式。
4) 保留 lab2 注释；新增代码标注 //lab2 challenge 2-4 2412090。

[RELY] / [GUARANTEE] / [SPECIFICATION]
（……上文 5.1.1 / 5.1.2 / 5.1.3 的全文……）

【输出】slub_pmm.h 与 slub_pmm.c 完整代码 + 一段文字说明"为什么 free() 是 O(1)"。
```

### 5.2 第二份 prompt：针对 SLUB 设计测试

#### 5.2.1 `[RELY]` 全文

```text
[RELY] Challenge 2-4 :: slub_check() 自测设计

可依赖（已生成并接入的模块与接口）:
  slub 模块（slub_alloc / slub_free / 观测接口）
  pmm_manager 桩（用于故障注入）
  nr_free_pages()（页级观测）
```

#### 5.2.2 `[GUARANTEE]` 全文

```text
[GUARANTEE] Challenge 2-4 :: slub_check() 自测设计

交付:
  slub_check() 完整自测，用 cprintf 逐条打印 "  [ok] ..." / "  [FAIL] ..."，
  最后打印 [Test S] SLUB: PASS/FAIL。
  覆盖三类内容: 核心行为 / 边界情况 / 总量守恒。

禁止改动项:
  * 不得修改 tools/ 下任何文件
```

#### 5.2.3 `[SPECIFICATION]` 全文

```text
[SPECIFICATION] Challenge 2-4 :: slub_check() 自测设计

A. 核心行为:
  S1 档次映射：alloc(1)->8B、alloc(8)->8B（边界正好命中）、alloc(9)->16B
     （向上取整）、alloc(17)->32B、alloc(4096)->4KiB、alloc(65536)->最大档、
     alloc(65537) 被拒绝。
  S2 首次分配：建立 1 个 16B 缓存；首块 slab 只占 1 页；已分配对象计数 = 1。
  S3 打包：连续分配 32 个 16B 对象全部成功，且都落在同一个 slab 页内，
     过程中没有再向第一层要页。
  S4 几何：对象地址 8 字节对齐、两两不重叠。
  S5 分档隔离：200B 请求落到 256B 档，与 16B 档用不同 slab；活跃缓存数 = 2。
  S6 LIFO 复用：释放后立刻分配，必须原样返回同一个对象。
  S7 级联归还：把 16B 档全部释放后，空的 slab 必须整段还给第一层
     （对象层不再持有这一页），且已分配对象数归零。
  S8 全档次遍历：14 个档次都能分配出 2 个互不相同的对象，遍历后持有页数复原。

B. 边界情况:
  S9 alloc(0) 返回 NULL；alloc(64KiB+1) / alloc(1MiB) 返回 NULL；
     free(NULL) 安全；且所有失败请求都不留下记账残留。
  S10 故障注入：临时把 pmm_manager 换成一个"永远返回 NULL"的桩，验证
     第一层 OOM 时 slub_alloc 返回 NULL 且不留残留；自检结束后必须把
     pmm_manager 复原。

C. 总量守恒:
  S11 8 个 128B 对象全部分配后全部释放：
     - 已分配对象数归零；
     - 对象层持有页数回到初值；
     - 页级空闲页数（nr_free_pages）也回到自检开始时的值（证明无泄漏）。
  S12 把"设计不变式"写成断言：全部 14 个档次的对象起点都落在 slab 第 0 页内。
```

#### 5.2.4 `[PROMPT]` 全文

```text
请针对你刚才生成的 SLUB 实现，设计一份完整自测 slub_check()，用 cprintf 逐条
打印 "  [ok] ..." / "  [FAIL] ..."，最后打印 [Test S] SLUB: PASS/FAIL。
测试必须逐条实现 [SPECIFICATION] 里的 S1~S12（覆盖核心行为 / 边界情况 / 总量守恒三类）。

[RELY] / [GUARANTEE] / [SPECIFICATION]
（……上文 5.2.1 / 5.2.2 / 5.2.3 的全文……）

另外请回答：
- 为什么 S11 必须同时检查对象层记账和页级 nr_free_pages，只查一层会漏掉哪类 bug？
- 为什么 S12 这条断言是为了防止哪一类具体错误？
```

---

## 6. 分支任务：GDB 调试页表查询过程（5 个卡点的 prompt 全文）

**负责人**：2410665 殷佳仪　**对应报告位置**：§四 分支任务·要求⑥

> 这一节按"**卡在哪 → 我怎么问 → 模型给了什么 → 我怎么验证 → 最后结论**"组织。
> 下面 5 条是我们在卡点上**实际使用的提问原文**（已去除当时的临时上下文贴图描述，保留提问本体）。

### 6.1 卡点 1：WSL 里"先起 qemu 再 attach"被内核拒绝

```text
环境：Windows + WSL2 Ubuntu 22.04，用 riscv64-unknown-elf-gdb 调试 qemu-system-riscv64。
现象：我按指导书做 sudo gdb /opt/qemu/bin/qemu-system-riscv64 -p $(pidof qemu-system-riscv64)，
报错 "ptrace: Operation not permitted"。我这里没有 sudo 密码（sudo -n true 也失败）。

$ cat /proc/sys/kernel/yama/ptrace_scope
1

问题：在不修改 sysctl、不使用 root 的前提下，怎么让 gdb 能调试一个 qemu 进程？
请给出具体命令，并解释 ptrace_scope=1 到底允许什么、禁止什么。
注意我还需要 qemu 侧带 -S -s，让客户机 gdb 也能连上，请说明这两件事怎么共存。
```

### 6.2 卡点 2：QEMU 那么大，到底哪个函数是"查 TLB"

```text
我在调试 QEMU 的 RISC-V 地址翻译。riscv 的流程应该是先查 tlb，tlb miss 之后
才从页表中查找。请帮我找一下 QEMU 源码里"查找 tlb"的代码位置。

QEMU 版本：7.0.0。源码目录：target/riscv/、accel/tcg/、include/exec/。

要求：
1) 给出从"一次访存"到"TLB 命中/未命中"的完整函数调用链，标出每个函数的文件:行；
2) 明确区分"快路径（命中）"和"慢路径（未命中后查页表）"；
3) 指出 TLB 表项结构体叫什么、里面存的是什么（是 PPN 还是别的？为什么）；
4) 告诉我"翻译成功后写回 TLB"的那一行代码在哪；
5) 提醒我哪些地方是我容易搞错的。
```

### 6.3 卡点 3：`-Og` 优化下手工 `stepi` 页表遍历根本走不通

```text
我用 --enable-debug 编了 QEMU（等于 -Og -g），想在 gdb 里逐级观察
target/riscv/cpu_helper.c 里 for (i = 0; i < levels; i++, ptshift -= ptidxbits)
这个循环每一次迭代的 i、idx、pte 值。

问题：断在函数入口后一路 next，循环变量被优化进寄存器了，经常一跳就出函数，
用 -batch 还直接报错终止。单步完全不可用。

我希望：一次运行就能把"每次迭代的 i/idx/pte/判断结果"全部打印出来，
而且这个脚本要能重复跑、结果稳定。
请给出具体的 gdb 命令写法（不要只讲原理，要能直接粘进脚本）。
```

### 6.4 卡点 4：想编 QEMU 4.1.1，但本机没有 python2

```text
背景：指导书对应 QEMU 4.1.1，我想"完全照做"，把 4.1.1 编成 --enable-debug 版本。
环境：Ubuntu 22.04（WSL2），默认没有 python2。
现象：./configure 阶段就失败（报 python2 相关的脚本依赖问题）。

问题：我是应该去装 python2 把 4.1.1 编出来，还是干脆编与我本机运行版本相同的 7.0.0？
请从"调试目的"出发分析这两个选择的利弊，并告诉我如果选 7.0.0，
报告里怎么处理"指导书要求 4.1.1"这件事才既诚实又满足要求。
```

### 6.5 卡点 5：`-d in_asm` 的日志 1.2 MB，怎么从里面找到"有意义的那几行"

```text
我用 qemu-system-riscv64 -d in_asm,mmu 跑 ucore，日志有 1.2 MB。
日志里能看到这样的结构：

IN: 
0x0000000080200034:  csrrw    zero,satp,t0
...
IN: 
0x0000000080200038:  ...

问题：这个 "IN:" 是什么？为什么在 csrw satp 之后会换一个新的 IN 块，
而且新块的第一条指令地址还是低地址（0x80200038）？
这和我理解的"写了 satp 之后就应该用虚拟地址取指"对不上。

请解释 "IN:" 的含义，以及"改变地址翻译状态"会对它产生什么影响。
```

---

## 7. 迭代追加 prompt 记录（每轮踩坑后的补充问法）

> 这些是**只补差量**的追加 prompt，用于把"踩坑"变成"下一次不再踩"。
> 对应报告位置：§四 1.5（R5 专栏）、§四 4.4。

### 7.1 模块一 D1：`pages` 未页对齐

```text
你给的实现里 pages 直接取了 (struct Page *)end。但官方测试报
"[Test 1] Page Init: FAIL (pages not page-aligned)"。

请回答：
1) 为什么"放在内核 end 之后"还不够，必须再做页对齐？（从 struct Page 的
   访问方式与 CPU 对齐要求两个角度解释）
2) 如果只图省事，把 end 手动加 40 字节，能替代 ROUNDUP 吗？为什么不能？
3) 修正后请只给出被改动的那一行，不要重发整个函数。
```

### 7.2 模块一 D2：Reserved 与 init_memmap 顺序颠倒

```text
现在的实现在 init_memmap() 之后再补 SetPageReserved()，结果
assert(PageReserved(p)) 在 default_init_memmap 第一行就失败了。

请解释：
1) init_memmap() 里的 assert(PageReserved(p)) 到底在断言什么？
   它是"防御性检查"还是"所有权移交协议"？
2) 为什么"先登记空闲区、再补 Reserved"这个顺序在语义上是矛盾的？
3) 一个更本质的问题：为什么 OpenSBI 区、内核镜像区、pages[] 自己
   都必须保持 Reserved，而不是从 pages[] 里"删掉"？
```

### 7.3 模块一 D3：空闲区下界未取整（静默错误）

```text
我不小心发现了另一个更隐蔽的问题：空闲区起点直接用了 pages 数组末尾的物理地址
(pages_pa + pages_num*sizeof(struct Page))，没有向上页对齐。
它不崩溃，但 best_fit_check() 里的 assert(total == nr_free_pages()) 会失败。

请回答：
1) 为什么这个错"不崩不报错，只是数对不上"？多余的"半页"是怎么被算进去的？
2) 为什么用 ROUNDUP 就对了？和上界的 ROUNDDOWN 分别是为了解决什么问题？
3) 有没有办法让这类"静默错误"在**一开始写代码时**就不可能发生？
   （我想把结论写回 spec，请给我一句可以直接写进 spec 的话）
```

### 7.4 SLUB 多页 slab 释放 bug

```text
[Test S] 里有 5 条 FAIL，伴随 warn：
[SLUB] slub_free: 0x... is not a slub object (magic=0x0)

我的 free() 是靠 ptr & ~(PGSIZE-1) 回溯到 slab 段首再读 magic 的。
请帮我分析：
1) 什么情况下"对象指针向上取整到页首"会落到一张没有元数据的页上？
2) 我的容量公式是 capacity = (slab_pages*PGSIZE - 64) / objsize，
   它在 objsize 稍大时会让第 2 个对象起点越过第 0 页的边界吗？
   请用 objsize=4096、slab_pages=2 与 objsize=1024、slab_pages=1 两个例子算给我看。
3) 给出一个"容量取两个上界较小者"的修正公式，并说明第二个上界保证了什么。
4) 这个错的本质是什么？（提示：我说的是"分配侧"与"释放侧"的隐含前提没有统一）
5) 请给出可以把这条不变式固化下来的自测断言写法。
```

### 7.5 GDB：把"单步"换成"行断点 + 打印"

```text
我还想在报告里写清"为什么把单步换成行断点"这件事。
请在下面三点上给我一句话结论（不要太长）：
1) 优化编译下单步为什么不可靠？
2) 行断点 + commands/silent/printf/continue 相比单步，稳定性与可复现性好在哪？
3) 这种"不打断执行流、只旁路打印"的做法，和真实内核里用什么机制类比最贴切？
```

---

## 8. 附：AI 工具与环境（与 §二 一致）

| 项 | 值 |
|---|---|
| 使用的 AI 工具 | OpenAI Codex（终端 coding agent），全程未更换模型 |
| 协作方式 | 四段式 spec 先行（`[RELY]`/`[GUARANTEE]`/`[SPECIFICATION]`）→ AI 生成第一版 → 我们编译 + 官方判据裁定 → 回填 spec |
| 编译约束 | `riscv64-unknown-elf-gcc 16.1.0`，`-Werror`（任何 warning 即失败） |
| 验收命令 | `make grade`（20/20）、`make DEFS=-DUSE_BUDDY_PMM`、`make DEFS=-DCHALLENGE_SLUB_TEST` |

> 以上为本实验**全部 prompt 与 spec** 的归档。正文凡引用 prompt 处，均指向本文件的小节号。
