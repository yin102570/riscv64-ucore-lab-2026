#ifndef __KERN_INIT_LAB3_SWITCH_H__
#define __KERN_INIT_LAB3_SWITCH_H__

#include <defs.h>

struct trapframe;

#ifdef LAB3_CHALLENGE_SWITCH

/* Challenge 1：S -> U -> S 往返演示的对外接口。 */
void lab3_switch_test(void) __attribute__((noreturn));
void lab3_switch_back(struct trapframe *tf);
extern int lab3_switch_active;

#endif /* LAB3_CHALLENGE_SWITCH */

#endif /* !__KERN_INIT_LAB3_SWITCH_H__ */
