#!/usr/bin/env python3
"""临时副本中注入 T8 失败清理测试 + 故障注入，运行。不触碰实际代码。"""
import os, re, shutil, subprocess

CODE = '/home/sqs/ucore-lab/lab4/code'
ROOT = '/tmp/lab4_boundary_t8'
TEST_SRC = '/mnt/c/Users/SQS/Desktop/os/test_boundary_t8.c'

if os.path.exists(ROOT):
    shutil.rmtree(ROOT)
shutil.copytree(CODE, ROOT, ignore=shutil.ignore_patterns('.git', 'bin', 'obj'))

os.makedirs(ROOT + '/kern/test', exist_ok=True)
shutil.copy(TEST_SRC, ROOT + '/kern/test/test_boundary_t8.c')

# Makefile 加 kern/test
mk_path = ROOT + '/Makefile'
mk = open(mk_path).read()
for var in ('KINCLUDE', 'KSRCDIR'):
    m = re.search(r'(?m)^' + var + r'[ \t]*\+=.*(?:\n[ \t]+[^\n]*)*', mk)
    assert m, var
    mk = mk[:m.end()] + '\n' + var + '\t+= kern/test' + mk[m.end():]
open(mk_path, 'w').write(mk)

# proc.c 加故障注入开关 + 进程计数 getter
proc_path = ROOT + '/kern/process/proc.c'
p = open(proc_path).read()

old = 'static int nr_process = 0;\n'
assert p.count(old) == 1, 'nr_process anchor'
p = p.replace(old, old +
    'int force_alloc_proc_fail = 0;\n'
    'int force_setup_kstack_fail = 0;\n'
    'int get_nr_process(void) { return nr_process; }\n', 1)

old = '    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));'
assert p.count(old) == 1, 'alloc_proc anchor'
p = p.replace(old, '    if (force_alloc_proc_fail) return NULL;\n' + old, 1)

old = '    struct Page *page = alloc_pages(KSTACKPAGE);'
assert p.count(old) == 1, 'setup_kstack anchor'
p = p.replace(old, '    if (force_setup_kstack_fail) return -E_NO_MEM;\n' + old, 1)

open(proc_path, 'w').write(p)

# init.c 里 proc_init 之后调用 T8
init_path = ROOT + '/kern/init/init.c'
s = open(init_path).read()
old = '    proc_init(); // init process table'
assert s.count(old) == 1, 'proc_init call anchor'
s = s.replace(old, old + '\n    test_t8_failure_cleanup();', 1)
s = s.replace('void grade_backtrace(void);',
              'void grade_backtrace(void);\nvoid test_t8_failure_cleanup(void);', 1)
open(init_path, 'w').write(s)

print('T8 injection done')

r = subprocess.run(['make'], cwd=ROOT, capture_output=True, text=True)
if r.returncode != 0:
    print('BUILD FAILED')
    print(r.stderr[-2000:])
    raise SystemExit(1)

r = subprocess.run(['timeout', '15', 'qemu-system-riscv64', '-machine', 'virt',
                    '-nographic', '-bios', 'default', '-kernel', 'bin/ucore.img'],
                   cwd=ROOT, capture_output=True, text=True)
print('=== QEMU OUTPUT ===')
print(r.stdout)
