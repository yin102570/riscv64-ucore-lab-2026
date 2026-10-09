/* defs.h —— -nostdinc 下的基础类型与工具宏，替代 stdint.h / stdbool.h / stddef.h。 */
#ifndef __LIBS_DEFS_H__
#define __LIBS_DEFS_H__

/* NULL 空指针常量。 */
#ifndef NULL
#define NULL ((void *)0)
#endif

/* 三个 GCC 属性：always_inline / noinline / noreturn（noreturn 供 kern_init 使用）。 */
#define __always_inline inline __attribute__((always_inline))
#define __noinline __attribute__((noinline))
#define __noreturn __attribute__((noreturn))

/* bool 用 int 表示：0 假、非 0 真（不是 C99 的 _Bool，赋值不会归一化）。 */
/* Represents true-or-false values */
typedef int bool;

/* 精确宽度整数。RV64 上 long 已是 64 位，64 位仍写作 long long。 */
/* Explicitly-sized versions of integer types */
typedef char int8_t;
typedef unsigned char uint8_t;
typedef short int16_t;
typedef unsigned short uint16_t;
typedef int int32_t;
typedef unsigned int uint32_t;
typedef long long int64_t;
typedef unsigned long long uint64_t;

/* fast 类型：至少 N 位且本机访问最快，RV64 下 32/64 位都用 long。 */
/* Add fast types */
typedef signed char int_fast8_t;
typedef short int_fast16_t;
typedef long int_fast32_t;
typedef long long int_fast64_t;

typedef unsigned char uint_fast8_t;
typedef unsigned short uint_fast16_t;
typedef unsigned long uint_fast32_t;
typedef unsigned long long uint_fast64_t;

/* 最小值。写 (-0x7f-1) 而不是 -0x80，是为了避开字面量取负的溢出问题。 */
#define INT8_MIN    (-0x7f - 1)
#define INT16_MIN   (-0x7fff - 1)
#define INT32_MIN   (-0x7fffffff - 1)
#define INT64_MIN   (-0x7fffffffffffffff - 1)

/* 各类型最大值。 */
#define INT8_MAX    (0x7f)
#define INT16_MAX   (0x7fff)
#define INT32_MAX   (0x7fffffff)
#define INT64_MAX   (0x7fffffffffffffff)

/* 各无符号类型最大值。 */
#define UINT8_MAX   (0xff)
#define UINT16_MAX  (0xffff)
#define UINT32_MAX  (0xffffffff)
#define UINT64_MAX  (0xffffffffffffffff)

/* ⚠ 下面原注释说“指针是 32 位”是 x86-32 时代的遗留：RV64 上 intptr_t 其实是 64 位。 */
/* *
 * Pointers and addresses are 32 bits long.
 * We use pointer types to represent addresses,
 * uintptr_t to represent the numerical values of addresses.
 * */
/* intptr_t/uintptr_t：能装下一个指针的整数（RV64 = 64 位）。 */
typedef int64_t intptr_t;
typedef uint64_t uintptr_t;

/* size_t 表示长度；ppn_t 表示物理页号。 */
/* size_t is used for memory object sizes */
typedef uintptr_t size_t;

/* used for page numbers */
typedef size_t ppn_t;

/* *
 * Rounding operations (efficient when n is a power of 2)
 * Round down to the nearest multiple of n
 * */
/* ROUNDDOWN：用 GCC 语句表达式 ({...}) 与 typeof 扩展实现，n 为 2 的幂时最高效。 */
#define ROUNDDOWN(a, n) ({                                          \
            size_t __a = (size_t)(a);                               \
            (typeof(a))(__a - __a % (n));                           \
        })

/* ROUNDUP：先加 n-1 再向下取整。 */
/* Round up to the nearest multiple of n */
#define ROUNDUP(a, n) ({                                            \
            size_t __n = (size_t)(n);                               \
            (typeof(a))(ROUNDDOWN((size_t)(a) + __n - 1, __n));     \
        })

/* offsetof：把地址 0 当基址取成员地址，其数值即偏移量（缺 stddef.h 故自备）。 */
/* Return the offset of 'member' relative to the beginning of a struct type */
#define offsetof(type, member)                                      \
    ((size_t)(&((type *)0)->member))

/* to_struct（即 container_of）：由成员地址减去偏移量，反推宿主结构体地址。 */
/* *
 * to_struct - get the struct from a ptr
 * @ptr:    a struct pointer of member
 * @type:   the type of the struct this is embedded in
 * @member: the name of the member within the struct
 * */
#define to_struct(ptr, type, member)                               \
    ((type *)((char *)(ptr) - offsetof(type, member)))

#endif /* !__LIBS_DEFS_H__ */

