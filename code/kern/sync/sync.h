#ifndef __KERN_SYNC_SYNC_H__
#define __KERN_SYNC_SYNC_H__

#include <defs.h>
#include <intr.h>
#include <riscv.h>
#include <atomic.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);

/*
 * A minimal spin lock built on the atomic bit helpers in libs/atomic.h.
 *
 * ucore runs on a single hart, so contention can only come from a context
 * switch inside a critical section. The scheduler is only entered when a
 * trap returns, so a plain spin wait is enough here; mm_lock is taken on
 * the slow path of fork and never from interrupt context.
 */
/* The atomic helpers operate on a machine word, so the lock must be a
 * machine word too; a bool here would let amo*.d touch four bytes past
 * the end of the field. */
typedef volatile uint_t lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
}

static inline bool
try_lock(lock_t *lock)
{
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
    {
        barrier();
    }
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
    {
        panic("unlock of an unlocked mutex");
    }
}

#endif /* !__KERN_SYNC_SYNC_H__ */
