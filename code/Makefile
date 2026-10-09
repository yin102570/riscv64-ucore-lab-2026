# lab1 构建脚本：编译 libs/ 与 kern/ → 按 tools/kernel.ld 链接出 bin/kernel → objcopy 成 bin/ucore.img。
# 常用目标：make / make qemu / make debug / make gdb / make clean。
PROJ	:= lab1
EMPTY	:=
SPACE	:= $(EMPTY) $(EMPTY)
SLASH	:= /

# V=@ 表示不回显命令；改成空值即可打印每条命令，排查构建问题时有用。
V       := @

# ⚠ Makefile 里以 # 开头即注释，所以下面 “#ifndef GCCPREFIX … #endif” 并未生效，
#   第 9 行的赋值是无条件执行的。
#ifndef GCCPREFIX
GCCPREFIX := riscv64-unknown-elf-
#endif

# 这一处才是真正生效的条件赋值：可通过 make QEMU=/path/to/qemu-system-riscv64 覆盖。
ifndef QEMU
QEMU := qemu-system-riscv64
endif


# 清掉内置后缀规则，避免 make 按默认规则擅自编译文件。
# eliminate default suffix rules
.SUFFIXES: .c .S .h

# 规则执行失败就删掉已生成的目标，避免半成品被后续 make 误用。
# delete target files if there is an error (or make is interrupted)
.DELETE_ON_ERROR:

# define compiler and flags
HOSTCC		:= gcc
HOSTCFLAGS	:= -Wall -O2

GDB		:= $(GCCPREFIX)gdb

CC		:= $(GCCPREFIX)gcc
# -mcmodel=medany：内核加载在 0x80200000，超出 medlow 允许范围，必须用 medany（PC 相对寻址）。
# -std=gnu99 提供 case 区间、语句表达式等扩展；-Wno-unused 配合 -Werror 容忍骨架里的空实现。
CFLAGS  := -mcmodel=medany -std=gnu99 -Wno-unused -Werror
# -fno-builtin 强制调用自备的 memset 等实现；-nostdinc 不搜索系统头文件；-O2 优化。
CFLAGS	+= -fno-builtin -Wall -O2 -nostdinc $(DEFS)
# -ffunction-sections/-fdata-sections 让每个函数/数据独立成节，为链接期 --gc-sections 做准备。
CFLAGS	+= -fno-stack-protector -ffunction-sections -fdata-sections
# -g 生成调试信息，供 make gdb 定位源码行。
CFLAGS	+= -g
CTYPE	:= c S

LD      := $(GCCPREFIX)ld
# -nostdlib 不链标准库与启动文件；--gc-sections 丢弃未被引用的节
#   （★ 这也是 sbi_console_getchar 未实现却能链接成功的原因）。
LDFLAGS	:= -m elf64lriscv
LDFLAGS	+= -nostdlib --gc-sections

OBJCOPY := $(GCCPREFIX)objcopy
OBJDUMP := $(GCCPREFIX)objdump

COPY	:= cp
MKDIR   := mkdir -p
MV		:= mv
RM		:= rm -f
AWK		:= awk
SED		:= sed
SH		:= sh
TR		:= tr
TOUCH	:= touch -c

OBJDIR	:= obj
BINDIR	:= bin

ALLOBJS	:=
ALLDEPS	:=
TARGETS	:=

include tools/function.mk

listf_cc = $(call listf,$(1),$(CTYPE))

# for cc
add_files_cc = $(call add_files,$(1),$(CC),$(CFLAGS) $(3),$(2),$(4))
create_target_cc = $(call create_target,$(1),$(2),$(3),$(CC),$(CFLAGS))

# for hostcc
add_files_host = $(call add_files,$(1),$(HOSTCC),$(HOSTCFLAGS),$(2),$(3))
create_target_host = $(call create_target,$(1),$(2),$(3),$(HOSTCC),$(HOSTCFLAGS))

cgtype = $(patsubst %.$(2),%.$(3),$(1))
objfile = $(call toobj,$(1))
asmfile = $(call cgtype,$(call toobj,$(1)),o,asm)
outfile = $(call cgtype,$(call toobj,$(1)),o,out)
symfile = $(call cgtype,$(call toobj,$(1)),o,sym)

# for match pattern
match = $(shell echo $(2) | $(AWK) '{for(i=1;i<=NF;i++){if(match("$(1)","^"$$(i)"$$")){exit 1;}}}'; echo $$?)

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# include kernel/user

# -Ilibs 加入头文件搜索路径。
INCLUDE	+= libs 

CFLAGS	+= $(addprefix -I,$(INCLUDE))

LIBDIR	+= libs

$(call add_files_cc,$(call listf_cc,$(LIBDIR)),libs,)

# -------------------------------------------------------------------
# kernel

# ★ 含 kern/mm/，entry.S 才可以直接 #include <mmu.h> 与 <memlayout.h>。
KINCLUDE	+= kern/debug/ \
			   kern/driver/ \
			   kern/trap/ \
			   kern/libs/\
			   kern/mm/ \
			   kern/arch/

