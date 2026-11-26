set pagination off
set confirm off
file bin/kernel
target remote :1234
add-symbol-file obj/user/exit.out
break *0xffffffffc0203dd4
continue
printf "== enter kernel syscall ==\n"
printf "nr=%ld a1=0x%lx a2=0x%lx epc=0x%lx\n", current->tf->gpr.a0, current->tf->gpr.a1, current->tf->gpr.a2, current->tf->epc
info registers sepc sstatus sscratch sp
finish
printf "== after syscall returns ==\n"
printf "ret_in_a0=%ld epc_after=0x%lx\n", current->tf->gpr.a0, current->tf->epc
break *0xffffffffc0200e0a
continue
printf "== immediately before sret ==\n"
info registers sepc sstatus sscratch sp
printf "user_return_value_a0=%ld\n", $a0
detach
quit
