/* string.h —— 自备的极简 libc（-nostdinc/-nostdlib 下不能用系统头文件）。 */
#ifndef __LIBS_STRING_H__
#define __LIBS_STRING_H__

#include <defs.h>

/* 长度：strlen / strnlen（后者限长，printfmt 的 %s 靠它防越界）。 */
size_t strlen(const char *s);
size_t strnlen(const char *s, size_t len);

/* 复制：strcpy / strncpy（后者不足部分用 '\0' 补满）。 */
char *strcpy(char *dst, const char *src);
char *strncpy(char *dst, const char *src, size_t len);

/* 比较：strcmp / strncmp，内部按 unsigned char 比较。 */
int strcmp(const char *s1, const char *s2);
int strncmp(const char *s1, const char *s2, size_t n);

/* 查找与转换：strchr 找不到返回 NULL，strfind 则返回指向结尾 '\0' 的指针。 */
char *strchr(const char *s, char c);
char *strfind(const char *s, char c);
long strtol(const char *s, char **endptr, int base);

/* 内存操作。注意本工程 memset 的填充值参数写作 char（标准库是 int）。 */
void *memset(void *s, char c, size_t n);
void *memmove(void *dst, const void *src, size_t n);
void *memcpy(void *dst, const void *src, size_t n);
int memcmp(const void *v1, const void *v2, size_t n);

#endif /* !__LIBS_STRING_H__ */

