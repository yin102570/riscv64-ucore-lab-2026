#!/usr/bin/env python3
"""临时副本中注入 T1-T4 边界测试并运行。不触碰实际代码。"""
import os, re, shutil, subprocess

CODE = '/home/sqs/ucore-lab/lab4/code'
ROOT = '/tmp/lab4_boundary'
TEST_SRC = '/mnt/c/Users/SQS/Desktop/os/test_boundary.c'

# 1. 复制代码树
if os.path.exists(ROOT):
    shutil.rmtree(ROOT)
shutil.copytree(CODE, ROOT, ignore=shutil.ignore_patterns('.git', 'bin', 'obj'))

# 2. 放测试文件到 kern/test
os.makedirs(ROOT + '/kern/test', exist_ok=True)
shutil.copy(TEST_SRC, ROOT + '/kern/test/test_boundary.c')

# 3. Makefile 加 kern/test
mk_path = ROOT + '/Makefile'
mk = open(mk_path).read()
for var in ('KINCLUDE', 'KSRCDIR'):
    m = re.search(r'(?m)^' + var + r'[ \t]*\+=.*(?:\n[ \t]+[^\n]*)*', mk)
    assert m, var
    mk = mk[:m.end()] + '\n' + var + '\t+= kern/test' + mk[m.end():]
open(mk_path, 'w').write(mk)

# 4. pmm.c 注入声明 + 调用
pmm_path = ROOT + '/kern/mm/pmm.c'
pmm = open(pmm_path).read()

# 声明
assert 'void test_lab4_boundary(void);' not in pmm
pmm = pmm.replace('void pmm_init(void)',
                  'void test_lab4_boundary(void);\n\nvoid pmm_init(void)', 1)

# 调用（pmm_init 末尾，kmalloc_init 之后）
old = '    kmalloc_init();\n}'
assert pmm.count(old) == 1, 'kmalloc_init anchor'
pmm = pmm.replace(old, '    kmalloc_init();\n    test_lab4_boundary();\n}', 1)

open(pmm_path, 'w').write(pmm)

print('injection done')

# 5. 构建
r = subprocess.run(['make'], cwd=ROOT, capture_output=True, text=True)
print(r.stdout[-2000:])
if r.returncode != 0:
    print('BUILD FAILED')
    print(r.stderr[-2000:])
    raise SystemExit(1)

# 6. 运行
r = subprocess.run(['timeout', '15', 'qemu-system-riscv64', '-machine', 'virt',
                    '-nographic', '-bios', 'default', '-kernel', 'bin/ucore.img'],
                   cwd=ROOT, capture_output=True, text=True)
print('=== QEMU OUTPUT ===')
print(r.stdout)
print('=== STDERR (tail) ===')
print(r.stderr[-500:])
