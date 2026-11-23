//LAB5 功能模块一 2410665
#ifndef __KERN_SYSCALL_SYSCALL_H__
#define __KERN_SYSCALL_SYSCALL_H__

/* Dispatch the system call described by current->tf and put the result
 * back into the a0 slot of the same trapframe. */
void syscall(void);

#endif /* !__KERN_SYSCALL_SYSCALL_H__ */
