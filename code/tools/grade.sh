#!/bin/sh
#
# Lab5 grading driver.  Every user program is a separate kernel build
# selected through TEST=<name>; the same user_main then loads that image.
# A case passes only when its own "pass" marker and the init reap marker
# both appear.  The fault cases are the inverse: the process must be killed
# and must not reach its "failed" line.

MAKE=make
QEMU=${QEMU:-qemu-system-riscv64}
TIMEOUT=${TIMEOUT:-25}

pass=0
total=0
failed=

build() {
    $MAKE clean >/dev/null 2>&1
    $MAKE TEST=$1 >/dev/null 2>&1
}

run_qemu() {
    timeout $TIMEOUT $QEMU -machine virt -bios default \
        -kernel bin/ucore.img -display none -monitor none -no-reboot \
        -serial file:$1.log >/dev/null 2>&1
    test -s $1.log
}

run_case() {
    name=$1
    expect=$2
    total=`expr $total + 1`
    printf '%-18s ' "$name:"

    if ! build $name; then
        echo "BUILD FAIL"
        failed="$failed $name"
        return
    fi
    if ! run_qemu $name; then
        echo "NO OUTPUT"
        failed="$failed $name"
        return
    fi
    if grep -q "$expect" $name.log && grep -q "all user-mode processes have quit." $name.log; then
        echo PASS
        pass=`expr $pass + 1`
    else
        echo FAIL
        failed="$failed $name"
    fi
}

run_fault() {
    name=$1
    stale=$2
    total=`expr $total + 1`
    printf '%-18s ' "$name:"

    if ! build $name; then
        echo "BUILD FAIL"
        failed="$failed $name"
        return
    fi
    if ! run_qemu $name; then
        echo "NO OUTPUT"
        failed="$failed $name"
        return
    fi
    if grep -q "bad memory access" $name.log &&
       ! grep -q "$stale" $name.log &&
       grep -q "all user-mode processes have quit." $name.log; then
        echo PASS
        pass=`expr $pass + 1`
    else
        echo FAIL
        failed="$failed $name"
    fi
}

run_case hello          "hello world."
run_case exit           "exit pass."
run_case forktest       "forktest pass."
run_case yield          "yield pass."
run_case badarg         "badarg pass."
run_case pgdir          "pgdir pass."
run_case testbss        "testbss pass."
run_case waitkill       "waitkill pass."
run_case spin           "spin pass."
run_case forktree       "forktree pass."

run_fault faultread        "faultread failed"
run_fault faultreadkernel  "faultreadkernel failed"
run_fault badsegment       "badsegment failed"

echo
echo "Total Score: $pass/$total"
if test -n "$failed"; then
    echo "Failed:$failed"
    exit 1
fi