KSRCDIR		+= kern/init \
			   kern/debug \
			   kern/libs \
			   kern/driver \
			   kern/trap \
			   kern/mm

KCFLAGS		+= $(addprefix -I,$(KINCLUDE))

# ★ 链接顺序由这里的文件顺序决定：entry.o 排在最前，这是入口落在 0x80200000 的直接原因。
$(call add_files_cc,$(call listf_cc,$(KSRCDIR)),kernel,$(KCFLAGS))

KOBJS	= $(call read_packet,kernel libs)

# create kernel target
kernel = $(call totarget,kernel)

$(kernel): tools/kernel.ld

# 链接出 bin/kernel，并顺带生成 obj/kernel.asm（反汇编）与 obj/kernel.sym（符号表）。
$(kernel): $(KOBJS)
	@echo + ld $@
	$(V)$(LD) $(LDFLAGS) -T tools/kernel.ld -o $@ $(KOBJS)
	@$(OBJDUMP) -S $@ > $(call asmfile,kernel)
	@$(OBJDUMP) -t $@ | $(SED) '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $(call symfile,kernel)

$(call create_target,kernel)

# -------------------------------------------------------------------
# create ucore.img
UCOREIMG	:= $(call totarget,ucore.img)


# objcopy：去掉符号与节头，导出纯二进制 → QEMU 可直接加载（体积 = text+rodata+填充+data+sdata）。
$(UCOREIMG): $(kernel)
	$(OBJCOPY) $(kernel) --strip-all -O binary $@

$(call create_target,ucore.img)

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

$(call finish_all)

IGNORE_ALLDEPS	= clean \
				  dist-clean \
				  grade \
				  touch \
				  print-.+ \
				  handin

ifeq ($(call match,$(MAKECMDGOALS),$(IGNORE_ALLDEPS)),0)
-include $(ALLDEPS)
endif

# files for grade script

TARGETS: $(TARGETS)

.DEFAULT_GOAL := TARGETS

# QEMU 参数：-machine virt（虚拟平台）、-nographic（串口接终端）、-bios default（内置 OpenSBI，必需）。
.PHONY: qemu 
qemu: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
# 教程里的 -device loader,file=...,addr=0x80200000 只写内存、不设置 fw_dynamic_info.next_addr，
#   会出现 “Domain0 Next Address : 0x0” 然后卡住；用 -kernel 才会设置该字段。
#	$(V)$(QEMU) -kernel $(UCOREIMG) -nographic
	$(V)$(QEMU) \
		-machine virt \
		-nographic \
		-bios default \
		-kernel $(UCOREIMG)

# 加 -s -S：QEMU 在 1234 端口监听并先暂停，等 make gdb 连上再运行。
debug: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
	$(V)$(QEMU) \
		-machine virt \
		-nographic \
		-bios default \
		-kernel $(UCOREIMG) \
		-s -S

# gdb-multiarch 连 1234：先载符号，再设体系结构 riscv:rv64，最后连目标。
gdb:
	gdb-multiarch \
    -ex 'file bin/kernel' \
    -ex 'set arch riscv:rv64' \
    -ex 'target remote localhost:1234'

	
.PHONY: grade touch

GRADE_GDB_IN	:= .gdb.in
GRADE_QEMU_OUT	:= .qemu.out
HANDIN			:= proj$(PROJ)-handin.tar.gz

# 注意：TOUCH_FILES 指向 kern/trap/trap.c，而本阶段该目录为空；
#   下一行用的是 touch -c，文件不存在时不报错也不创建。
TOUCH_FILES		:= kern/trap/trap.c

MAKEOPTS		:= --quiet --no-print-directory

grade:
	$(V)$(MAKE) $(MAKEOPTS) clean
	$(V)$(SH) tools/grade.sh

touch:
	$(V)$(foreach f,$(TOUCH_FILES),$(TOUCH) $(f))

print-%:
	@echo $($(shell echo $(patsubst print-%,%,$@) | $(TR) [a-z] [A-Z]))

# clean 删除本次构建的全部产物（cscope/tags/obj/bin 等）；grade/handin 目标本组不使用。
.PHONY: clean dist-clean handin packall tags
clean:
	$(V)$(RM) $(GRADE_GDB_IN) $(GRADE_QEMU_OUT) cscope* tags
	-$(RM) -r $(OBJDIR) $(BINDIR)

dist-clean: clean
	-$(RM) $(HANDIN)

handin: packall
	@echo Please visit http://learn.tsinghua.edu.cn and upload $(HANDIN). Thanks!

packall: clean
	@$(RM) -f $(HANDIN)
	@tar -czf $(HANDIN) `find . -type f -o -type d | grep -v '^\.*$$' | grep -vF '$(HANDIN)'`

tags:
	@echo TAGS ALL
	$(V)rm -f cscope.files cscope.in.out cscope.out cscope.po.out tags
	$(V)find . -type f -name "*.[chS]" >cscope.files
	$(V)cscope -bq 
	$(V)ctags -L cscope.files
