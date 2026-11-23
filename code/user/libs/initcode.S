# LAB5 功能模块二 2410665
.text
.globl _start
_start:
    /* main's return value becomes exit's argument. */
    call main
    call exit
1:
    j 1b
