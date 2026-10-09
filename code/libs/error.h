/* 内核错误码：出错时返回负值（如 -E_INVAL），0 表示成功。 */
/* ⚠ 必须与 libs/printfmt.c 的 error_string[] 同步：%e 是用这些编号查表的。 */
#ifndef __LIBS_ERROR_H__
#define __LIBS_ERROR_H__

/* kernel error codes -- keep in sync with list in lib/printfmt.c */
/* 1~6 依次是：未指明 / 进程异常 / 参数非法 / 内存不足 / 进程数超限 / 访存错误。 */
#define E_UNSPECIFIED        1    // Unspecified or unknown problem
#define E_BAD_PROC            2    // Process doesn't exist or otherwise
#define E_INVAL                3    // Invalid parameter
#define E_NO_MEM            4    // Request failed due to memory shortage
#define E_NO_FREE_PROC        5    // Attempt to create a new process beyond
#define E_FAULT                6    // Memory fault

/* the maximum allowed */
/* 必须等于上面最大的错误码：printfmt.c 用 MAXERROR+1 定数组长度并做越界检查。 */
#define MAXERROR            6

#endif /* !__LIBS_ERROR_H__ */

