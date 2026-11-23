PROJ	:= lab5
EMPTY	:=
SPACE	:= $(EMPTY) $(EMPTY)
SLASH	:= /

V       := @

# Lab5 selects the user program at build time.  Keeping the choice here
# avoids rebuilding the kernel image with a hand-edited macro.
ifdef TEST
EXTRA_DEFS := -DTEST=$(TEST) \
              -DTESTSTART=_binary_obj___user_$(TEST)_out_start \
              -DTESTSIZE=_binary_obj___user_$(TEST)_out_size
endif

ifndef GCCPREFIX
GCCPREFIX := riscv64-unknown-elf-
endif

ifndef QEMU
QEMU := qemu-system-riscv64
endif

ifndef SPIKE
SPIKE := spike
endif

# eliminate default suffix rules
.SUFFIXES: .c .S .h

# delete target files if there is an error (or make is interrupted)
.DELETE_ON_ERROR:

# define compiler and flags
HOSTCC		:= gcc
HOSTCFLAGS	:= -Wall -O2

GDB := gdb-multiarch

CC		:= $(GCCPREFIX)gcc
CFLAGS  := -mcmodel=medany -O2 -std=gnu99 -Wno-unused -Wno-error=incompatible-pointer-types
CFLAGS	+= -fno-builtin -Wall -nostdinc $(DEFS) $(EXTRA_DEFS)
CFLAGS	+= -fno-stack-protector -ffunction-sections -fdata-sections
CFLAGS	+= -g
CTYPE	:= c S

LD      := $(GCCPREFIX)ld
LDFLAGS	:= -m elf64lriscv
LDFLAGS	+= -nostdlib --gc-sections --print-gc-sections

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

INCLUDE	+= libs/

CFLAGS	+= $(addprefix -I,$(INCLUDE))

LIBDIR	+= libs

$(call add_files_cc,$(call listf_cc,$(LIBDIR)),libs,)

# -------------------------------------------------------------------
# kernel

KINCLUDE	+= kern/debug/ \
			   kern/driver/ \
			   kern/trap/ \
			   kern/mm/ \
			   kern/sync/ \
			   kern/fs/ \
			   kern/syscall/ \
			   kern/process \
			   kern/schedule

KSRCDIR		+= kern/init \
			   kern/libs \
			   kern/debug \
			   kern/driver \
			   kern/trap \
			   kern/mm \
			   kern/fs \
			   kern/syscall \
			   kern/process \
			   kern/schedule

KCFLAGS		+= $(addprefix -I,$(KINCLUDE))

$(call add_files_cc,$(call listf_cc,$(KSRCDIR)),kernel,$(KCFLAGS))

KOBJS	= $(call read_packet,kernel libs)

# -------------------------------------------------------------------
# user programs

USER_CFLAGS	:= -mcmodel=medany -O2 -std=gnu99 -Wno-unused -fno-builtin \
			   -Wall -nostdinc -fno-stack-protector -g \
			   -Iuser/libs -Ilibs
USER_LDFLAGS	:= -m elf64lriscv -nostdlib

USER_SRCS	:= $(wildcard user/*.c)
USER_BINS	:= $(patsubst user/%.c,obj/user/%.out,$(USER_SRCS))
ULIB_OBJS	:= $(patsubst user/libs/%.c,obj/user/libs/%.o,$(wildcard user/libs/*.c)) \
			   $(patsubst user/libs/%.S,obj/user/libs/%.o,$(wildcard user/libs/*.S))
USER_EMBEDS	:= $(patsubst obj/user/%.out,obj/__user_%.out.o,$(USER_BINS))

obj/user/libs/%.o: user/libs/%.c
	@mkdir -p $(dir $@)
	@echo + cc $<
	$(V)$(CC) $(USER_CFLAGS) -c $< -o $@

obj/user/libs/%.o: user/libs/%.S
	@mkdir -p $(dir $@)
	@echo + as $<
	$(V)$(CC) $(USER_CFLAGS) -c $< -o $@

obj/user/%.o: user/%.c
	@mkdir -p $(dir $@)
	@echo + cc $<
	$(V)$(CC) $(USER_CFLAGS) -c $< -o $@

obj/user/%.out: obj/user/%.o $(ULIB_OBJS) obj/printfmt.o obj/string.o tools/user.ld
	@mkdir -p $(dir $@)
	@echo + ld $@
	$(V)$(LD) $(USER_LDFLAGS) -T tools/user.ld -o $@ $< $(ULIB_OBJS) obj/printfmt.o obj/string.o

obj/__user_%.out: obj/user/%.out
	$(V)$(COPY) $< $@

obj/__user_%.out.o: obj/__user_%.out
	@echo + objcopy $<
	$(V)$(OBJCOPY) -I binary -O elf64-littleriscv -B riscv $< $@

KOBJS	+= $(USER_EMBEDS)
TARGETS	+= $(USER_BINS)

# create kernel target
kernel = $(call totarget,kernel)

$(kernel): tools/kernel.ld

$(kernel): $(KOBJS)
	@echo + ld $@
	$(V)$(LD) $(LDFLAGS) -T tools/kernel.ld -o $@ $(KOBJS)
	@$(OBJDUMP) -S $@ > $(call asmfile,kernel)
	@$(OBJDUMP) -t $@ | $(SED) '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $(call symfile,kernel)

$(call create_target,kernel)

# -------------------------------------------------------------------
# create ucore.img
UCOREIMG	:= $(call totarget,ucore.img)

# $(UCOREIMG): $(kernel)
#	cd ../../riscv-pk && rm -rf build && mkdir build && cd build && ../configure --prefix=$(RISCV) --host=riscv64-unknown-elf --with-payload=../../labcodes/$(PROJ)/$(kernel)  --disable-fp-emulation && make && cp bbl ../../labcodes/$(PROJ)/$(UCOREIMG)

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

.PHONY: qemu spike
qemu: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
#	$(V)$(QEMU) -kernel $(UCOREIMG) -nographic
	$(V)$(QEMU) \
		-machine virt \
		-nographic \
		-bios default \
		-kernel $(UCOREIMG)

debug: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
	$(V)$(QEMU) \
		-machine virt \
		-nographic \
		-bios default \
		-kernel $(UCOREIMG) \
		-s -S

gdb:
	$(GDB) \
    -ex 'file bin/kernel' \
    -ex 'set arch riscv:rv64' \
    -ex 'target remote localhost:1234'

spike: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
	$(V)$(SPIKE) $(UCOREIMG)

.PHONY: grade touch

GRADE_GDB_IN	:= .gdb.in
GRADE_QEMU_OUT	:= .qemu.out
HANDIN			:= proj$(PROJ)-handin.tar.gz

TOUCH_FILES		:= kern/trap/trap.c

MAKEOPTS		:= --quiet --no-print-directory

GRADE_TMP		:= /tmp/lab5_grade

grade:
	$(V)$(MAKE) $(MAKEOPTS) clean
	$(V)$(RM) -rf $(GRADE_TMP)
	$(V)$(MKDIR) $(GRADE_TMP)
	$(V)tar -C . --exclude=.git --exclude=.vscode --exclude=vcs -cf - . | tar -C $(GRADE_TMP) -xf -
	$(V)cd $(GRADE_TMP) && $(SH) tools/grade.sh
	$(V)$(RM) -rf $(GRADE_TMP)

touch:
	$(V)$(foreach f,$(TOUCH_FILES),$(TOUCH) $(f))

print-%:
	@echo $($(shell echo $(patsubst print-%,%,$@) | $(TR) [a-z] [A-Z]))

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
