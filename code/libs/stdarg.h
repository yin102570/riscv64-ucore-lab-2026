/* -nostdinc 下自备的变参支持：直接复用 GCC 内建的 __builtin_va_* 机制。 */
#ifndef __LIBS_STDARG_H__
#define __LIBS_STDARG_H__

/* compiler provides size of save area */
/* va_list 就是编译器内建类型，无需自己计算栈帧布局。 */
typedef __builtin_va_list va_list;

/* va_start/va_arg 映射到内建函数；va_end 无需释放资源，故展开为空。 */
#define va_start(ap, last)              (__builtin_va_start(ap, last))
#define va_arg(ap, type)                (__builtin_va_arg(ap, type))
#define va_end(ap)                      /*nothing*/

#endif /* !__LIBS_STDARG_H__ */

