//LAB5 功能模块一 2410665
#ifndef __LIBS_UNISTD_H__
#define __LIBS_UNISTD_H__

/* System call numbers shared by the user library and the kernel. */
#define SYS_exit            1
#define SYS_fork            2
#define SYS_wait            3
#define SYS_exec            4
#define SYS_clone           5
#define SYS_yield           10
#define SYS_sleep           11
#define SYS_kill            12
#define SYS_gettime         17
#define SYS_getpid          18
#define SYS_brk             19
#define SYS_mmap            20
#define SYS_munmap          21
#define SYS_shmem           22
#define SYS_putc            30
#define SYS_pgdir           31

#define NR_SYSCALLS         32

#ifndef __ASSEMBLER__

/* fork flags, kept here as well so user code can name them. */
#define CLONE_VM            0x00000100
#define CLONE_THREAD        0x00000200

#endif /* !__ASSEMBLER__ */

#endif /* !__LIBS_UNISTD_H__ */
