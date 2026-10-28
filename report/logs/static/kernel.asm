
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
ffffffffc0200034:	18029073          	csrw	satp,t0
ffffffffc0200038:	12000073          	sfence.vma
ffffffffc020003c:	c0205137          	lui	sp,0xc0205
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
ffffffffc020004a:	00006517          	auipc	a0,0x6
ffffffffc020004e:	fde50513          	addi	a0,a0,-34 # ffffffffc0206028 <free_area>
ffffffffc0200052:	00006617          	auipc	a2,0x6
ffffffffc0200056:	44660613          	addi	a2,a2,1094 # ffffffffc0206498 <end>
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
ffffffffc0200060:	e406                	sd	ra,8(sp)
ffffffffc0200062:	67d010ef          	jal	ffffffffc0201ede <memset>
ffffffffc0200066:	3c2000ef          	jal	ffffffffc0200428 <dtb_init>
ffffffffc020006a:	3b0000ef          	jal	ffffffffc020041a <cons_init>
ffffffffc020006e:	00002517          	auipc	a0,0x2
ffffffffc0200072:	e8250513          	addi	a0,a0,-382 # ffffffffc0201ef0 <etext>
ffffffffc0200076:	08c000ef          	jal	ffffffffc0200102 <cputs>
ffffffffc020007a:	0e4000ef          	jal	ffffffffc020015e <print_kerninfo>
ffffffffc020007e:	702000ef          	jal	ffffffffc0200780 <idt_init>
ffffffffc0200082:	65e010ef          	jal	ffffffffc02016e0 <pmm_init>
ffffffffc0200086:	6fa000ef          	jal	ffffffffc0200780 <idt_init>
ffffffffc020008a:	34e000ef          	jal	ffffffffc02003d8 <clock_init>
ffffffffc020008e:	6e6000ef          	jal	ffffffffc0200774 <intr_enable>
ffffffffc0200092:	a001                	j	ffffffffc0200092 <kern_init+0x48>

ffffffffc0200094 <cputch>:
ffffffffc0200094:	1101                	addi	sp,sp,-32
ffffffffc0200096:	ec06                	sd	ra,24(sp)
ffffffffc0200098:	e42e                	sd	a1,8(sp)
ffffffffc020009a:	382000ef          	jal	ffffffffc020041c <cons_putc>
ffffffffc020009e:	65a2                	ld	a1,8(sp)
ffffffffc02000a0:	60e2                	ld	ra,24(sp)
ffffffffc02000a2:	419c                	lw	a5,0(a1)
ffffffffc02000a4:	2785                	addiw	a5,a5,1
ffffffffc02000a6:	c19c                	sw	a5,0(a1)
ffffffffc02000a8:	6105                	addi	sp,sp,32
ffffffffc02000aa:	8082                	ret

ffffffffc02000ac <vcprintf>:
ffffffffc02000ac:	1101                	addi	sp,sp,-32
ffffffffc02000ae:	862a                	mv	a2,a0
ffffffffc02000b0:	86ae                	mv	a3,a1
ffffffffc02000b2:	00000517          	auipc	a0,0x0
ffffffffc02000b6:	fe250513          	addi	a0,a0,-30 # ffffffffc0200094 <cputch>
ffffffffc02000ba:	006c                	addi	a1,sp,12
ffffffffc02000bc:	ec06                	sd	ra,24(sp)
ffffffffc02000be:	c602                	sw	zero,12(sp)
ffffffffc02000c0:	103010ef          	jal	ffffffffc02019c2 <vprintfmt>
ffffffffc02000c4:	60e2                	ld	ra,24(sp)
ffffffffc02000c6:	4532                	lw	a0,12(sp)
ffffffffc02000c8:	6105                	addi	sp,sp,32
ffffffffc02000ca:	8082                	ret

ffffffffc02000cc <cprintf>:
ffffffffc02000cc:	711d                	addi	sp,sp,-96
ffffffffc02000ce:	02810313          	addi	t1,sp,40
ffffffffc02000d2:	f42e                	sd	a1,40(sp)
ffffffffc02000d4:	f832                	sd	a2,48(sp)
ffffffffc02000d6:	fc36                	sd	a3,56(sp)
ffffffffc02000d8:	862a                	mv	a2,a0
ffffffffc02000da:	004c                	addi	a1,sp,4
ffffffffc02000dc:	00000517          	auipc	a0,0x0
ffffffffc02000e0:	fb850513          	addi	a0,a0,-72 # ffffffffc0200094 <cputch>
ffffffffc02000e4:	869a                	mv	a3,t1
ffffffffc02000e6:	ec06                	sd	ra,24(sp)
ffffffffc02000e8:	e0ba                	sd	a4,64(sp)
ffffffffc02000ea:	e4be                	sd	a5,72(sp)
ffffffffc02000ec:	e8c2                	sd	a6,80(sp)
ffffffffc02000ee:	ecc6                	sd	a7,88(sp)
ffffffffc02000f0:	c202                	sw	zero,4(sp)
ffffffffc02000f2:	e41a                	sd	t1,8(sp)
ffffffffc02000f4:	0cf010ef          	jal	ffffffffc02019c2 <vprintfmt>
ffffffffc02000f8:	60e2                	ld	ra,24(sp)
ffffffffc02000fa:	4512                	lw	a0,4(sp)
ffffffffc02000fc:	6125                	addi	sp,sp,96
ffffffffc02000fe:	8082                	ret

ffffffffc0200100 <cputchar>:
ffffffffc0200100:	ae31                	j	ffffffffc020041c <cons_putc>

ffffffffc0200102 <cputs>:
ffffffffc0200102:	1101                	addi	sp,sp,-32
ffffffffc0200104:	e822                	sd	s0,16(sp)
ffffffffc0200106:	ec06                	sd	ra,24(sp)
ffffffffc0200108:	842a                	mv	s0,a0
ffffffffc020010a:	00054503          	lbu	a0,0(a0)
ffffffffc020010e:	c51d                	beqz	a0,ffffffffc020013c <cputs+0x3a>
ffffffffc0200110:	e426                	sd	s1,8(sp)
ffffffffc0200112:	0405                	addi	s0,s0,1
ffffffffc0200114:	4481                	li	s1,0
ffffffffc0200116:	306000ef          	jal	ffffffffc020041c <cons_putc>
ffffffffc020011a:	00044503          	lbu	a0,0(s0)
ffffffffc020011e:	0405                	addi	s0,s0,1
ffffffffc0200120:	87a6                	mv	a5,s1
ffffffffc0200122:	2485                	addiw	s1,s1,1
ffffffffc0200124:	f96d                	bnez	a0,ffffffffc0200116 <cputs+0x14>
ffffffffc0200126:	4529                	li	a0,10
ffffffffc0200128:	0027841b          	addiw	s0,a5,2
ffffffffc020012c:	64a2                	ld	s1,8(sp)
ffffffffc020012e:	2ee000ef          	jal	ffffffffc020041c <cons_putc>
ffffffffc0200132:	60e2                	ld	ra,24(sp)
ffffffffc0200134:	8522                	mv	a0,s0
ffffffffc0200136:	6442                	ld	s0,16(sp)
ffffffffc0200138:	6105                	addi	sp,sp,32
ffffffffc020013a:	8082                	ret
ffffffffc020013c:	4529                	li	a0,10
ffffffffc020013e:	2de000ef          	jal	ffffffffc020041c <cons_putc>
ffffffffc0200142:	4405                	li	s0,1
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	8522                	mv	a0,s0
ffffffffc0200148:	6442                	ld	s0,16(sp)
ffffffffc020014a:	6105                	addi	sp,sp,32
ffffffffc020014c:	8082                	ret

ffffffffc020014e <getchar>:
ffffffffc020014e:	1141                	addi	sp,sp,-16
ffffffffc0200150:	e406                	sd	ra,8(sp)
ffffffffc0200152:	2d2000ef          	jal	ffffffffc0200424 <cons_getc>
ffffffffc0200156:	dd75                	beqz	a0,ffffffffc0200152 <getchar+0x4>
ffffffffc0200158:	60a2                	ld	ra,8(sp)
ffffffffc020015a:	0141                	addi	sp,sp,16
ffffffffc020015c:	8082                	ret

ffffffffc020015e <print_kerninfo>:
ffffffffc020015e:	1141                	addi	sp,sp,-16
ffffffffc0200160:	00002517          	auipc	a0,0x2
ffffffffc0200164:	db050513          	addi	a0,a0,-592 # ffffffffc0201f10 <etext+0x20>
ffffffffc0200168:	e406                	sd	ra,8(sp)
ffffffffc020016a:	f63ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020016e:	00000597          	auipc	a1,0x0
ffffffffc0200172:	edc58593          	addi	a1,a1,-292 # ffffffffc020004a <kern_init>
ffffffffc0200176:	00002517          	auipc	a0,0x2
ffffffffc020017a:	dba50513          	addi	a0,a0,-582 # ffffffffc0201f30 <etext+0x40>
ffffffffc020017e:	f4fff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200182:	00002597          	auipc	a1,0x2
ffffffffc0200186:	d6e58593          	addi	a1,a1,-658 # ffffffffc0201ef0 <etext>
ffffffffc020018a:	00002517          	auipc	a0,0x2
ffffffffc020018e:	dc650513          	addi	a0,a0,-570 # ffffffffc0201f50 <etext+0x60>
ffffffffc0200192:	f3bff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200196:	00006597          	auipc	a1,0x6
ffffffffc020019a:	e9258593          	addi	a1,a1,-366 # ffffffffc0206028 <free_area>
ffffffffc020019e:	00002517          	auipc	a0,0x2
ffffffffc02001a2:	dd250513          	addi	a0,a0,-558 # ffffffffc0201f70 <etext+0x80>
ffffffffc02001a6:	f27ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02001aa:	00006597          	auipc	a1,0x6
ffffffffc02001ae:	2ee58593          	addi	a1,a1,750 # ffffffffc0206498 <end>
ffffffffc02001b2:	00002517          	auipc	a0,0x2
ffffffffc02001b6:	dde50513          	addi	a0,a0,-546 # ffffffffc0201f90 <etext+0xa0>
ffffffffc02001ba:	f13ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02001be:	00000717          	auipc	a4,0x0
ffffffffc02001c2:	e8c70713          	addi	a4,a4,-372 # ffffffffc020004a <kern_init>
ffffffffc02001c6:	00006797          	auipc	a5,0x6
ffffffffc02001ca:	6d178793          	addi	a5,a5,1745 # ffffffffc0206897 <end+0x3ff>
ffffffffc02001ce:	8f99                	sub	a5,a5,a4
ffffffffc02001d0:	43f7d593          	srai	a1,a5,0x3f
ffffffffc02001d4:	60a2                	ld	ra,8(sp)
ffffffffc02001d6:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001da:	95be                	add	a1,a1,a5
ffffffffc02001dc:	85a9                	srai	a1,a1,0xa
ffffffffc02001de:	00002517          	auipc	a0,0x2
ffffffffc02001e2:	dd250513          	addi	a0,a0,-558 # ffffffffc0201fb0 <etext+0xc0>
ffffffffc02001e6:	0141                	addi	sp,sp,16
ffffffffc02001e8:	b5d5                	j	ffffffffc02000cc <cprintf>

ffffffffc02001ea <print_stackframe>:
ffffffffc02001ea:	1141                	addi	sp,sp,-16
ffffffffc02001ec:	00002617          	auipc	a2,0x2
ffffffffc02001f0:	df460613          	addi	a2,a2,-524 # ffffffffc0201fe0 <etext+0xf0>
ffffffffc02001f4:	04e00593          	li	a1,78
ffffffffc02001f8:	00002517          	auipc	a0,0x2
ffffffffc02001fc:	e0050513          	addi	a0,a0,-512 # ffffffffc0201ff8 <etext+0x108>
ffffffffc0200200:	e406                	sd	ra,8(sp)
ffffffffc0200202:	178000ef          	jal	ffffffffc020037a <__panic>

ffffffffc0200206 <mon_help>:
ffffffffc0200206:	1101                	addi	sp,sp,-32
ffffffffc0200208:	e822                	sd	s0,16(sp)
ffffffffc020020a:	e426                	sd	s1,8(sp)
ffffffffc020020c:	ec06                	sd	ra,24(sp)
ffffffffc020020e:	00003417          	auipc	s0,0x3
ffffffffc0200212:	b5240413          	addi	s0,s0,-1198 # ffffffffc0202d60 <commands>
ffffffffc0200216:	00003497          	auipc	s1,0x3
ffffffffc020021a:	b9248493          	addi	s1,s1,-1134 # ffffffffc0202da8 <best_fit_pmm_manager>
ffffffffc020021e:	6410                	ld	a2,8(s0)
ffffffffc0200220:	600c                	ld	a1,0(s0)
ffffffffc0200222:	00002517          	auipc	a0,0x2
ffffffffc0200226:	dee50513          	addi	a0,a0,-530 # ffffffffc0202010 <etext+0x120>
ffffffffc020022a:	0461                	addi	s0,s0,24
ffffffffc020022c:	ea1ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200230:	fe9417e3          	bne	s0,s1,ffffffffc020021e <mon_help+0x18>
ffffffffc0200234:	60e2                	ld	ra,24(sp)
ffffffffc0200236:	6442                	ld	s0,16(sp)
ffffffffc0200238:	64a2                	ld	s1,8(sp)
ffffffffc020023a:	4501                	li	a0,0
ffffffffc020023c:	6105                	addi	sp,sp,32
ffffffffc020023e:	8082                	ret

ffffffffc0200240 <mon_kerninfo>:
ffffffffc0200240:	1141                	addi	sp,sp,-16
ffffffffc0200242:	e406                	sd	ra,8(sp)
ffffffffc0200244:	f1bff0ef          	jal	ffffffffc020015e <print_kerninfo>
ffffffffc0200248:	60a2                	ld	ra,8(sp)
ffffffffc020024a:	4501                	li	a0,0
ffffffffc020024c:	0141                	addi	sp,sp,16
ffffffffc020024e:	8082                	ret

ffffffffc0200250 <mon_backtrace>:
ffffffffc0200250:	1141                	addi	sp,sp,-16
ffffffffc0200252:	e406                	sd	ra,8(sp)
ffffffffc0200254:	f97ff0ef          	jal	ffffffffc02001ea <print_stackframe>
ffffffffc0200258:	60a2                	ld	ra,8(sp)
ffffffffc020025a:	4501                	li	a0,0
ffffffffc020025c:	0141                	addi	sp,sp,16
ffffffffc020025e:	8082                	ret

ffffffffc0200260 <kmonitor>:
ffffffffc0200260:	7155                	addi	sp,sp,-208
ffffffffc0200262:	ed56                	sd	s5,152(sp)
ffffffffc0200264:	8aaa                	mv	s5,a0
ffffffffc0200266:	00002517          	auipc	a0,0x2
ffffffffc020026a:	dba50513          	addi	a0,a0,-582 # ffffffffc0202020 <etext+0x130>
ffffffffc020026e:	e586                	sd	ra,200(sp)
ffffffffc0200270:	e1a2                	sd	s0,192(sp)
ffffffffc0200272:	fd26                	sd	s1,184(sp)
ffffffffc0200274:	f54e                	sd	s3,168(sp)
ffffffffc0200276:	f152                	sd	s4,160(sp)
ffffffffc0200278:	e95a                	sd	s6,144(sp)
ffffffffc020027a:	e55e                	sd	s7,136(sp)
ffffffffc020027c:	e51ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200280:	00002517          	auipc	a0,0x2
ffffffffc0200284:	dc850513          	addi	a0,a0,-568 # ffffffffc0202048 <etext+0x158>
ffffffffc0200288:	e45ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020028c:	000a8563          	beqz	s5,ffffffffc0200296 <kmonitor+0x36>
ffffffffc0200290:	8556                	mv	a0,s5
ffffffffc0200292:	6ce000ef          	jal	ffffffffc0200960 <print_trapframe>
ffffffffc0200296:	00003b17          	auipc	s6,0x3
ffffffffc020029a:	acab0b13          	addi	s6,s6,-1334 # ffffffffc0202d60 <commands>
ffffffffc020029e:	49bd                	li	s3,15
ffffffffc02002a0:	4a0d                	li	s4,3
ffffffffc02002a2:	00002517          	auipc	a0,0x2
ffffffffc02002a6:	dce50513          	addi	a0,a0,-562 # ffffffffc0202070 <etext+0x180>
ffffffffc02002aa:	289010ef          	jal	ffffffffc0201d32 <readline>
ffffffffc02002ae:	842a                	mv	s0,a0
ffffffffc02002b0:	d96d                	beqz	a0,ffffffffc02002a2 <kmonitor+0x42>
ffffffffc02002b2:	00054583          	lbu	a1,0(a0)
ffffffffc02002b6:	4481                	li	s1,0
ffffffffc02002b8:	e98d                	bnez	a1,ffffffffc02002ea <kmonitor+0x8a>
ffffffffc02002ba:	00003b97          	auipc	s7,0x3
ffffffffc02002be:	aa6b8b93          	addi	s7,s7,-1370 # ffffffffc0202d60 <commands>
ffffffffc02002c2:	4401                	li	s0,0
ffffffffc02002c4:	dcf9                	beqz	s1,ffffffffc02002a2 <kmonitor+0x42>
ffffffffc02002c6:	6582                	ld	a1,0(sp)
ffffffffc02002c8:	000bb503          	ld	a0,0(s7)
ffffffffc02002cc:	3b9010ef          	jal	ffffffffc0201e84 <strcmp>
ffffffffc02002d0:	cd35                	beqz	a0,ffffffffc020034c <kmonitor+0xec>
ffffffffc02002d2:	2405                	addiw	s0,s0,1
ffffffffc02002d4:	0be1                	addi	s7,s7,24
ffffffffc02002d6:	ff4418e3          	bne	s0,s4,ffffffffc02002c6 <kmonitor+0x66>
ffffffffc02002da:	6582                	ld	a1,0(sp)
ffffffffc02002dc:	00002517          	auipc	a0,0x2
ffffffffc02002e0:	dc450513          	addi	a0,a0,-572 # ffffffffc02020a0 <etext+0x1b0>
ffffffffc02002e4:	de9ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02002e8:	bf6d                	j	ffffffffc02002a2 <kmonitor+0x42>
ffffffffc02002ea:	00002517          	auipc	a0,0x2
ffffffffc02002ee:	d8e50513          	addi	a0,a0,-626 # ffffffffc0202078 <etext+0x188>
ffffffffc02002f2:	3d9010ef          	jal	ffffffffc0201eca <strchr>
ffffffffc02002f6:	c519                	beqz	a0,ffffffffc0200304 <kmonitor+0xa4>
ffffffffc02002f8:	00144583          	lbu	a1,1(s0)
ffffffffc02002fc:	00040023          	sb	zero,0(s0)
ffffffffc0200300:	0405                	addi	s0,s0,1
ffffffffc0200302:	bf5d                	j	ffffffffc02002b8 <kmonitor+0x58>
ffffffffc0200304:	00044783          	lbu	a5,0(s0)
ffffffffc0200308:	dbcd                	beqz	a5,ffffffffc02002ba <kmonitor+0x5a>
ffffffffc020030a:	03348963          	beq	s1,s3,ffffffffc020033c <kmonitor+0xdc>
ffffffffc020030e:	00349793          	slli	a5,s1,0x3
ffffffffc0200312:	978a                	add	a5,a5,sp
ffffffffc0200314:	e380                	sd	s0,0(a5)
ffffffffc0200316:	00044583          	lbu	a1,0(s0)
ffffffffc020031a:	2485                	addiw	s1,s1,1
ffffffffc020031c:	e591                	bnez	a1,ffffffffc0200328 <kmonitor+0xc8>
ffffffffc020031e:	bf71                	j	ffffffffc02002ba <kmonitor+0x5a>
ffffffffc0200320:	00144583          	lbu	a1,1(s0)
ffffffffc0200324:	0405                	addi	s0,s0,1
ffffffffc0200326:	d9d1                	beqz	a1,ffffffffc02002ba <kmonitor+0x5a>
ffffffffc0200328:	00002517          	auipc	a0,0x2
ffffffffc020032c:	d5050513          	addi	a0,a0,-688 # ffffffffc0202078 <etext+0x188>
ffffffffc0200330:	39b010ef          	jal	ffffffffc0201eca <strchr>
ffffffffc0200334:	d575                	beqz	a0,ffffffffc0200320 <kmonitor+0xc0>
ffffffffc0200336:	00044583          	lbu	a1,0(s0)
ffffffffc020033a:	bfbd                	j	ffffffffc02002b8 <kmonitor+0x58>
ffffffffc020033c:	45c1                	li	a1,16
ffffffffc020033e:	00002517          	auipc	a0,0x2
ffffffffc0200342:	d4250513          	addi	a0,a0,-702 # ffffffffc0202080 <etext+0x190>
ffffffffc0200346:	d87ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020034a:	b7d1                	j	ffffffffc020030e <kmonitor+0xae>
ffffffffc020034c:	00141793          	slli	a5,s0,0x1
ffffffffc0200350:	97a2                	add	a5,a5,s0
ffffffffc0200352:	078e                	slli	a5,a5,0x3
ffffffffc0200354:	97da                	add	a5,a5,s6
ffffffffc0200356:	6b9c                	ld	a5,16(a5)
ffffffffc0200358:	fff4851b          	addiw	a0,s1,-1
ffffffffc020035c:	8656                	mv	a2,s5
ffffffffc020035e:	002c                	addi	a1,sp,8
ffffffffc0200360:	9782                	jalr	a5
ffffffffc0200362:	f40550e3          	bgez	a0,ffffffffc02002a2 <kmonitor+0x42>
ffffffffc0200366:	60ae                	ld	ra,200(sp)
ffffffffc0200368:	640e                	ld	s0,192(sp)
ffffffffc020036a:	74ea                	ld	s1,184(sp)
ffffffffc020036c:	79aa                	ld	s3,168(sp)
ffffffffc020036e:	7a0a                	ld	s4,160(sp)
ffffffffc0200370:	6aea                	ld	s5,152(sp)
ffffffffc0200372:	6b4a                	ld	s6,144(sp)
ffffffffc0200374:	6baa                	ld	s7,136(sp)
ffffffffc0200376:	6169                	addi	sp,sp,208
ffffffffc0200378:	8082                	ret

ffffffffc020037a <__panic>:
ffffffffc020037a:	00006317          	auipc	t1,0x6
ffffffffc020037e:	0c632303          	lw	t1,198(t1) # ffffffffc0206440 <is_panic>
ffffffffc0200382:	715d                	addi	sp,sp,-80
ffffffffc0200384:	ec06                	sd	ra,24(sp)
ffffffffc0200386:	f436                	sd	a3,40(sp)
ffffffffc0200388:	f83a                	sd	a4,48(sp)
ffffffffc020038a:	fc3e                	sd	a5,56(sp)
ffffffffc020038c:	e0c2                	sd	a6,64(sp)
ffffffffc020038e:	e4c6                	sd	a7,72(sp)
ffffffffc0200390:	02031e63          	bnez	t1,ffffffffc02003cc <__panic+0x52>
ffffffffc0200394:	4705                	li	a4,1
ffffffffc0200396:	103c                	addi	a5,sp,40
ffffffffc0200398:	e822                	sd	s0,16(sp)
ffffffffc020039a:	8432                	mv	s0,a2
ffffffffc020039c:	862e                	mv	a2,a1
ffffffffc020039e:	85aa                	mv	a1,a0
ffffffffc02003a0:	00002517          	auipc	a0,0x2
ffffffffc02003a4:	da850513          	addi	a0,a0,-600 # ffffffffc0202148 <etext+0x258>
ffffffffc02003a8:	00006697          	auipc	a3,0x6
ffffffffc02003ac:	08e6ac23          	sw	a4,152(a3) # ffffffffc0206440 <is_panic>
ffffffffc02003b0:	e43e                	sd	a5,8(sp)
ffffffffc02003b2:	d1bff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02003b6:	65a2                	ld	a1,8(sp)
ffffffffc02003b8:	8522                	mv	a0,s0
ffffffffc02003ba:	cf3ff0ef          	jal	ffffffffc02000ac <vcprintf>
ffffffffc02003be:	00002517          	auipc	a0,0x2
ffffffffc02003c2:	daa50513          	addi	a0,a0,-598 # ffffffffc0202168 <etext+0x278>
ffffffffc02003c6:	d07ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02003ca:	6442                	ld	s0,16(sp)
ffffffffc02003cc:	3ae000ef          	jal	ffffffffc020077a <intr_disable>
ffffffffc02003d0:	4501                	li	a0,0
ffffffffc02003d2:	e8fff0ef          	jal	ffffffffc0200260 <kmonitor>
ffffffffc02003d6:	bfed                	j	ffffffffc02003d0 <__panic+0x56>

ffffffffc02003d8 <clock_init>:
ffffffffc02003d8:	1141                	addi	sp,sp,-16
ffffffffc02003da:	e406                	sd	ra,8(sp)
ffffffffc02003dc:	02000793          	li	a5,32
ffffffffc02003e0:	1047a7f3          	csrrs	a5,sie,a5
ffffffffc02003e4:	c0102573          	rdtime	a0
ffffffffc02003e8:	67e1                	lui	a5,0x18
ffffffffc02003ea:	6a078793          	addi	a5,a5,1696 # 186a0 <sbadaddr+0x1855d>
ffffffffc02003ee:	953e                	add	a0,a0,a5
ffffffffc02003f0:	20d010ef          	jal	ffffffffc0201dfc <sbi_set_timer>
ffffffffc02003f4:	60a2                	ld	ra,8(sp)
ffffffffc02003f6:	00006797          	auipc	a5,0x6
ffffffffc02003fa:	0407b923          	sd	zero,82(a5) # ffffffffc0206448 <ticks>
ffffffffc02003fe:	00002517          	auipc	a0,0x2
ffffffffc0200402:	d7250513          	addi	a0,a0,-654 # ffffffffc0202170 <etext+0x280>
ffffffffc0200406:	0141                	addi	sp,sp,16
ffffffffc0200408:	b1d1                	j	ffffffffc02000cc <cprintf>

ffffffffc020040a <clock_set_next_event>:
ffffffffc020040a:	c0102573          	rdtime	a0
ffffffffc020040e:	67e1                	lui	a5,0x18
ffffffffc0200410:	6a078793          	addi	a5,a5,1696 # 186a0 <sbadaddr+0x1855d>
ffffffffc0200414:	953e                	add	a0,a0,a5
ffffffffc0200416:	1e70106f          	j	ffffffffc0201dfc <sbi_set_timer>

ffffffffc020041a <cons_init>:
ffffffffc020041a:	8082                	ret

ffffffffc020041c <cons_putc>:
ffffffffc020041c:	0ff57513          	zext.b	a0,a0
ffffffffc0200420:	1c30106f          	j	ffffffffc0201de2 <sbi_console_putchar>

ffffffffc0200424 <cons_getc>:
ffffffffc0200424:	1f30106f          	j	ffffffffc0201e16 <sbi_console_getchar>

ffffffffc0200428 <dtb_init>:
ffffffffc0200428:	7179                	addi	sp,sp,-48
ffffffffc020042a:	00002517          	auipc	a0,0x2
ffffffffc020042e:	d6650513          	addi	a0,a0,-666 # ffffffffc0202190 <etext+0x2a0>
ffffffffc0200432:	f406                	sd	ra,40(sp)
ffffffffc0200434:	f022                	sd	s0,32(sp)
ffffffffc0200436:	c97ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020043a:	00006597          	auipc	a1,0x6
ffffffffc020043e:	bc65b583          	ld	a1,-1082(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200442:	00002517          	auipc	a0,0x2
ffffffffc0200446:	d5e50513          	addi	a0,a0,-674 # ffffffffc02021a0 <etext+0x2b0>
ffffffffc020044a:	00006417          	auipc	s0,0x6
ffffffffc020044e:	bbe40413          	addi	s0,s0,-1090 # ffffffffc0206008 <boot_dtb>
ffffffffc0200452:	c7bff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200456:	600c                	ld	a1,0(s0)
ffffffffc0200458:	00002517          	auipc	a0,0x2
ffffffffc020045c:	d5850513          	addi	a0,a0,-680 # ffffffffc02021b0 <etext+0x2c0>
ffffffffc0200460:	c6dff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200464:	6018                	ld	a4,0(s0)
ffffffffc0200466:	00002517          	auipc	a0,0x2
ffffffffc020046a:	d6250513          	addi	a0,a0,-670 # ffffffffc02021c8 <etext+0x2d8>
ffffffffc020046e:	10070263          	beqz	a4,ffffffffc0200572 <dtb_init+0x14a>
ffffffffc0200472:	57f5                	li	a5,-3
ffffffffc0200474:	07fa                	slli	a5,a5,0x1e
ffffffffc0200476:	973e                	add	a4,a4,a5
ffffffffc0200478:	431c                	lw	a5,0(a4)
ffffffffc020047a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020047e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed9a55>
ffffffffc0200482:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200486:	0187961b          	slliw	a2,a5,0x18
ffffffffc020048a:	0187d51b          	srliw	a0,a5,0x18
ffffffffc020048e:	0ff5f593          	zext.b	a1,a1
ffffffffc0200492:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200496:	05c2                	slli	a1,a1,0x10
ffffffffc0200498:	8e49                	or	a2,a2,a0
ffffffffc020049a:	0ff7f793          	zext.b	a5,a5
ffffffffc020049e:	8dd1                	or	a1,a1,a2
ffffffffc02004a0:	07a2                	slli	a5,a5,0x8
ffffffffc02004a2:	8ddd                	or	a1,a1,a5
ffffffffc02004a4:	00ff0837          	lui	a6,0xff0
ffffffffc02004a8:	0cd59963          	bne	a1,a3,ffffffffc020057a <dtb_init+0x152>
ffffffffc02004ac:	4710                	lw	a2,8(a4)
ffffffffc02004ae:	4754                	lw	a3,12(a4)
ffffffffc02004b0:	e84a                	sd	s2,16(sp)
ffffffffc02004b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02004b6:	0086d79b          	srliw	a5,a3,0x8
ffffffffc02004ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02004be:	0186d31b          	srliw	t1,a3,0x18
ffffffffc02004c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02004c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02004ca:	0104141b          	slliw	s0,s0,0x10
ffffffffc02004ce:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004d2:	0107979b          	slliw	a5,a5,0x10
ffffffffc02004d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02004da:	01c56533          	or	a0,a0,t3
ffffffffc02004de:	0065e5b3          	or	a1,a1,t1
ffffffffc02004e2:	01047433          	and	s0,s0,a6
ffffffffc02004e6:	0ff67613          	zext.b	a2,a2
ffffffffc02004ea:	0107f7b3          	and	a5,a5,a6
ffffffffc02004ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02004f2:	8c49                	or	s0,s0,a0
ffffffffc02004f4:	0622                	slli	a2,a2,0x8
ffffffffc02004f6:	8fcd                	or	a5,a5,a1
ffffffffc02004f8:	06a2                	slli	a3,a3,0x8
ffffffffc02004fa:	8c51                	or	s0,s0,a2
ffffffffc02004fc:	8fd5                	or	a5,a5,a3
ffffffffc02004fe:	1402                	slli	s0,s0,0x20
ffffffffc0200500:	1782                	slli	a5,a5,0x20
ffffffffc0200502:	9001                	srli	s0,s0,0x20
ffffffffc0200504:	9381                	srli	a5,a5,0x20
ffffffffc0200506:	ec26                	sd	s1,24(sp)
ffffffffc0200508:	4881                	li	a7,0
ffffffffc020050a:	430d                	li	t1,3
ffffffffc020050c:	943a                	add	s0,s0,a4
ffffffffc020050e:	00e78933          	add	s2,a5,a4
ffffffffc0200512:	4e05                	li	t3,1
ffffffffc0200514:	4018                	lw	a4,0(s0)
ffffffffc0200516:	0087579b          	srliw	a5,a4,0x8
ffffffffc020051a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020051e:	0187561b          	srliw	a2,a4,0x18
ffffffffc0200522:	0107979b          	slliw	a5,a5,0x10
ffffffffc0200526:	0107571b          	srliw	a4,a4,0x10
ffffffffc020052a:	0107f7b3          	and	a5,a5,a6
ffffffffc020052e:	8ed1                	or	a3,a3,a2
ffffffffc0200530:	0ff77713          	zext.b	a4,a4
ffffffffc0200534:	8fd5                	or	a5,a5,a3
ffffffffc0200536:	0722                	slli	a4,a4,0x8
ffffffffc0200538:	8fd9                	or	a5,a5,a4
ffffffffc020053a:	04678863          	beq	a5,t1,ffffffffc020058a <dtb_init+0x162>
ffffffffc020053e:	0411                	addi	s0,s0,4
ffffffffc0200540:	00f36a63          	bltu	t1,a5,ffffffffc0200554 <dtb_init+0x12c>
ffffffffc0200544:	8522                	mv	a0,s0
ffffffffc0200546:	07c78d63          	beq	a5,t3,ffffffffc02005c0 <dtb_init+0x198>
ffffffffc020054a:	4709                	li	a4,2
ffffffffc020054c:	00e79763          	bne	a5,a4,ffffffffc020055a <dtb_init+0x132>
ffffffffc0200550:	4881                	li	a7,0
ffffffffc0200552:	b7c9                	j	ffffffffc0200514 <dtb_init+0xec>
ffffffffc0200554:	4711                	li	a4,4
ffffffffc0200556:	fae78fe3          	beq	a5,a4,ffffffffc0200514 <dtb_init+0xec>
ffffffffc020055a:	00002517          	auipc	a0,0x2
ffffffffc020055e:	d3650513          	addi	a0,a0,-714 # ffffffffc0202290 <etext+0x3a0>
ffffffffc0200562:	b6bff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200566:	64e2                	ld	s1,24(sp)
ffffffffc0200568:	6942                	ld	s2,16(sp)
ffffffffc020056a:	00002517          	auipc	a0,0x2
ffffffffc020056e:	d5e50513          	addi	a0,a0,-674 # ffffffffc02022c8 <etext+0x3d8>
ffffffffc0200572:	7402                	ld	s0,32(sp)
ffffffffc0200574:	70a2                	ld	ra,40(sp)
ffffffffc0200576:	6145                	addi	sp,sp,48
ffffffffc0200578:	be91                	j	ffffffffc02000cc <cprintf>
ffffffffc020057a:	7402                	ld	s0,32(sp)
ffffffffc020057c:	70a2                	ld	ra,40(sp)
ffffffffc020057e:	00002517          	auipc	a0,0x2
ffffffffc0200582:	c6a50513          	addi	a0,a0,-918 # ffffffffc02021e8 <etext+0x2f8>
ffffffffc0200586:	6145                	addi	sp,sp,48
ffffffffc0200588:	b691                	j	ffffffffc02000cc <cprintf>
ffffffffc020058a:	4058                	lw	a4,4(s0)
ffffffffc020058c:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200590:	0187169b          	slliw	a3,a4,0x18
ffffffffc0200594:	0187561b          	srliw	a2,a4,0x18
ffffffffc0200598:	0107979b          	slliw	a5,a5,0x10
ffffffffc020059c:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005a0:	0107f7b3          	and	a5,a5,a6
ffffffffc02005a4:	8ed1                	or	a3,a3,a2
ffffffffc02005a6:	0ff77713          	zext.b	a4,a4
ffffffffc02005aa:	8fd5                	or	a5,a5,a3
ffffffffc02005ac:	0722                	slli	a4,a4,0x8
ffffffffc02005ae:	8fd9                	or	a5,a5,a4
ffffffffc02005b0:	04089363          	bnez	a7,ffffffffc02005f6 <dtb_init+0x1ce>
ffffffffc02005b4:	1782                	slli	a5,a5,0x20
ffffffffc02005b6:	9381                	srli	a5,a5,0x20
ffffffffc02005b8:	043d                	addi	s0,s0,15
ffffffffc02005ba:	943e                	add	s0,s0,a5
ffffffffc02005bc:	9871                	andi	s0,s0,-4
ffffffffc02005be:	bf99                	j	ffffffffc0200514 <dtb_init+0xec>
ffffffffc02005c0:	e046                	sd	a7,0(sp)
ffffffffc02005c2:	08b010ef          	jal	ffffffffc0201e4c <strlen>
ffffffffc02005c6:	84aa                	mv	s1,a0
ffffffffc02005c8:	4619                	li	a2,6
ffffffffc02005ca:	8522                	mv	a0,s0
ffffffffc02005cc:	00002597          	auipc	a1,0x2
ffffffffc02005d0:	c4458593          	addi	a1,a1,-956 # ffffffffc0202210 <etext+0x320>
ffffffffc02005d4:	0cf010ef          	jal	ffffffffc0201ea2 <strncmp>
ffffffffc02005d8:	6882                	ld	a7,0(sp)
ffffffffc02005da:	0411                	addi	s0,s0,4
ffffffffc02005dc:	0004879b          	sext.w	a5,s1
ffffffffc02005e0:	943e                	add	s0,s0,a5
ffffffffc02005e2:	00153513          	seqz	a0,a0
ffffffffc02005e6:	9871                	andi	s0,s0,-4
ffffffffc02005e8:	00a8e8b3          	or	a7,a7,a0
ffffffffc02005ec:	00ff0837          	lui	a6,0xff0
ffffffffc02005f0:	430d                	li	t1,3
ffffffffc02005f2:	4e05                	li	t3,1
ffffffffc02005f4:	b705                	j	ffffffffc0200514 <dtb_init+0xec>
ffffffffc02005f6:	4418                	lw	a4,8(s0)
ffffffffc02005f8:	00002597          	auipc	a1,0x2
ffffffffc02005fc:	c2058593          	addi	a1,a1,-992 # ffffffffc0202218 <etext+0x328>
ffffffffc0200600:	e43e                	sd	a5,8(sp)
ffffffffc0200602:	0087551b          	srliw	a0,a4,0x8
ffffffffc0200606:	0187561b          	srliw	a2,a4,0x18
ffffffffc020060a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020060e:	0105151b          	slliw	a0,a0,0x10
ffffffffc0200612:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200616:	01057533          	and	a0,a0,a6
ffffffffc020061a:	8ed1                	or	a3,a3,a2
ffffffffc020061c:	0ff77713          	zext.b	a4,a4
ffffffffc0200620:	0722                	slli	a4,a4,0x8
ffffffffc0200622:	8d55                	or	a0,a0,a3
ffffffffc0200624:	8d59                	or	a0,a0,a4
ffffffffc0200626:	1502                	slli	a0,a0,0x20
ffffffffc0200628:	9101                	srli	a0,a0,0x20
ffffffffc020062a:	954a                	add	a0,a0,s2
ffffffffc020062c:	e046                	sd	a7,0(sp)
ffffffffc020062e:	057010ef          	jal	ffffffffc0201e84 <strcmp>
ffffffffc0200632:	67a2                	ld	a5,8(sp)
ffffffffc0200634:	473d                	li	a4,15
ffffffffc0200636:	00153513          	seqz	a0,a0
ffffffffc020063a:	00f73733          	sltu	a4,a4,a5
ffffffffc020063e:	8f69                	and	a4,a4,a0
ffffffffc0200640:	6882                	ld	a7,0(sp)
ffffffffc0200642:	00ff0837          	lui	a6,0xff0
ffffffffc0200646:	430d                	li	t1,3
ffffffffc0200648:	4e05                	li	t3,1
ffffffffc020064a:	d72d                	beqz	a4,ffffffffc02005b4 <dtb_init+0x18c>
ffffffffc020064c:	00c43683          	ld	a3,12(s0)
ffffffffc0200650:	01443703          	ld	a4,20(s0)
ffffffffc0200654:	00002517          	auipc	a0,0x2
ffffffffc0200658:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0202220 <etext+0x330>
ffffffffc020065c:	0206d793          	srli	a5,a3,0x20
ffffffffc0200660:	0087d31b          	srliw	t1,a5,0x8
ffffffffc0200664:	00871f93          	slli	t6,a4,0x8
ffffffffc0200668:	02075893          	srli	a7,a4,0x20
ffffffffc020066c:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200670:	0187959b          	slliw	a1,a5,0x18
ffffffffc0200674:	0103131b          	slliw	t1,t1,0x10
ffffffffc0200678:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020067c:	420fd613          	srai	a2,t6,0x20
ffffffffc0200680:	0188df1b          	srliw	t5,a7,0x18
ffffffffc0200684:	01037333          	and	t1,t1,a6
ffffffffc0200688:	01889e9b          	slliw	t4,a7,0x18
ffffffffc020068c:	01c5e5b3          	or	a1,a1,t3
ffffffffc0200690:	0ff7f793          	zext.b	a5,a5
ffffffffc0200694:	01eeeeb3          	or	t4,t4,t5
ffffffffc0200698:	0065e5b3          	or	a1,a1,t1
ffffffffc020069c:	0086de1b          	srliw	t3,a3,0x8
ffffffffc02006a0:	01067633          	and	a2,a2,a6
ffffffffc02006a4:	0087531b          	srliw	t1,a4,0x8
ffffffffc02006a8:	07a2                	slli	a5,a5,0x8
ffffffffc02006aa:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02006ae:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02006b2:	0103131b          	slliw	t1,t1,0x10
ffffffffc02006b6:	8ddd                	or	a1,a1,a5
ffffffffc02006b8:	01d66633          	or	a2,a2,t4
ffffffffc02006bc:	0186979b          	slliw	a5,a3,0x18
ffffffffc02006c0:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02006c4:	0187141b          	slliw	s0,a4,0x18
ffffffffc02006c8:	0ff8f893          	zext.b	a7,a7
ffffffffc02006cc:	010e1e1b          	slliw	t3,t3,0x10
ffffffffc02006d0:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02006d4:	0107571b          	srliw	a4,a4,0x10
ffffffffc02006d8:	010e7e33          	and	t3,t3,a6
ffffffffc02006dc:	08a2                	slli	a7,a7,0x8
ffffffffc02006de:	01e7e7b3          	or	a5,a5,t5
ffffffffc02006e2:	01037833          	and	a6,t1,a6
ffffffffc02006e6:	01d46433          	or	s0,s0,t4
ffffffffc02006ea:	0ff6f693          	zext.b	a3,a3
ffffffffc02006ee:	0ff77713          	zext.b	a4,a4
ffffffffc02006f2:	01166633          	or	a2,a2,a7
ffffffffc02006f6:	01c7e7b3          	or	a5,a5,t3
ffffffffc02006fa:	06a2                	slli	a3,a3,0x8
ffffffffc02006fc:	01046433          	or	s0,s0,a6
ffffffffc0200700:	0722                	slli	a4,a4,0x8
ffffffffc0200702:	8fd5                	or	a5,a5,a3
ffffffffc0200704:	8c59                	or	s0,s0,a4
ffffffffc0200706:	1582                	slli	a1,a1,0x20
ffffffffc0200708:	1602                	slli	a2,a2,0x20
ffffffffc020070a:	1782                	slli	a5,a5,0x20
ffffffffc020070c:	9201                	srli	a2,a2,0x20
ffffffffc020070e:	9181                	srli	a1,a1,0x20
ffffffffc0200710:	1402                	slli	s0,s0,0x20
ffffffffc0200712:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200716:	8c51                	or	s0,s0,a2
ffffffffc0200718:	9b5ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020071c:	85a6                	mv	a1,s1
ffffffffc020071e:	00002517          	auipc	a0,0x2
ffffffffc0200722:	b2250513          	addi	a0,a0,-1246 # ffffffffc0202240 <etext+0x350>
ffffffffc0200726:	9a7ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020072a:	01445613          	srli	a2,s0,0x14
ffffffffc020072e:	85a2                	mv	a1,s0
ffffffffc0200730:	00002517          	auipc	a0,0x2
ffffffffc0200734:	b2850513          	addi	a0,a0,-1240 # ffffffffc0202258 <etext+0x368>
ffffffffc0200738:	995ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020073c:	009405b3          	add	a1,s0,s1
ffffffffc0200740:	15fd                	addi	a1,a1,-1
ffffffffc0200742:	00002517          	auipc	a0,0x2
ffffffffc0200746:	b3650513          	addi	a0,a0,-1226 # ffffffffc0202278 <etext+0x388>
ffffffffc020074a:	983ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020074e:	00006797          	auipc	a5,0x6
ffffffffc0200752:	d097b523          	sd	s1,-758(a5) # ffffffffc0206458 <memory_base>
ffffffffc0200756:	00006797          	auipc	a5,0x6
ffffffffc020075a:	ce87bd23          	sd	s0,-774(a5) # ffffffffc0206450 <memory_size>
ffffffffc020075e:	b521                	j	ffffffffc0200566 <dtb_init+0x13e>

ffffffffc0200760 <get_memory_base>:
ffffffffc0200760:	00006517          	auipc	a0,0x6
ffffffffc0200764:	cf853503          	ld	a0,-776(a0) # ffffffffc0206458 <memory_base>
ffffffffc0200768:	8082                	ret

ffffffffc020076a <get_memory_size>:
ffffffffc020076a:	00006517          	auipc	a0,0x6
ffffffffc020076e:	ce653503          	ld	a0,-794(a0) # ffffffffc0206450 <memory_size>
ffffffffc0200772:	8082                	ret

ffffffffc0200774 <intr_enable>:
ffffffffc0200774:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200778:	8082                	ret

ffffffffc020077a <intr_disable>:
ffffffffc020077a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020077e:	8082                	ret

ffffffffc0200780 <idt_init>:
ffffffffc0200780:	14005073          	csrwi	sscratch,0
ffffffffc0200784:	00000797          	auipc	a5,0x0
ffffffffc0200788:	3d078793          	addi	a5,a5,976 # ffffffffc0200b54 <__alltraps>
ffffffffc020078c:	10579073          	csrw	stvec,a5
ffffffffc0200790:	8082                	ret

ffffffffc0200792 <print_regs>:
ffffffffc0200792:	610c                	ld	a1,0(a0)
ffffffffc0200794:	1141                	addi	sp,sp,-16
ffffffffc0200796:	e022                	sd	s0,0(sp)
ffffffffc0200798:	842a                	mv	s0,a0
ffffffffc020079a:	00002517          	auipc	a0,0x2
ffffffffc020079e:	b4650513          	addi	a0,a0,-1210 # ffffffffc02022e0 <etext+0x3f0>
ffffffffc02007a2:	e406                	sd	ra,8(sp)
ffffffffc02007a4:	929ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02007a8:	640c                	ld	a1,8(s0)
ffffffffc02007aa:	00002517          	auipc	a0,0x2
ffffffffc02007ae:	b4e50513          	addi	a0,a0,-1202 # ffffffffc02022f8 <etext+0x408>
ffffffffc02007b2:	91bff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02007b6:	680c                	ld	a1,16(s0)
ffffffffc02007b8:	00002517          	auipc	a0,0x2
ffffffffc02007bc:	b5850513          	addi	a0,a0,-1192 # ffffffffc0202310 <etext+0x420>
ffffffffc02007c0:	90dff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02007c4:	6c0c                	ld	a1,24(s0)
ffffffffc02007c6:	00002517          	auipc	a0,0x2
ffffffffc02007ca:	b6250513          	addi	a0,a0,-1182 # ffffffffc0202328 <etext+0x438>
ffffffffc02007ce:	8ffff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02007d2:	700c                	ld	a1,32(s0)
ffffffffc02007d4:	00002517          	auipc	a0,0x2
ffffffffc02007d8:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0202340 <etext+0x450>
ffffffffc02007dc:	8f1ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02007e0:	740c                	ld	a1,40(s0)
ffffffffc02007e2:	00002517          	auipc	a0,0x2
ffffffffc02007e6:	b7650513          	addi	a0,a0,-1162 # ffffffffc0202358 <etext+0x468>
ffffffffc02007ea:	8e3ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02007ee:	780c                	ld	a1,48(s0)
ffffffffc02007f0:	00002517          	auipc	a0,0x2
ffffffffc02007f4:	b8050513          	addi	a0,a0,-1152 # ffffffffc0202370 <etext+0x480>
ffffffffc02007f8:	8d5ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02007fc:	7c0c                	ld	a1,56(s0)
ffffffffc02007fe:	00002517          	auipc	a0,0x2
ffffffffc0200802:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0202388 <etext+0x498>
ffffffffc0200806:	8c7ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020080a:	602c                	ld	a1,64(s0)
ffffffffc020080c:	00002517          	auipc	a0,0x2
ffffffffc0200810:	b9450513          	addi	a0,a0,-1132 # ffffffffc02023a0 <etext+0x4b0>
ffffffffc0200814:	8b9ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200818:	642c                	ld	a1,72(s0)
ffffffffc020081a:	00002517          	auipc	a0,0x2
ffffffffc020081e:	b9e50513          	addi	a0,a0,-1122 # ffffffffc02023b8 <etext+0x4c8>
ffffffffc0200822:	8abff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200826:	682c                	ld	a1,80(s0)
ffffffffc0200828:	00002517          	auipc	a0,0x2
ffffffffc020082c:	ba850513          	addi	a0,a0,-1112 # ffffffffc02023d0 <etext+0x4e0>
ffffffffc0200830:	89dff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200834:	6c2c                	ld	a1,88(s0)
ffffffffc0200836:	00002517          	auipc	a0,0x2
ffffffffc020083a:	bb250513          	addi	a0,a0,-1102 # ffffffffc02023e8 <etext+0x4f8>
ffffffffc020083e:	88fff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200842:	702c                	ld	a1,96(s0)
ffffffffc0200844:	00002517          	auipc	a0,0x2
ffffffffc0200848:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0202400 <etext+0x510>
ffffffffc020084c:	881ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200850:	742c                	ld	a1,104(s0)
ffffffffc0200852:	00002517          	auipc	a0,0x2
ffffffffc0200856:	bc650513          	addi	a0,a0,-1082 # ffffffffc0202418 <etext+0x528>
ffffffffc020085a:	873ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020085e:	782c                	ld	a1,112(s0)
ffffffffc0200860:	00002517          	auipc	a0,0x2
ffffffffc0200864:	bd050513          	addi	a0,a0,-1072 # ffffffffc0202430 <etext+0x540>
ffffffffc0200868:	865ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020086c:	7c2c                	ld	a1,120(s0)
ffffffffc020086e:	00002517          	auipc	a0,0x2
ffffffffc0200872:	bda50513          	addi	a0,a0,-1062 # ffffffffc0202448 <etext+0x558>
ffffffffc0200876:	857ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020087a:	604c                	ld	a1,128(s0)
ffffffffc020087c:	00002517          	auipc	a0,0x2
ffffffffc0200880:	be450513          	addi	a0,a0,-1052 # ffffffffc0202460 <etext+0x570>
ffffffffc0200884:	849ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200888:	644c                	ld	a1,136(s0)
ffffffffc020088a:	00002517          	auipc	a0,0x2
ffffffffc020088e:	bee50513          	addi	a0,a0,-1042 # ffffffffc0202478 <etext+0x588>
ffffffffc0200892:	83bff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200896:	684c                	ld	a1,144(s0)
ffffffffc0200898:	00002517          	auipc	a0,0x2
ffffffffc020089c:	bf850513          	addi	a0,a0,-1032 # ffffffffc0202490 <etext+0x5a0>
ffffffffc02008a0:	82dff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02008a4:	6c4c                	ld	a1,152(s0)
ffffffffc02008a6:	00002517          	auipc	a0,0x2
ffffffffc02008aa:	c0250513          	addi	a0,a0,-1022 # ffffffffc02024a8 <etext+0x5b8>
ffffffffc02008ae:	81fff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02008b2:	704c                	ld	a1,160(s0)
ffffffffc02008b4:	00002517          	auipc	a0,0x2
ffffffffc02008b8:	c0c50513          	addi	a0,a0,-1012 # ffffffffc02024c0 <etext+0x5d0>
ffffffffc02008bc:	811ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02008c0:	744c                	ld	a1,168(s0)
ffffffffc02008c2:	00002517          	auipc	a0,0x2
ffffffffc02008c6:	c1650513          	addi	a0,a0,-1002 # ffffffffc02024d8 <etext+0x5e8>
ffffffffc02008ca:	803ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02008ce:	784c                	ld	a1,176(s0)
ffffffffc02008d0:	00002517          	auipc	a0,0x2
ffffffffc02008d4:	c2050513          	addi	a0,a0,-992 # ffffffffc02024f0 <etext+0x600>
ffffffffc02008d8:	ff4ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02008dc:	7c4c                	ld	a1,184(s0)
ffffffffc02008de:	00002517          	auipc	a0,0x2
ffffffffc02008e2:	c2a50513          	addi	a0,a0,-982 # ffffffffc0202508 <etext+0x618>
ffffffffc02008e6:	fe6ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02008ea:	606c                	ld	a1,192(s0)
ffffffffc02008ec:	00002517          	auipc	a0,0x2
ffffffffc02008f0:	c3450513          	addi	a0,a0,-972 # ffffffffc0202520 <etext+0x630>
ffffffffc02008f4:	fd8ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02008f8:	646c                	ld	a1,200(s0)
ffffffffc02008fa:	00002517          	auipc	a0,0x2
ffffffffc02008fe:	c3e50513          	addi	a0,a0,-962 # ffffffffc0202538 <etext+0x648>
ffffffffc0200902:	fcaff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200906:	686c                	ld	a1,208(s0)
ffffffffc0200908:	00002517          	auipc	a0,0x2
ffffffffc020090c:	c4850513          	addi	a0,a0,-952 # ffffffffc0202550 <etext+0x660>
ffffffffc0200910:	fbcff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200914:	6c6c                	ld	a1,216(s0)
ffffffffc0200916:	00002517          	auipc	a0,0x2
ffffffffc020091a:	c5250513          	addi	a0,a0,-942 # ffffffffc0202568 <etext+0x678>
ffffffffc020091e:	faeff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200922:	706c                	ld	a1,224(s0)
ffffffffc0200924:	00002517          	auipc	a0,0x2
ffffffffc0200928:	c5c50513          	addi	a0,a0,-932 # ffffffffc0202580 <etext+0x690>
ffffffffc020092c:	fa0ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200930:	746c                	ld	a1,232(s0)
ffffffffc0200932:	00002517          	auipc	a0,0x2
ffffffffc0200936:	c6650513          	addi	a0,a0,-922 # ffffffffc0202598 <etext+0x6a8>
ffffffffc020093a:	f92ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020093e:	786c                	ld	a1,240(s0)
ffffffffc0200940:	00002517          	auipc	a0,0x2
ffffffffc0200944:	c7050513          	addi	a0,a0,-912 # ffffffffc02025b0 <etext+0x6c0>
ffffffffc0200948:	f84ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020094c:	7c6c                	ld	a1,248(s0)
ffffffffc020094e:	6402                	ld	s0,0(sp)
ffffffffc0200950:	60a2                	ld	ra,8(sp)
ffffffffc0200952:	00002517          	auipc	a0,0x2
ffffffffc0200956:	c7650513          	addi	a0,a0,-906 # ffffffffc02025c8 <etext+0x6d8>
ffffffffc020095a:	0141                	addi	sp,sp,16
ffffffffc020095c:	f70ff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200960 <print_trapframe>:
ffffffffc0200960:	1141                	addi	sp,sp,-16
ffffffffc0200962:	e022                	sd	s0,0(sp)
ffffffffc0200964:	85aa                	mv	a1,a0
ffffffffc0200966:	842a                	mv	s0,a0
ffffffffc0200968:	00002517          	auipc	a0,0x2
ffffffffc020096c:	c7850513          	addi	a0,a0,-904 # ffffffffc02025e0 <etext+0x6f0>
ffffffffc0200970:	e406                	sd	ra,8(sp)
ffffffffc0200972:	f5aff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200976:	8522                	mv	a0,s0
ffffffffc0200978:	e1bff0ef          	jal	ffffffffc0200792 <print_regs>
ffffffffc020097c:	10043583          	ld	a1,256(s0)
ffffffffc0200980:	00002517          	auipc	a0,0x2
ffffffffc0200984:	c7850513          	addi	a0,a0,-904 # ffffffffc02025f8 <etext+0x708>
ffffffffc0200988:	f44ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020098c:	10843583          	ld	a1,264(s0)
ffffffffc0200990:	00002517          	auipc	a0,0x2
ffffffffc0200994:	c8050513          	addi	a0,a0,-896 # ffffffffc0202610 <etext+0x720>
ffffffffc0200998:	f34ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc020099c:	11043583          	ld	a1,272(s0)
ffffffffc02009a0:	00002517          	auipc	a0,0x2
ffffffffc02009a4:	c8850513          	addi	a0,a0,-888 # ffffffffc0202628 <etext+0x738>
ffffffffc02009a8:	f24ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02009ac:	11843583          	ld	a1,280(s0)
ffffffffc02009b0:	6402                	ld	s0,0(sp)
ffffffffc02009b2:	60a2                	ld	ra,8(sp)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	c8c50513          	addi	a0,a0,-884 # ffffffffc0202640 <etext+0x750>
ffffffffc02009bc:	0141                	addi	sp,sp,16
ffffffffc02009be:	f0eff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc02009c2 <interrupt_handler>:
ffffffffc02009c2:	11853583          	ld	a1,280(a0)
ffffffffc02009c6:	4715                	li	a4,5
ffffffffc02009c8:	00159793          	slli	a5,a1,0x1
ffffffffc02009cc:	8385                	srli	a5,a5,0x1
ffffffffc02009ce:	02e78463          	beq	a5,a4,ffffffffc02009f6 <interrupt_handler+0x34>
ffffffffc02009d2:	4725                	li	a4,9
ffffffffc02009d4:	00e78b63          	beq	a5,a4,ffffffffc02009ea <interrupt_handler+0x28>
ffffffffc02009d8:	4705                	li	a4,1
ffffffffc02009da:	06e79763          	bne	a5,a4,ffffffffc0200a48 <interrupt_handler+0x86>
ffffffffc02009de:	00002517          	auipc	a0,0x2
ffffffffc02009e2:	c7a50513          	addi	a0,a0,-902 # ffffffffc0202658 <etext+0x768>
ffffffffc02009e6:	ee6ff06f          	j	ffffffffc02000cc <cprintf>
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	c9e50513          	addi	a0,a0,-866 # ffffffffc0202688 <etext+0x798>
ffffffffc02009f2:	edaff06f          	j	ffffffffc02000cc <cprintf>
ffffffffc02009f6:	1141                	addi	sp,sp,-16
ffffffffc02009f8:	e406                	sd	ra,8(sp)
ffffffffc02009fa:	a11ff0ef          	jal	ffffffffc020040a <clock_set_next_event>
ffffffffc02009fe:	00006697          	auipc	a3,0x6
ffffffffc0200a02:	a4a68693          	addi	a3,a3,-1462 # ffffffffc0206448 <ticks>
ffffffffc0200a06:	629c                	ld	a5,0(a3)
ffffffffc0200a08:	28f5c737          	lui	a4,0x28f5c
ffffffffc0200a0c:	28f70713          	addi	a4,a4,655 # 28f5c28f <sbadaddr+0x28f5c14c>
ffffffffc0200a10:	0785                	addi	a5,a5,1
ffffffffc0200a12:	e29c                	sd	a5,0(a3)
ffffffffc0200a14:	6288                	ld	a0,0(a3)
ffffffffc0200a16:	5c28f637          	lui	a2,0x5c28f
ffffffffc0200a1a:	1702                	slli	a4,a4,0x20
ffffffffc0200a1c:	5c360613          	addi	a2,a2,1475 # 5c28f5c3 <sbadaddr+0x5c28f480>
ffffffffc0200a20:	00255793          	srli	a5,a0,0x2
ffffffffc0200a24:	9732                	add	a4,a4,a2
ffffffffc0200a26:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc0200a2a:	06400593          	li	a1,100
ffffffffc0200a2e:	8389                	srli	a5,a5,0x2
ffffffffc0200a30:	02b787b3          	mul	a5,a5,a1
ffffffffc0200a34:	02f50563          	beq	a0,a5,ffffffffc0200a5e <interrupt_handler+0x9c>
ffffffffc0200a38:	6298                	ld	a4,0(a3)
ffffffffc0200a3a:	3e700793          	li	a5,999
ffffffffc0200a3e:	00e7ec63          	bltu	a5,a4,ffffffffc0200a56 <interrupt_handler+0x94>
ffffffffc0200a42:	60a2                	ld	ra,8(sp)
ffffffffc0200a44:	0141                	addi	sp,sp,16
ffffffffc0200a46:	8082                	ret
ffffffffc0200a48:	2581                	sext.w	a1,a1
ffffffffc0200a4a:	00002517          	auipc	a0,0x2
ffffffffc0200a4e:	c5e50513          	addi	a0,a0,-930 # ffffffffc02026a8 <etext+0x7b8>
ffffffffc0200a52:	e7aff06f          	j	ffffffffc02000cc <cprintf>
ffffffffc0200a56:	60a2                	ld	ra,8(sp)
ffffffffc0200a58:	0141                	addi	sp,sp,16
ffffffffc0200a5a:	3d80106f          	j	ffffffffc0201e32 <sbi_shutdown>
ffffffffc0200a5e:	00002517          	auipc	a0,0x2
ffffffffc0200a62:	c1a50513          	addi	a0,a0,-998 # ffffffffc0202678 <etext+0x788>
ffffffffc0200a66:	e66ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200a6a:	00006697          	auipc	a3,0x6
ffffffffc0200a6e:	9de68693          	addi	a3,a3,-1570 # ffffffffc0206448 <ticks>
ffffffffc0200a72:	b7d9                	j	ffffffffc0200a38 <interrupt_handler+0x76>

ffffffffc0200a74 <exception_handler>:
ffffffffc0200a74:	11853703          	ld	a4,280(a0)
ffffffffc0200a78:	1101                	addi	sp,sp,-32
ffffffffc0200a7a:	ec06                	sd	ra,24(sp)
ffffffffc0200a7c:	46a1                	li	a3,8
ffffffffc0200a7e:	87aa                	mv	a5,a0
ffffffffc0200a80:	06d70d63          	beq	a4,a3,ffffffffc0200afa <exception_handler+0x86>
ffffffffc0200a84:	04e6e263          	bltu	a3,a4,ffffffffc0200ac8 <exception_handler+0x54>
ffffffffc0200a88:	4689                	li	a3,2
ffffffffc0200a8a:	08d70063          	beq	a4,a3,ffffffffc0200b0a <exception_handler+0x96>
ffffffffc0200a8e:	460d                	li	a2,3
ffffffffc0200a90:	06c71163          	bne	a4,a2,ffffffffc0200af2 <exception_handler+0x7e>
ffffffffc0200a94:	10853583          	ld	a1,264(a0)
ffffffffc0200a98:	e02a                	sd	a0,0(sp)
ffffffffc0200a9a:	00002517          	auipc	a0,0x2
ffffffffc0200a9e:	c2e50513          	addi	a0,a0,-978 # ffffffffc02026c8 <etext+0x7d8>
ffffffffc0200aa2:	e43a                	sd	a4,8(sp)
ffffffffc0200aa4:	e28ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200aa8:	6782                	ld	a5,0(sp)
ffffffffc0200aaa:	6722                	ld	a4,8(sp)
ffffffffc0200aac:	4689                	li	a3,2
ffffffffc0200aae:	1087b603          	ld	a2,264(a5)
ffffffffc0200ab2:	00065583          	lhu	a1,0(a2)
ffffffffc0200ab6:	898d                	andi	a1,a1,3
ffffffffc0200ab8:	08e58563          	beq	a1,a4,ffffffffc0200b42 <exception_handler+0xce>
ffffffffc0200abc:	60e2                	ld	ra,24(sp)
ffffffffc0200abe:	9636                	add	a2,a2,a3
ffffffffc0200ac0:	10c7b423          	sd	a2,264(a5)
ffffffffc0200ac4:	6105                	addi	sp,sp,32
ffffffffc0200ac6:	8082                	ret
ffffffffc0200ac8:	46a5                	li	a3,9
ffffffffc0200aca:	02d71463          	bne	a4,a3,ffffffffc0200af2 <exception_handler+0x7e>
ffffffffc0200ace:	10853583          	ld	a1,264(a0)
ffffffffc0200ad2:	e02a                	sd	a0,0(sp)
ffffffffc0200ad4:	00002517          	auipc	a0,0x2
ffffffffc0200ad8:	c4c50513          	addi	a0,a0,-948 # ffffffffc0202720 <etext+0x830>
ffffffffc0200adc:	df0ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200ae0:	6782                	ld	a5,0(sp)
ffffffffc0200ae2:	60e2                	ld	ra,24(sp)
ffffffffc0200ae4:	1087b703          	ld	a4,264(a5)
ffffffffc0200ae8:	0711                	addi	a4,a4,4
ffffffffc0200aea:	10e7b423          	sd	a4,264(a5)
ffffffffc0200aee:	6105                	addi	sp,sp,32
ffffffffc0200af0:	8082                	ret
ffffffffc0200af2:	60e2                	ld	ra,24(sp)
ffffffffc0200af4:	853e                	mv	a0,a5
ffffffffc0200af6:	6105                	addi	sp,sp,32
ffffffffc0200af8:	b5a5                	j	ffffffffc0200960 <print_trapframe>
ffffffffc0200afa:	10853583          	ld	a1,264(a0)
ffffffffc0200afe:	e02a                	sd	a0,0(sp)
ffffffffc0200b00:	00002517          	auipc	a0,0x2
ffffffffc0200b04:	c0850513          	addi	a0,a0,-1016 # ffffffffc0202708 <etext+0x818>
ffffffffc0200b08:	bfd1                	j	ffffffffc0200adc <exception_handler+0x68>
ffffffffc0200b0a:	10853583          	ld	a1,264(a0)
ffffffffc0200b0e:	e02a                	sd	a0,0(sp)
ffffffffc0200b10:	00002517          	auipc	a0,0x2
ffffffffc0200b14:	bd050513          	addi	a0,a0,-1072 # ffffffffc02026e0 <etext+0x7f0>
ffffffffc0200b18:	e43a                	sd	a4,8(sp)
ffffffffc0200b1a:	db2ff0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0200b1e:	6782                	ld	a5,0(sp)
ffffffffc0200b20:	458d                	li	a1,3
ffffffffc0200b22:	6722                	ld	a4,8(sp)
ffffffffc0200b24:	1087b683          	ld	a3,264(a5)
ffffffffc0200b28:	0006d603          	lhu	a2,0(a3)
ffffffffc0200b2c:	8e6d                	and	a2,a2,a1
ffffffffc0200b2e:	00b60863          	beq	a2,a1,ffffffffc0200b3e <exception_handler+0xca>
ffffffffc0200b32:	60e2                	ld	ra,24(sp)
ffffffffc0200b34:	96ba                	add	a3,a3,a4
ffffffffc0200b36:	10d7b423          	sd	a3,264(a5)
ffffffffc0200b3a:	6105                	addi	sp,sp,32
ffffffffc0200b3c:	8082                	ret
ffffffffc0200b3e:	4711                	li	a4,4
ffffffffc0200b40:	bfcd                	j	ffffffffc0200b32 <exception_handler+0xbe>
ffffffffc0200b42:	4691                	li	a3,4
ffffffffc0200b44:	bfa5                	j	ffffffffc0200abc <exception_handler+0x48>

ffffffffc0200b46 <trap>:
ffffffffc0200b46:	11853783          	ld	a5,280(a0)
ffffffffc0200b4a:	0007c363          	bltz	a5,ffffffffc0200b50 <trap+0xa>
ffffffffc0200b4e:	b71d                	j	ffffffffc0200a74 <exception_handler>
ffffffffc0200b50:	bd8d                	j	ffffffffc02009c2 <interrupt_handler>
	...

ffffffffc0200b54 <__alltraps>:
ffffffffc0200b54:	14011073          	csrw	sscratch,sp
ffffffffc0200b58:	712d                	addi	sp,sp,-288
ffffffffc0200b5a:	e002                	sd	zero,0(sp)
ffffffffc0200b5c:	e406                	sd	ra,8(sp)
ffffffffc0200b5e:	ec0e                	sd	gp,24(sp)
ffffffffc0200b60:	f012                	sd	tp,32(sp)
ffffffffc0200b62:	f416                	sd	t0,40(sp)
ffffffffc0200b64:	f81a                	sd	t1,48(sp)
ffffffffc0200b66:	fc1e                	sd	t2,56(sp)
ffffffffc0200b68:	e0a2                	sd	s0,64(sp)
ffffffffc0200b6a:	e4a6                	sd	s1,72(sp)
ffffffffc0200b6c:	e8aa                	sd	a0,80(sp)
ffffffffc0200b6e:	ecae                	sd	a1,88(sp)
ffffffffc0200b70:	f0b2                	sd	a2,96(sp)
ffffffffc0200b72:	f4b6                	sd	a3,104(sp)
ffffffffc0200b74:	f8ba                	sd	a4,112(sp)
ffffffffc0200b76:	fcbe                	sd	a5,120(sp)
ffffffffc0200b78:	e142                	sd	a6,128(sp)
ffffffffc0200b7a:	e546                	sd	a7,136(sp)
ffffffffc0200b7c:	e94a                	sd	s2,144(sp)
ffffffffc0200b7e:	ed4e                	sd	s3,152(sp)
ffffffffc0200b80:	f152                	sd	s4,160(sp)
ffffffffc0200b82:	f556                	sd	s5,168(sp)
ffffffffc0200b84:	f95a                	sd	s6,176(sp)
ffffffffc0200b86:	fd5e                	sd	s7,184(sp)
ffffffffc0200b88:	e1e2                	sd	s8,192(sp)
ffffffffc0200b8a:	e5e6                	sd	s9,200(sp)
ffffffffc0200b8c:	e9ea                	sd	s10,208(sp)
ffffffffc0200b8e:	edee                	sd	s11,216(sp)
ffffffffc0200b90:	f1f2                	sd	t3,224(sp)
ffffffffc0200b92:	f5f6                	sd	t4,232(sp)
ffffffffc0200b94:	f9fa                	sd	t5,240(sp)
ffffffffc0200b96:	fdfe                	sd	t6,248(sp)
ffffffffc0200b98:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200b9c:	100024f3          	csrr	s1,sstatus
ffffffffc0200ba0:	14102973          	csrr	s2,sepc
ffffffffc0200ba4:	143029f3          	csrr	s3,stval
ffffffffc0200ba8:	14202a73          	csrr	s4,scause
ffffffffc0200bac:	e822                	sd	s0,16(sp)
ffffffffc0200bae:	e226                	sd	s1,256(sp)
ffffffffc0200bb0:	e64a                	sd	s2,264(sp)
ffffffffc0200bb2:	ea4e                	sd	s3,272(sp)
ffffffffc0200bb4:	ee52                	sd	s4,280(sp)
ffffffffc0200bb6:	850a                	mv	a0,sp
ffffffffc0200bb8:	f8fff0ef          	jal	ffffffffc0200b46 <trap>
ffffffffc0200bbc:	a009                	j	ffffffffc0200bbe <__trapret>

ffffffffc0200bbe <__trapret>:
ffffffffc0200bbe:	6292                	ld	t0,256(sp)
ffffffffc0200bc0:	10029073          	csrw	sstatus,t0
ffffffffc0200bc4:	62b2                	ld	t0,264(sp)
ffffffffc0200bc6:	14129073          	csrw	sepc,t0
ffffffffc0200bca:	60a2                	ld	ra,8(sp)
ffffffffc0200bcc:	61e2                	ld	gp,24(sp)
ffffffffc0200bce:	7202                	ld	tp,32(sp)
ffffffffc0200bd0:	72a2                	ld	t0,40(sp)
ffffffffc0200bd2:	7342                	ld	t1,48(sp)
ffffffffc0200bd4:	73e2                	ld	t2,56(sp)
ffffffffc0200bd6:	6406                	ld	s0,64(sp)
ffffffffc0200bd8:	64a6                	ld	s1,72(sp)
ffffffffc0200bda:	6546                	ld	a0,80(sp)
ffffffffc0200bdc:	65e6                	ld	a1,88(sp)
ffffffffc0200bde:	7606                	ld	a2,96(sp)
ffffffffc0200be0:	76a6                	ld	a3,104(sp)
ffffffffc0200be2:	7746                	ld	a4,112(sp)
ffffffffc0200be4:	77e6                	ld	a5,120(sp)
ffffffffc0200be6:	680a                	ld	a6,128(sp)
ffffffffc0200be8:	68aa                	ld	a7,136(sp)
ffffffffc0200bea:	694a                	ld	s2,144(sp)
ffffffffc0200bec:	69ea                	ld	s3,152(sp)
ffffffffc0200bee:	7a0a                	ld	s4,160(sp)
ffffffffc0200bf0:	7aaa                	ld	s5,168(sp)
ffffffffc0200bf2:	7b4a                	ld	s6,176(sp)
ffffffffc0200bf4:	7bea                	ld	s7,184(sp)
ffffffffc0200bf6:	6c0e                	ld	s8,192(sp)
ffffffffc0200bf8:	6cae                	ld	s9,200(sp)
ffffffffc0200bfa:	6d4e                	ld	s10,208(sp)
ffffffffc0200bfc:	6dee                	ld	s11,216(sp)
ffffffffc0200bfe:	7e0e                	ld	t3,224(sp)
ffffffffc0200c00:	7eae                	ld	t4,232(sp)
ffffffffc0200c02:	7f4e                	ld	t5,240(sp)
ffffffffc0200c04:	7fee                	ld	t6,248(sp)
ffffffffc0200c06:	6142                	ld	sp,16(sp)
ffffffffc0200c08:	10200073          	sret
ffffffffc0200c0c:	0001                	nop

ffffffffc0200c0e <best_fit_init>:
ffffffffc0200c0e:	00005797          	auipc	a5,0x5
ffffffffc0200c12:	41a78793          	addi	a5,a5,1050 # ffffffffc0206028 <free_area>
ffffffffc0200c16:	e79c                	sd	a5,8(a5)
ffffffffc0200c18:	e39c                	sd	a5,0(a5)
ffffffffc0200c1a:	0007a823          	sw	zero,16(a5)
ffffffffc0200c1e:	8082                	ret

ffffffffc0200c20 <best_fit_nr_free_pages>:
ffffffffc0200c20:	00005517          	auipc	a0,0x5
ffffffffc0200c24:	41856503          	lwu	a0,1048(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200c28:	8082                	ret

ffffffffc0200c2a <best_fit_check>:
ffffffffc0200c2a:	711d                	addi	sp,sp,-96
ffffffffc0200c2c:	e0ca                	sd	s2,64(sp)
ffffffffc0200c2e:	00005917          	auipc	s2,0x5
ffffffffc0200c32:	3fa90913          	addi	s2,s2,1018 # ffffffffc0206028 <free_area>
ffffffffc0200c36:	00893783          	ld	a5,8(s2)
ffffffffc0200c3a:	ec86                	sd	ra,88(sp)
ffffffffc0200c3c:	e8a2                	sd	s0,80(sp)
ffffffffc0200c3e:	e4a6                	sd	s1,72(sp)
ffffffffc0200c40:	fc4e                	sd	s3,56(sp)
ffffffffc0200c42:	f852                	sd	s4,48(sp)
ffffffffc0200c44:	f456                	sd	s5,40(sp)
ffffffffc0200c46:	f05a                	sd	s6,32(sp)
ffffffffc0200c48:	ec5e                	sd	s7,24(sp)
ffffffffc0200c4a:	e862                	sd	s8,16(sp)
ffffffffc0200c4c:	e466                	sd	s9,8(sp)
ffffffffc0200c4e:	2d278463          	beq	a5,s2,ffffffffc0200f16 <best_fit_check+0x2ec>
ffffffffc0200c52:	4401                	li	s0,0
ffffffffc0200c54:	4481                	li	s1,0
ffffffffc0200c56:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200c5a:	8b09                	andi	a4,a4,2
ffffffffc0200c5c:	2c070163          	beqz	a4,ffffffffc0200f1e <best_fit_check+0x2f4>
ffffffffc0200c60:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c64:	679c                	ld	a5,8(a5)
ffffffffc0200c66:	2485                	addiw	s1,s1,1
ffffffffc0200c68:	9c39                	addw	s0,s0,a4
ffffffffc0200c6a:	ff2796e3          	bne	a5,s2,ffffffffc0200c56 <best_fit_check+0x2c>
ffffffffc0200c6e:	89a2                	mv	s3,s0
ffffffffc0200c70:	265000ef          	jal	ffffffffc02016d4 <nr_free_pages>
ffffffffc0200c74:	39351563          	bne	a0,s3,ffffffffc0200ffe <best_fit_check+0x3d4>
ffffffffc0200c78:	4505                	li	a0,1
ffffffffc0200c7a:	243000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200c7e:	8aaa                	mv	s5,a0
ffffffffc0200c80:	3a050f63          	beqz	a0,ffffffffc020103e <best_fit_check+0x414>
ffffffffc0200c84:	4505                	li	a0,1
ffffffffc0200c86:	237000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200c8a:	89aa                	mv	s3,a0
ffffffffc0200c8c:	38050963          	beqz	a0,ffffffffc020101e <best_fit_check+0x3f4>
ffffffffc0200c90:	4505                	li	a0,1
ffffffffc0200c92:	22b000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200c96:	8a2a                	mv	s4,a0
ffffffffc0200c98:	32050363          	beqz	a0,ffffffffc0200fbe <best_fit_check+0x394>
ffffffffc0200c9c:	40aa8733          	sub	a4,s5,a0
ffffffffc0200ca0:	40a986b3          	sub	a3,s3,a0
ffffffffc0200ca4:	00173713          	seqz	a4,a4
ffffffffc0200ca8:	0016b693          	seqz	a3,a3
ffffffffc0200cac:	413a87b3          	sub	a5,s5,s3
ffffffffc0200cb0:	8f55                	or	a4,a4,a3
ffffffffc0200cb2:	0017b793          	seqz	a5,a5
ffffffffc0200cb6:	8fd9                	or	a5,a5,a4
ffffffffc0200cb8:	2e079363          	bnez	a5,ffffffffc0200f9e <best_fit_check+0x374>
ffffffffc0200cbc:	000aa783          	lw	a5,0(s5)
ffffffffc0200cc0:	26079f63          	bnez	a5,ffffffffc0200f3e <best_fit_check+0x314>
ffffffffc0200cc4:	0009a783          	lw	a5,0(s3)
ffffffffc0200cc8:	26079b63          	bnez	a5,ffffffffc0200f3e <best_fit_check+0x314>
ffffffffc0200ccc:	411c                	lw	a5,0(a0)
ffffffffc0200cce:	26079863          	bnez	a5,ffffffffc0200f3e <best_fit_check+0x314>
ffffffffc0200cd2:	00005797          	auipc	a5,0x5
ffffffffc0200cd6:	7b67b783          	ld	a5,1974(a5) # ffffffffc0206488 <pages>
ffffffffc0200cda:	ccccd737          	lui	a4,0xccccd
ffffffffc0200cde:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac6835>
ffffffffc0200ce2:	02071613          	slli	a2,a4,0x20
ffffffffc0200ce6:	963a                	add	a2,a2,a4
ffffffffc0200ce8:	40fa8733          	sub	a4,s5,a5
ffffffffc0200cec:	870d                	srai	a4,a4,0x3
ffffffffc0200cee:	02c70733          	mul	a4,a4,a2
ffffffffc0200cf2:	00002597          	auipc	a1,0x2
ffffffffc0200cf6:	27e5b583          	ld	a1,638(a1) # ffffffffc0202f70 <nbase>
ffffffffc0200cfa:	00005697          	auipc	a3,0x5
ffffffffc0200cfe:	7866b683          	ld	a3,1926(a3) # ffffffffc0206480 <npage>
ffffffffc0200d02:	06b2                	slli	a3,a3,0xc
ffffffffc0200d04:	972e                	add	a4,a4,a1
ffffffffc0200d06:	0732                	slli	a4,a4,0xc
ffffffffc0200d08:	26d77b63          	bgeu	a4,a3,ffffffffc0200f7e <best_fit_check+0x354>
ffffffffc0200d0c:	40f98733          	sub	a4,s3,a5
ffffffffc0200d10:	870d                	srai	a4,a4,0x3
ffffffffc0200d12:	02c70733          	mul	a4,a4,a2
ffffffffc0200d16:	972e                	add	a4,a4,a1
ffffffffc0200d18:	0732                	slli	a4,a4,0xc
ffffffffc0200d1a:	42d77263          	bgeu	a4,a3,ffffffffc020113e <best_fit_check+0x514>
ffffffffc0200d1e:	ccccd737          	lui	a4,0xccccd
ffffffffc0200d22:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac6835>
ffffffffc0200d26:	40f507b3          	sub	a5,a0,a5
ffffffffc0200d2a:	02071613          	slli	a2,a4,0x20
ffffffffc0200d2e:	878d                	srai	a5,a5,0x3
ffffffffc0200d30:	9732                	add	a4,a4,a2
ffffffffc0200d32:	02e787b3          	mul	a5,a5,a4
ffffffffc0200d36:	97ae                	add	a5,a5,a1
ffffffffc0200d38:	07b2                	slli	a5,a5,0xc
ffffffffc0200d3a:	3ed7f263          	bgeu	a5,a3,ffffffffc020111e <best_fit_check+0x4f4>
ffffffffc0200d3e:	4505                	li	a0,1
ffffffffc0200d40:	00093c03          	ld	s8,0(s2)
ffffffffc0200d44:	00893b83          	ld	s7,8(s2)
ffffffffc0200d48:	00005b17          	auipc	s6,0x5
ffffffffc0200d4c:	2f0b2b03          	lw	s6,752(s6) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200d50:	01293023          	sd	s2,0(s2)
ffffffffc0200d54:	01293423          	sd	s2,8(s2)
ffffffffc0200d58:	00005797          	auipc	a5,0x5
ffffffffc0200d5c:	2e07a023          	sw	zero,736(a5) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200d60:	15d000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200d64:	38051d63          	bnez	a0,ffffffffc02010fe <best_fit_check+0x4d4>
ffffffffc0200d68:	8556                	mv	a0,s5
ffffffffc0200d6a:	4585                	li	a1,1
ffffffffc0200d6c:	15d000ef          	jal	ffffffffc02016c8 <free_pages>
ffffffffc0200d70:	854e                	mv	a0,s3
ffffffffc0200d72:	4585                	li	a1,1
ffffffffc0200d74:	155000ef          	jal	ffffffffc02016c8 <free_pages>
ffffffffc0200d78:	8552                	mv	a0,s4
ffffffffc0200d7a:	4585                	li	a1,1
ffffffffc0200d7c:	14d000ef          	jal	ffffffffc02016c8 <free_pages>
ffffffffc0200d80:	00005717          	auipc	a4,0x5
ffffffffc0200d84:	2b872703          	lw	a4,696(a4) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200d88:	478d                	li	a5,3
ffffffffc0200d8a:	34f71a63          	bne	a4,a5,ffffffffc02010de <best_fit_check+0x4b4>
ffffffffc0200d8e:	4505                	li	a0,1
ffffffffc0200d90:	12d000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200d94:	89aa                	mv	s3,a0
ffffffffc0200d96:	32050463          	beqz	a0,ffffffffc02010be <best_fit_check+0x494>
ffffffffc0200d9a:	4505                	li	a0,1
ffffffffc0200d9c:	121000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200da0:	8aaa                	mv	s5,a0
ffffffffc0200da2:	2e050e63          	beqz	a0,ffffffffc020109e <best_fit_check+0x474>
ffffffffc0200da6:	4505                	li	a0,1
ffffffffc0200da8:	115000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200dac:	8a2a                	mv	s4,a0
ffffffffc0200dae:	2c050863          	beqz	a0,ffffffffc020107e <best_fit_check+0x454>
ffffffffc0200db2:	4505                	li	a0,1
ffffffffc0200db4:	109000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200db8:	2a051363          	bnez	a0,ffffffffc020105e <best_fit_check+0x434>
ffffffffc0200dbc:	4585                	li	a1,1
ffffffffc0200dbe:	854e                	mv	a0,s3
ffffffffc0200dc0:	109000ef          	jal	ffffffffc02016c8 <free_pages>
ffffffffc0200dc4:	00893783          	ld	a5,8(s2)
ffffffffc0200dc8:	19278b63          	beq	a5,s2,ffffffffc0200f5e <best_fit_check+0x334>
ffffffffc0200dcc:	4505                	li	a0,1
ffffffffc0200dce:	0ef000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200dd2:	8caa                	mv	s9,a0
ffffffffc0200dd4:	54a99563          	bne	s3,a0,ffffffffc020131e <best_fit_check+0x6f4>
ffffffffc0200dd8:	4505                	li	a0,1
ffffffffc0200dda:	0e3000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200dde:	52051063          	bnez	a0,ffffffffc02012fe <best_fit_check+0x6d4>
ffffffffc0200de2:	00005797          	auipc	a5,0x5
ffffffffc0200de6:	2567a783          	lw	a5,598(a5) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200dea:	4e079a63          	bnez	a5,ffffffffc02012de <best_fit_check+0x6b4>
ffffffffc0200dee:	8566                	mv	a0,s9
ffffffffc0200df0:	4585                	li	a1,1
ffffffffc0200df2:	01893023          	sd	s8,0(s2)
ffffffffc0200df6:	01793423          	sd	s7,8(s2)
ffffffffc0200dfa:	01692823          	sw	s6,16(s2)
ffffffffc0200dfe:	0cb000ef          	jal	ffffffffc02016c8 <free_pages>
ffffffffc0200e02:	8556                	mv	a0,s5
ffffffffc0200e04:	4585                	li	a1,1
ffffffffc0200e06:	0c3000ef          	jal	ffffffffc02016c8 <free_pages>
ffffffffc0200e0a:	8552                	mv	a0,s4
ffffffffc0200e0c:	4585                	li	a1,1
ffffffffc0200e0e:	0bb000ef          	jal	ffffffffc02016c8 <free_pages>
ffffffffc0200e12:	4515                	li	a0,5
ffffffffc0200e14:	0a9000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200e18:	89aa                	mv	s3,a0
ffffffffc0200e1a:	4a050263          	beqz	a0,ffffffffc02012be <best_fit_check+0x694>
ffffffffc0200e1e:	651c                	ld	a5,8(a0)
ffffffffc0200e20:	8385                	srli	a5,a5,0x1
ffffffffc0200e22:	8b85                	andi	a5,a5,1
ffffffffc0200e24:	46079d63          	bnez	a5,ffffffffc020129e <best_fit_check+0x674>
ffffffffc0200e28:	4505                	li	a0,1
ffffffffc0200e2a:	00093b03          	ld	s6,0(s2)
ffffffffc0200e2e:	00893a83          	ld	s5,8(s2)
ffffffffc0200e32:	01293023          	sd	s2,0(s2)
ffffffffc0200e36:	01293423          	sd	s2,8(s2)
ffffffffc0200e3a:	083000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200e3e:	44051063          	bnez	a0,ffffffffc020127e <best_fit_check+0x654>
ffffffffc0200e42:	4589                	li	a1,2
ffffffffc0200e44:	02898513          	addi	a0,s3,40
ffffffffc0200e48:	00005b97          	auipc	s7,0x5
ffffffffc0200e4c:	1f0bab83          	lw	s7,496(s7) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200e50:	0a098c13          	addi	s8,s3,160
ffffffffc0200e54:	00005797          	auipc	a5,0x5
ffffffffc0200e58:	1e07a223          	sw	zero,484(a5) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200e5c:	06d000ef          	jal	ffffffffc02016c8 <free_pages>
ffffffffc0200e60:	8562                	mv	a0,s8
ffffffffc0200e62:	4585                	li	a1,1
ffffffffc0200e64:	065000ef          	jal	ffffffffc02016c8 <free_pages>
ffffffffc0200e68:	4511                	li	a0,4
ffffffffc0200e6a:	053000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200e6e:	3e051863          	bnez	a0,ffffffffc020125e <best_fit_check+0x634>
ffffffffc0200e72:	0309b783          	ld	a5,48(s3)
ffffffffc0200e76:	8385                	srli	a5,a5,0x1
ffffffffc0200e78:	8b85                	andi	a5,a5,1
ffffffffc0200e7a:	3c078263          	beqz	a5,ffffffffc020123e <best_fit_check+0x614>
ffffffffc0200e7e:	0389ac83          	lw	s9,56(s3)
ffffffffc0200e82:	4789                	li	a5,2
ffffffffc0200e84:	3afc9d63          	bne	s9,a5,ffffffffc020123e <best_fit_check+0x614>
ffffffffc0200e88:	4505                	li	a0,1
ffffffffc0200e8a:	033000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200e8e:	8a2a                	mv	s4,a0
ffffffffc0200e90:	38050763          	beqz	a0,ffffffffc020121e <best_fit_check+0x5f4>
ffffffffc0200e94:	8566                	mv	a0,s9
ffffffffc0200e96:	027000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200e9a:	36050263          	beqz	a0,ffffffffc02011fe <best_fit_check+0x5d4>
ffffffffc0200e9e:	354c1063          	bne	s8,s4,ffffffffc02011de <best_fit_check+0x5b4>
ffffffffc0200ea2:	854e                	mv	a0,s3
ffffffffc0200ea4:	4595                	li	a1,5
ffffffffc0200ea6:	023000ef          	jal	ffffffffc02016c8 <free_pages>
ffffffffc0200eaa:	4515                	li	a0,5
ffffffffc0200eac:	011000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200eb0:	89aa                	mv	s3,a0
ffffffffc0200eb2:	30050663          	beqz	a0,ffffffffc02011be <best_fit_check+0x594>
ffffffffc0200eb6:	4505                	li	a0,1
ffffffffc0200eb8:	005000ef          	jal	ffffffffc02016bc <alloc_pages>
ffffffffc0200ebc:	2e051163          	bnez	a0,ffffffffc020119e <best_fit_check+0x574>
ffffffffc0200ec0:	00005797          	auipc	a5,0x5
ffffffffc0200ec4:	1787a783          	lw	a5,376(a5) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200ec8:	2a079b63          	bnez	a5,ffffffffc020117e <best_fit_check+0x554>
ffffffffc0200ecc:	854e                	mv	a0,s3
ffffffffc0200ece:	4595                	li	a1,5
ffffffffc0200ed0:	01792823          	sw	s7,16(s2)
ffffffffc0200ed4:	01693023          	sd	s6,0(s2)
ffffffffc0200ed8:	01593423          	sd	s5,8(s2)
ffffffffc0200edc:	7ec000ef          	jal	ffffffffc02016c8 <free_pages>
ffffffffc0200ee0:	00893783          	ld	a5,8(s2)
ffffffffc0200ee4:	01278963          	beq	a5,s2,ffffffffc0200ef6 <best_fit_check+0x2cc>
ffffffffc0200ee8:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200eec:	679c                	ld	a5,8(a5)
ffffffffc0200eee:	34fd                	addiw	s1,s1,-1
ffffffffc0200ef0:	9c19                	subw	s0,s0,a4
ffffffffc0200ef2:	ff279be3          	bne	a5,s2,ffffffffc0200ee8 <best_fit_check+0x2be>
ffffffffc0200ef6:	26049463          	bnez	s1,ffffffffc020115e <best_fit_check+0x534>
ffffffffc0200efa:	e075                	bnez	s0,ffffffffc0200fde <best_fit_check+0x3b4>
ffffffffc0200efc:	60e6                	ld	ra,88(sp)
ffffffffc0200efe:	6446                	ld	s0,80(sp)
ffffffffc0200f00:	64a6                	ld	s1,72(sp)
ffffffffc0200f02:	6906                	ld	s2,64(sp)
ffffffffc0200f04:	79e2                	ld	s3,56(sp)
ffffffffc0200f06:	7a42                	ld	s4,48(sp)
ffffffffc0200f08:	7aa2                	ld	s5,40(sp)
ffffffffc0200f0a:	7b02                	ld	s6,32(sp)
ffffffffc0200f0c:	6be2                	ld	s7,24(sp)
ffffffffc0200f0e:	6c42                	ld	s8,16(sp)
ffffffffc0200f10:	6ca2                	ld	s9,8(sp)
ffffffffc0200f12:	6125                	addi	sp,sp,96
ffffffffc0200f14:	8082                	ret
ffffffffc0200f16:	4981                	li	s3,0
ffffffffc0200f18:	4401                	li	s0,0
ffffffffc0200f1a:	4481                	li	s1,0
ffffffffc0200f1c:	bb91                	j	ffffffffc0200c70 <best_fit_check+0x46>
ffffffffc0200f1e:	00002697          	auipc	a3,0x2
ffffffffc0200f22:	82268693          	addi	a3,a3,-2014 # ffffffffc0202740 <etext+0x850>
ffffffffc0200f26:	00002617          	auipc	a2,0x2
ffffffffc0200f2a:	82a60613          	addi	a2,a2,-2006 # ffffffffc0202750 <etext+0x860>
ffffffffc0200f2e:	0d000593          	li	a1,208
ffffffffc0200f32:	00002517          	auipc	a0,0x2
ffffffffc0200f36:	83650513          	addi	a0,a0,-1994 # ffffffffc0202768 <etext+0x878>
ffffffffc0200f3a:	c40ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc0200f3e:	00002697          	auipc	a3,0x2
ffffffffc0200f42:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0202828 <etext+0x938>
ffffffffc0200f46:	00002617          	auipc	a2,0x2
ffffffffc0200f4a:	80a60613          	addi	a2,a2,-2038 # ffffffffc0202750 <etext+0x860>
ffffffffc0200f4e:	09f00593          	li	a1,159
ffffffffc0200f52:	00002517          	auipc	a0,0x2
ffffffffc0200f56:	81650513          	addi	a0,a0,-2026 # ffffffffc0202768 <etext+0x878>
ffffffffc0200f5a:	c20ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc0200f5e:	00002697          	auipc	a3,0x2
ffffffffc0200f62:	99268693          	addi	a3,a3,-1646 # ffffffffc02028f0 <etext+0xa00>
ffffffffc0200f66:	00001617          	auipc	a2,0x1
ffffffffc0200f6a:	7ea60613          	addi	a2,a2,2026 # ffffffffc0202750 <etext+0x860>
ffffffffc0200f6e:	0ba00593          	li	a1,186
ffffffffc0200f72:	00001517          	auipc	a0,0x1
ffffffffc0200f76:	7f650513          	addi	a0,a0,2038 # ffffffffc0202768 <etext+0x878>
ffffffffc0200f7a:	c00ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc0200f7e:	00002697          	auipc	a3,0x2
ffffffffc0200f82:	8ea68693          	addi	a3,a3,-1814 # ffffffffc0202868 <etext+0x978>
ffffffffc0200f86:	00001617          	auipc	a2,0x1
ffffffffc0200f8a:	7ca60613          	addi	a2,a2,1994 # ffffffffc0202750 <etext+0x860>
ffffffffc0200f8e:	0a100593          	li	a1,161
ffffffffc0200f92:	00001517          	auipc	a0,0x1
ffffffffc0200f96:	7d650513          	addi	a0,a0,2006 # ffffffffc0202768 <etext+0x878>
ffffffffc0200f9a:	be0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc0200f9e:	00002697          	auipc	a3,0x2
ffffffffc0200fa2:	86268693          	addi	a3,a3,-1950 # ffffffffc0202800 <etext+0x910>
ffffffffc0200fa6:	00001617          	auipc	a2,0x1
ffffffffc0200faa:	7aa60613          	addi	a2,a2,1962 # ffffffffc0202750 <etext+0x860>
ffffffffc0200fae:	09e00593          	li	a1,158
ffffffffc0200fb2:	00001517          	auipc	a0,0x1
ffffffffc0200fb6:	7b650513          	addi	a0,a0,1974 # ffffffffc0202768 <etext+0x878>
ffffffffc0200fba:	bc0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc0200fbe:	00002697          	auipc	a3,0x2
ffffffffc0200fc2:	82268693          	addi	a3,a3,-2014 # ffffffffc02027e0 <etext+0x8f0>
ffffffffc0200fc6:	00001617          	auipc	a2,0x1
ffffffffc0200fca:	78a60613          	addi	a2,a2,1930 # ffffffffc0202750 <etext+0x860>
ffffffffc0200fce:	09c00593          	li	a1,156
ffffffffc0200fd2:	00001517          	auipc	a0,0x1
ffffffffc0200fd6:	79650513          	addi	a0,a0,1942 # ffffffffc0202768 <etext+0x878>
ffffffffc0200fda:	ba0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc0200fde:	00002697          	auipc	a3,0x2
ffffffffc0200fe2:	a4268693          	addi	a3,a3,-1470 # ffffffffc0202a20 <etext+0xb30>
ffffffffc0200fe6:	00001617          	auipc	a2,0x1
ffffffffc0200fea:	76a60613          	addi	a2,a2,1898 # ffffffffc0202750 <etext+0x860>
ffffffffc0200fee:	11200593          	li	a1,274
ffffffffc0200ff2:	00001517          	auipc	a0,0x1
ffffffffc0200ff6:	77650513          	addi	a0,a0,1910 # ffffffffc0202768 <etext+0x878>
ffffffffc0200ffa:	b80ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc0200ffe:	00001697          	auipc	a3,0x1
ffffffffc0201002:	78268693          	addi	a3,a3,1922 # ffffffffc0202780 <etext+0x890>
ffffffffc0201006:	00001617          	auipc	a2,0x1
ffffffffc020100a:	74a60613          	addi	a2,a2,1866 # ffffffffc0202750 <etext+0x860>
ffffffffc020100e:	0d300593          	li	a1,211
ffffffffc0201012:	00001517          	auipc	a0,0x1
ffffffffc0201016:	75650513          	addi	a0,a0,1878 # ffffffffc0202768 <etext+0x878>
ffffffffc020101a:	b60ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020101e:	00001697          	auipc	a3,0x1
ffffffffc0201022:	7a268693          	addi	a3,a3,1954 # ffffffffc02027c0 <etext+0x8d0>
ffffffffc0201026:	00001617          	auipc	a2,0x1
ffffffffc020102a:	72a60613          	addi	a2,a2,1834 # ffffffffc0202750 <etext+0x860>
ffffffffc020102e:	09b00593          	li	a1,155
ffffffffc0201032:	00001517          	auipc	a0,0x1
ffffffffc0201036:	73650513          	addi	a0,a0,1846 # ffffffffc0202768 <etext+0x878>
ffffffffc020103a:	b40ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020103e:	00001697          	auipc	a3,0x1
ffffffffc0201042:	76268693          	addi	a3,a3,1890 # ffffffffc02027a0 <etext+0x8b0>
ffffffffc0201046:	00001617          	auipc	a2,0x1
ffffffffc020104a:	70a60613          	addi	a2,a2,1802 # ffffffffc0202750 <etext+0x860>
ffffffffc020104e:	09a00593          	li	a1,154
ffffffffc0201052:	00001517          	auipc	a0,0x1
ffffffffc0201056:	71650513          	addi	a0,a0,1814 # ffffffffc0202768 <etext+0x878>
ffffffffc020105a:	b20ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020105e:	00002697          	auipc	a3,0x2
ffffffffc0201062:	86a68693          	addi	a3,a3,-1942 # ffffffffc02028c8 <etext+0x9d8>
ffffffffc0201066:	00001617          	auipc	a2,0x1
ffffffffc020106a:	6ea60613          	addi	a2,a2,1770 # ffffffffc0202750 <etext+0x860>
ffffffffc020106e:	0b700593          	li	a1,183
ffffffffc0201072:	00001517          	auipc	a0,0x1
ffffffffc0201076:	6f650513          	addi	a0,a0,1782 # ffffffffc0202768 <etext+0x878>
ffffffffc020107a:	b00ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020107e:	00001697          	auipc	a3,0x1
ffffffffc0201082:	76268693          	addi	a3,a3,1890 # ffffffffc02027e0 <etext+0x8f0>
ffffffffc0201086:	00001617          	auipc	a2,0x1
ffffffffc020108a:	6ca60613          	addi	a2,a2,1738 # ffffffffc0202750 <etext+0x860>
ffffffffc020108e:	0b500593          	li	a1,181
ffffffffc0201092:	00001517          	auipc	a0,0x1
ffffffffc0201096:	6d650513          	addi	a0,a0,1750 # ffffffffc0202768 <etext+0x878>
ffffffffc020109a:	ae0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020109e:	00001697          	auipc	a3,0x1
ffffffffc02010a2:	72268693          	addi	a3,a3,1826 # ffffffffc02027c0 <etext+0x8d0>
ffffffffc02010a6:	00001617          	auipc	a2,0x1
ffffffffc02010aa:	6aa60613          	addi	a2,a2,1706 # ffffffffc0202750 <etext+0x860>
ffffffffc02010ae:	0b400593          	li	a1,180
ffffffffc02010b2:	00001517          	auipc	a0,0x1
ffffffffc02010b6:	6b650513          	addi	a0,a0,1718 # ffffffffc0202768 <etext+0x878>
ffffffffc02010ba:	ac0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc02010be:	00001697          	auipc	a3,0x1
ffffffffc02010c2:	6e268693          	addi	a3,a3,1762 # ffffffffc02027a0 <etext+0x8b0>
ffffffffc02010c6:	00001617          	auipc	a2,0x1
ffffffffc02010ca:	68a60613          	addi	a2,a2,1674 # ffffffffc0202750 <etext+0x860>
ffffffffc02010ce:	0b300593          	li	a1,179
ffffffffc02010d2:	00001517          	auipc	a0,0x1
ffffffffc02010d6:	69650513          	addi	a0,a0,1686 # ffffffffc0202768 <etext+0x878>
ffffffffc02010da:	aa0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc02010de:	00002697          	auipc	a3,0x2
ffffffffc02010e2:	80268693          	addi	a3,a3,-2046 # ffffffffc02028e0 <etext+0x9f0>
ffffffffc02010e6:	00001617          	auipc	a2,0x1
ffffffffc02010ea:	66a60613          	addi	a2,a2,1642 # ffffffffc0202750 <etext+0x860>
ffffffffc02010ee:	0b100593          	li	a1,177
ffffffffc02010f2:	00001517          	auipc	a0,0x1
ffffffffc02010f6:	67650513          	addi	a0,a0,1654 # ffffffffc0202768 <etext+0x878>
ffffffffc02010fa:	a80ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc02010fe:	00001697          	auipc	a3,0x1
ffffffffc0201102:	7ca68693          	addi	a3,a3,1994 # ffffffffc02028c8 <etext+0x9d8>
ffffffffc0201106:	00001617          	auipc	a2,0x1
ffffffffc020110a:	64a60613          	addi	a2,a2,1610 # ffffffffc0202750 <etext+0x860>
ffffffffc020110e:	0ac00593          	li	a1,172
ffffffffc0201112:	00001517          	auipc	a0,0x1
ffffffffc0201116:	65650513          	addi	a0,a0,1622 # ffffffffc0202768 <etext+0x878>
ffffffffc020111a:	a60ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020111e:	00001697          	auipc	a3,0x1
ffffffffc0201122:	78a68693          	addi	a3,a3,1930 # ffffffffc02028a8 <etext+0x9b8>
ffffffffc0201126:	00001617          	auipc	a2,0x1
ffffffffc020112a:	62a60613          	addi	a2,a2,1578 # ffffffffc0202750 <etext+0x860>
ffffffffc020112e:	0a300593          	li	a1,163
ffffffffc0201132:	00001517          	auipc	a0,0x1
ffffffffc0201136:	63650513          	addi	a0,a0,1590 # ffffffffc0202768 <etext+0x878>
ffffffffc020113a:	a40ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020113e:	00001697          	auipc	a3,0x1
ffffffffc0201142:	74a68693          	addi	a3,a3,1866 # ffffffffc0202888 <etext+0x998>
ffffffffc0201146:	00001617          	auipc	a2,0x1
ffffffffc020114a:	60a60613          	addi	a2,a2,1546 # ffffffffc0202750 <etext+0x860>
ffffffffc020114e:	0a200593          	li	a1,162
ffffffffc0201152:	00001517          	auipc	a0,0x1
ffffffffc0201156:	61650513          	addi	a0,a0,1558 # ffffffffc0202768 <etext+0x878>
ffffffffc020115a:	a20ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020115e:	00002697          	auipc	a3,0x2
ffffffffc0201162:	8b268693          	addi	a3,a3,-1870 # ffffffffc0202a10 <etext+0xb20>
ffffffffc0201166:	00001617          	auipc	a2,0x1
ffffffffc020116a:	5ea60613          	addi	a2,a2,1514 # ffffffffc0202750 <etext+0x860>
ffffffffc020116e:	11100593          	li	a1,273
ffffffffc0201172:	00001517          	auipc	a0,0x1
ffffffffc0201176:	5f650513          	addi	a0,a0,1526 # ffffffffc0202768 <etext+0x878>
ffffffffc020117a:	a00ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020117e:	00001697          	auipc	a3,0x1
ffffffffc0201182:	7aa68693          	addi	a3,a3,1962 # ffffffffc0202928 <etext+0xa38>
ffffffffc0201186:	00001617          	auipc	a2,0x1
ffffffffc020118a:	5ca60613          	addi	a2,a2,1482 # ffffffffc0202750 <etext+0x860>
ffffffffc020118e:	10600593          	li	a1,262
ffffffffc0201192:	00001517          	auipc	a0,0x1
ffffffffc0201196:	5d650513          	addi	a0,a0,1494 # ffffffffc0202768 <etext+0x878>
ffffffffc020119a:	9e0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020119e:	00001697          	auipc	a3,0x1
ffffffffc02011a2:	72a68693          	addi	a3,a3,1834 # ffffffffc02028c8 <etext+0x9d8>
ffffffffc02011a6:	00001617          	auipc	a2,0x1
ffffffffc02011aa:	5aa60613          	addi	a2,a2,1450 # ffffffffc0202750 <etext+0x860>
ffffffffc02011ae:	10000593          	li	a1,256
ffffffffc02011b2:	00001517          	auipc	a0,0x1
ffffffffc02011b6:	5b650513          	addi	a0,a0,1462 # ffffffffc0202768 <etext+0x878>
ffffffffc02011ba:	9c0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc02011be:	00002697          	auipc	a3,0x2
ffffffffc02011c2:	83268693          	addi	a3,a3,-1998 # ffffffffc02029f0 <etext+0xb00>
ffffffffc02011c6:	00001617          	auipc	a2,0x1
ffffffffc02011ca:	58a60613          	addi	a2,a2,1418 # ffffffffc0202750 <etext+0x860>
ffffffffc02011ce:	0ff00593          	li	a1,255
ffffffffc02011d2:	00001517          	auipc	a0,0x1
ffffffffc02011d6:	59650513          	addi	a0,a0,1430 # ffffffffc0202768 <etext+0x878>
ffffffffc02011da:	9a0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc02011de:	00002697          	auipc	a3,0x2
ffffffffc02011e2:	80268693          	addi	a3,a3,-2046 # ffffffffc02029e0 <etext+0xaf0>
ffffffffc02011e6:	00001617          	auipc	a2,0x1
ffffffffc02011ea:	56a60613          	addi	a2,a2,1386 # ffffffffc0202750 <etext+0x860>
ffffffffc02011ee:	0f700593          	li	a1,247
ffffffffc02011f2:	00001517          	auipc	a0,0x1
ffffffffc02011f6:	57650513          	addi	a0,a0,1398 # ffffffffc0202768 <etext+0x878>
ffffffffc02011fa:	980ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc02011fe:	00001697          	auipc	a3,0x1
ffffffffc0201202:	7ca68693          	addi	a3,a3,1994 # ffffffffc02029c8 <etext+0xad8>
ffffffffc0201206:	00001617          	auipc	a2,0x1
ffffffffc020120a:	54a60613          	addi	a2,a2,1354 # ffffffffc0202750 <etext+0x860>
ffffffffc020120e:	0f600593          	li	a1,246
ffffffffc0201212:	00001517          	auipc	a0,0x1
ffffffffc0201216:	55650513          	addi	a0,a0,1366 # ffffffffc0202768 <etext+0x878>
ffffffffc020121a:	960ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020121e:	00001697          	auipc	a3,0x1
ffffffffc0201222:	78a68693          	addi	a3,a3,1930 # ffffffffc02029a8 <etext+0xab8>
ffffffffc0201226:	00001617          	auipc	a2,0x1
ffffffffc020122a:	52a60613          	addi	a2,a2,1322 # ffffffffc0202750 <etext+0x860>
ffffffffc020122e:	0f500593          	li	a1,245
ffffffffc0201232:	00001517          	auipc	a0,0x1
ffffffffc0201236:	53650513          	addi	a0,a0,1334 # ffffffffc0202768 <etext+0x878>
ffffffffc020123a:	940ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020123e:	00001697          	auipc	a3,0x1
ffffffffc0201242:	73a68693          	addi	a3,a3,1850 # ffffffffc0202978 <etext+0xa88>
ffffffffc0201246:	00001617          	auipc	a2,0x1
ffffffffc020124a:	50a60613          	addi	a2,a2,1290 # ffffffffc0202750 <etext+0x860>
ffffffffc020124e:	0f300593          	li	a1,243
ffffffffc0201252:	00001517          	auipc	a0,0x1
ffffffffc0201256:	51650513          	addi	a0,a0,1302 # ffffffffc0202768 <etext+0x878>
ffffffffc020125a:	920ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020125e:	00001697          	auipc	a3,0x1
ffffffffc0201262:	70268693          	addi	a3,a3,1794 # ffffffffc0202960 <etext+0xa70>
ffffffffc0201266:	00001617          	auipc	a2,0x1
ffffffffc020126a:	4ea60613          	addi	a2,a2,1258 # ffffffffc0202750 <etext+0x860>
ffffffffc020126e:	0f200593          	li	a1,242
ffffffffc0201272:	00001517          	auipc	a0,0x1
ffffffffc0201276:	4f650513          	addi	a0,a0,1270 # ffffffffc0202768 <etext+0x878>
ffffffffc020127a:	900ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020127e:	00001697          	auipc	a3,0x1
ffffffffc0201282:	64a68693          	addi	a3,a3,1610 # ffffffffc02028c8 <etext+0x9d8>
ffffffffc0201286:	00001617          	auipc	a2,0x1
ffffffffc020128a:	4ca60613          	addi	a2,a2,1226 # ffffffffc0202750 <etext+0x860>
ffffffffc020128e:	0e600593          	li	a1,230
ffffffffc0201292:	00001517          	auipc	a0,0x1
ffffffffc0201296:	4d650513          	addi	a0,a0,1238 # ffffffffc0202768 <etext+0x878>
ffffffffc020129a:	8e0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020129e:	00001697          	auipc	a3,0x1
ffffffffc02012a2:	6aa68693          	addi	a3,a3,1706 # ffffffffc0202948 <etext+0xa58>
ffffffffc02012a6:	00001617          	auipc	a2,0x1
ffffffffc02012aa:	4aa60613          	addi	a2,a2,1194 # ffffffffc0202750 <etext+0x860>
ffffffffc02012ae:	0dd00593          	li	a1,221
ffffffffc02012b2:	00001517          	auipc	a0,0x1
ffffffffc02012b6:	4b650513          	addi	a0,a0,1206 # ffffffffc0202768 <etext+0x878>
ffffffffc02012ba:	8c0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc02012be:	00001697          	auipc	a3,0x1
ffffffffc02012c2:	67a68693          	addi	a3,a3,1658 # ffffffffc0202938 <etext+0xa48>
ffffffffc02012c6:	00001617          	auipc	a2,0x1
ffffffffc02012ca:	48a60613          	addi	a2,a2,1162 # ffffffffc0202750 <etext+0x860>
ffffffffc02012ce:	0dc00593          	li	a1,220
ffffffffc02012d2:	00001517          	auipc	a0,0x1
ffffffffc02012d6:	49650513          	addi	a0,a0,1174 # ffffffffc0202768 <etext+0x878>
ffffffffc02012da:	8a0ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc02012de:	00001697          	auipc	a3,0x1
ffffffffc02012e2:	64a68693          	addi	a3,a3,1610 # ffffffffc0202928 <etext+0xa38>
ffffffffc02012e6:	00001617          	auipc	a2,0x1
ffffffffc02012ea:	46a60613          	addi	a2,a2,1130 # ffffffffc0202750 <etext+0x860>
ffffffffc02012ee:	0c000593          	li	a1,192
ffffffffc02012f2:	00001517          	auipc	a0,0x1
ffffffffc02012f6:	47650513          	addi	a0,a0,1142 # ffffffffc0202768 <etext+0x878>
ffffffffc02012fa:	880ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc02012fe:	00001697          	auipc	a3,0x1
ffffffffc0201302:	5ca68693          	addi	a3,a3,1482 # ffffffffc02028c8 <etext+0x9d8>
ffffffffc0201306:	00001617          	auipc	a2,0x1
ffffffffc020130a:	44a60613          	addi	a2,a2,1098 # ffffffffc0202750 <etext+0x860>
ffffffffc020130e:	0be00593          	li	a1,190
ffffffffc0201312:	00001517          	auipc	a0,0x1
ffffffffc0201316:	45650513          	addi	a0,a0,1110 # ffffffffc0202768 <etext+0x878>
ffffffffc020131a:	860ff0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020131e:	00001697          	auipc	a3,0x1
ffffffffc0201322:	5ea68693          	addi	a3,a3,1514 # ffffffffc0202908 <etext+0xa18>
ffffffffc0201326:	00001617          	auipc	a2,0x1
ffffffffc020132a:	42a60613          	addi	a2,a2,1066 # ffffffffc0202750 <etext+0x860>
ffffffffc020132e:	0bd00593          	li	a1,189
ffffffffc0201332:	00001517          	auipc	a0,0x1
ffffffffc0201336:	43650513          	addi	a0,a0,1078 # ffffffffc0202768 <etext+0x878>
ffffffffc020133a:	840ff0ef          	jal	ffffffffc020037a <__panic>

ffffffffc020133e <best_fit_free_pages>:
ffffffffc020133e:	1141                	addi	sp,sp,-16
ffffffffc0201340:	e406                	sd	ra,8(sp)
ffffffffc0201342:	14058a63          	beqz	a1,ffffffffc0201496 <best_fit_free_pages+0x158>
ffffffffc0201346:	00259713          	slli	a4,a1,0x2
ffffffffc020134a:	972e                	add	a4,a4,a1
ffffffffc020134c:	070e                	slli	a4,a4,0x3
ffffffffc020134e:	00e506b3          	add	a3,a0,a4
ffffffffc0201352:	87aa                	mv	a5,a0
ffffffffc0201354:	c30d                	beqz	a4,ffffffffc0201376 <best_fit_free_pages+0x38>
ffffffffc0201356:	6798                	ld	a4,8(a5)
ffffffffc0201358:	8b05                	andi	a4,a4,1
ffffffffc020135a:	10071e63          	bnez	a4,ffffffffc0201476 <best_fit_free_pages+0x138>
ffffffffc020135e:	6798                	ld	a4,8(a5)
ffffffffc0201360:	8b09                	andi	a4,a4,2
ffffffffc0201362:	10071a63          	bnez	a4,ffffffffc0201476 <best_fit_free_pages+0x138>
ffffffffc0201366:	0007b423          	sd	zero,8(a5)
ffffffffc020136a:	0007a023          	sw	zero,0(a5)
ffffffffc020136e:	02878793          	addi	a5,a5,40
ffffffffc0201372:	fed792e3          	bne	a5,a3,ffffffffc0201356 <best_fit_free_pages+0x18>
ffffffffc0201376:	c90c                	sw	a1,16(a0)
ffffffffc0201378:	00850893          	addi	a7,a0,8
ffffffffc020137c:	4789                	li	a5,2
ffffffffc020137e:	40f8b02f          	amoor.d	zero,a5,(a7)
ffffffffc0201382:	00005717          	auipc	a4,0x5
ffffffffc0201386:	cb672703          	lw	a4,-842(a4) # ffffffffc0206038 <free_area+0x10>
ffffffffc020138a:	00005697          	auipc	a3,0x5
ffffffffc020138e:	c9e68693          	addi	a3,a3,-866 # ffffffffc0206028 <free_area>
ffffffffc0201392:	669c                	ld	a5,8(a3)
ffffffffc0201394:	9f2d                	addw	a4,a4,a1
ffffffffc0201396:	ca98                	sw	a4,16(a3)
ffffffffc0201398:	01850613          	addi	a2,a0,24
ffffffffc020139c:	4581                	li	a1,0
ffffffffc020139e:	0ad78263          	beq	a5,a3,ffffffffc0201442 <best_fit_free_pages+0x104>
ffffffffc02013a2:	fe878713          	addi	a4,a5,-24
ffffffffc02013a6:	00e56a63          	bltu	a0,a4,ffffffffc02013ba <best_fit_free_pages+0x7c>
ffffffffc02013aa:	6798                	ld	a4,8(a5)
ffffffffc02013ac:	06d70263          	beq	a4,a3,ffffffffc0201410 <best_fit_free_pages+0xd2>
ffffffffc02013b0:	87ba                	mv	a5,a4
ffffffffc02013b2:	fe878713          	addi	a4,a5,-24
ffffffffc02013b6:	fee57ae3          	bgeu	a0,a4,ffffffffc02013aa <best_fit_free_pages+0x6c>
ffffffffc02013ba:	c199                	beqz	a1,ffffffffc02013c0 <best_fit_free_pages+0x82>
ffffffffc02013bc:	0106b023          	sd	a6,0(a3)
ffffffffc02013c0:	6398                	ld	a4,0(a5)
ffffffffc02013c2:	e390                	sd	a2,0(a5)
ffffffffc02013c4:	e710                	sd	a2,8(a4)
ffffffffc02013c6:	ed18                	sd	a4,24(a0)
ffffffffc02013c8:	f11c                	sd	a5,32(a0)
ffffffffc02013ca:	02d70063          	beq	a4,a3,ffffffffc02013ea <best_fit_free_pages+0xac>
ffffffffc02013ce:	ff872803          	lw	a6,-8(a4)
ffffffffc02013d2:	fe870593          	addi	a1,a4,-24
ffffffffc02013d6:	02081613          	slli	a2,a6,0x20
ffffffffc02013da:	9201                	srli	a2,a2,0x20
ffffffffc02013dc:	00261793          	slli	a5,a2,0x2
ffffffffc02013e0:	97b2                	add	a5,a5,a2
ffffffffc02013e2:	078e                	slli	a5,a5,0x3
ffffffffc02013e4:	97ae                	add	a5,a5,a1
ffffffffc02013e6:	02f50f63          	beq	a0,a5,ffffffffc0201424 <best_fit_free_pages+0xe6>
ffffffffc02013ea:	7118                	ld	a4,32(a0)
ffffffffc02013ec:	00d70f63          	beq	a4,a3,ffffffffc020140a <best_fit_free_pages+0xcc>
ffffffffc02013f0:	490c                	lw	a1,16(a0)
ffffffffc02013f2:	fe870693          	addi	a3,a4,-24
ffffffffc02013f6:	02059613          	slli	a2,a1,0x20
ffffffffc02013fa:	9201                	srli	a2,a2,0x20
ffffffffc02013fc:	00261793          	slli	a5,a2,0x2
ffffffffc0201400:	97b2                	add	a5,a5,a2
ffffffffc0201402:	078e                	slli	a5,a5,0x3
ffffffffc0201404:	97aa                	add	a5,a5,a0
ffffffffc0201406:	04f68863          	beq	a3,a5,ffffffffc0201456 <best_fit_free_pages+0x118>
ffffffffc020140a:	60a2                	ld	ra,8(sp)
ffffffffc020140c:	0141                	addi	sp,sp,16
ffffffffc020140e:	8082                	ret
ffffffffc0201410:	e790                	sd	a2,8(a5)
ffffffffc0201412:	f114                	sd	a3,32(a0)
ffffffffc0201414:	6798                	ld	a4,8(a5)
ffffffffc0201416:	ed1c                	sd	a5,24(a0)
ffffffffc0201418:	8832                	mv	a6,a2
ffffffffc020141a:	02d70b63          	beq	a4,a3,ffffffffc0201450 <best_fit_free_pages+0x112>
ffffffffc020141e:	4585                	li	a1,1
ffffffffc0201420:	87ba                	mv	a5,a4
ffffffffc0201422:	bf41                	j	ffffffffc02013b2 <best_fit_free_pages+0x74>
ffffffffc0201424:	491c                	lw	a5,16(a0)
ffffffffc0201426:	5675                	li	a2,-3
ffffffffc0201428:	010787bb          	addw	a5,a5,a6
ffffffffc020142c:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201430:	60c8b02f          	amoand.d	zero,a2,(a7)
ffffffffc0201434:	6d10                	ld	a2,24(a0)
ffffffffc0201436:	711c                	ld	a5,32(a0)
ffffffffc0201438:	852e                	mv	a0,a1
ffffffffc020143a:	e61c                	sd	a5,8(a2)
ffffffffc020143c:	6718                	ld	a4,8(a4)
ffffffffc020143e:	e390                	sd	a2,0(a5)
ffffffffc0201440:	b775                	j	ffffffffc02013ec <best_fit_free_pages+0xae>
ffffffffc0201442:	60a2                	ld	ra,8(sp)
ffffffffc0201444:	e390                	sd	a2,0(a5)
ffffffffc0201446:	e790                	sd	a2,8(a5)
ffffffffc0201448:	f11c                	sd	a5,32(a0)
ffffffffc020144a:	ed1c                	sd	a5,24(a0)
ffffffffc020144c:	0141                	addi	sp,sp,16
ffffffffc020144e:	8082                	ret
ffffffffc0201450:	e290                	sd	a2,0(a3)
ffffffffc0201452:	873e                	mv	a4,a5
ffffffffc0201454:	bf9d                	j	ffffffffc02013ca <best_fit_free_pages+0x8c>
ffffffffc0201456:	ff872783          	lw	a5,-8(a4)
ffffffffc020145a:	56f5                	li	a3,-3
ffffffffc020145c:	9fad                	addw	a5,a5,a1
ffffffffc020145e:	c91c                	sw	a5,16(a0)
ffffffffc0201460:	ff070793          	addi	a5,a4,-16
ffffffffc0201464:	60d7b02f          	amoand.d	zero,a3,(a5)
ffffffffc0201468:	6314                	ld	a3,0(a4)
ffffffffc020146a:	671c                	ld	a5,8(a4)
ffffffffc020146c:	60a2                	ld	ra,8(sp)
ffffffffc020146e:	e69c                	sd	a5,8(a3)
ffffffffc0201470:	e394                	sd	a3,0(a5)
ffffffffc0201472:	0141                	addi	sp,sp,16
ffffffffc0201474:	8082                	ret
ffffffffc0201476:	00001697          	auipc	a3,0x1
ffffffffc020147a:	5c268693          	addi	a3,a3,1474 # ffffffffc0202a38 <etext+0xb48>
ffffffffc020147e:	00001617          	auipc	a2,0x1
ffffffffc0201482:	2d260613          	addi	a2,a2,722 # ffffffffc0202750 <etext+0x860>
ffffffffc0201486:	06100593          	li	a1,97
ffffffffc020148a:	00001517          	auipc	a0,0x1
ffffffffc020148e:	2de50513          	addi	a0,a0,734 # ffffffffc0202768 <etext+0x878>
ffffffffc0201492:	ee9fe0ef          	jal	ffffffffc020037a <__panic>
ffffffffc0201496:	00001697          	auipc	a3,0x1
ffffffffc020149a:	59a68693          	addi	a3,a3,1434 # ffffffffc0202a30 <etext+0xb40>
ffffffffc020149e:	00001617          	auipc	a2,0x1
ffffffffc02014a2:	2b260613          	addi	a2,a2,690 # ffffffffc0202750 <etext+0x860>
ffffffffc02014a6:	05e00593          	li	a1,94
ffffffffc02014aa:	00001517          	auipc	a0,0x1
ffffffffc02014ae:	2be50513          	addi	a0,a0,702 # ffffffffc0202768 <etext+0x878>
ffffffffc02014b2:	ec9fe0ef          	jal	ffffffffc020037a <__panic>

ffffffffc02014b6 <best_fit_alloc_pages>:
ffffffffc02014b6:	c57d                	beqz	a0,ffffffffc02015a4 <best_fit_alloc_pages+0xee>
ffffffffc02014b8:	00005897          	auipc	a7,0x5
ffffffffc02014bc:	b808a883          	lw	a7,-1152(a7) # ffffffffc0206038 <free_area+0x10>
ffffffffc02014c0:	00005617          	auipc	a2,0x5
ffffffffc02014c4:	b6860613          	addi	a2,a2,-1176 # ffffffffc0206028 <free_area>
ffffffffc02014c8:	02089793          	slli	a5,a7,0x20
ffffffffc02014cc:	9381                	srli	a5,a5,0x20
ffffffffc02014ce:	0ca7e663          	bltu	a5,a0,ffffffffc020159a <best_fit_alloc_pages+0xe4>
ffffffffc02014d2:	661c                	ld	a5,8(a2)
ffffffffc02014d4:	4681                	li	a3,0
ffffffffc02014d6:	0cc78263          	beq	a5,a2,ffffffffc020159a <best_fit_alloc_pages+0xe4>
ffffffffc02014da:	ff87a703          	lw	a4,-8(a5)
ffffffffc02014de:	02071593          	slli	a1,a4,0x20
ffffffffc02014e2:	9181                	srli	a1,a1,0x20
ffffffffc02014e4:	02a5e663          	bltu	a1,a0,ffffffffc0201510 <best_fit_alloc_pages+0x5a>
ffffffffc02014e8:	fe878593          	addi	a1,a5,-24
ffffffffc02014ec:	cea1                	beqz	a3,ffffffffc0201544 <best_fit_alloc_pages+0x8e>
ffffffffc02014ee:	0106a803          	lw	a6,16(a3)
ffffffffc02014f2:	07076963          	bltu	a4,a6,ffffffffc0201564 <best_fit_alloc_pages+0xae>
ffffffffc02014f6:	679c                	ld	a5,8(a5)
ffffffffc02014f8:	02c78063          	beq	a5,a2,ffffffffc0201518 <best_fit_alloc_pages+0x62>
ffffffffc02014fc:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201500:	fe878593          	addi	a1,a5,-24
ffffffffc0201504:	02071313          	slli	t1,a4,0x20
ffffffffc0201508:	02035313          	srli	t1,t1,0x20
ffffffffc020150c:	fea373e3          	bgeu	t1,a0,ffffffffc02014f2 <best_fit_alloc_pages+0x3c>
ffffffffc0201510:	679c                	ld	a5,8(a5)
ffffffffc0201512:	fcc794e3          	bne	a5,a2,ffffffffc02014da <best_fit_alloc_pages+0x24>
ffffffffc0201516:	c68d                	beqz	a3,ffffffffc0201540 <best_fit_alloc_pages+0x8a>
ffffffffc0201518:	4a8c                	lw	a1,16(a3)
ffffffffc020151a:	6e98                	ld	a4,24(a3)
ffffffffc020151c:	729c                	ld	a5,32(a3)
ffffffffc020151e:	02059813          	slli	a6,a1,0x20
ffffffffc0201522:	02085813          	srli	a6,a6,0x20
ffffffffc0201526:	e71c                	sd	a5,8(a4)
ffffffffc0201528:	e398                	sd	a4,0(a5)
ffffffffc020152a:	05056263          	bltu	a0,a6,ffffffffc020156e <best_fit_alloc_pages+0xb8>
ffffffffc020152e:	40a888bb          	subw	a7,a7,a0
ffffffffc0201532:	01162823          	sw	a7,16(a2)
ffffffffc0201536:	57f5                	li	a5,-3
ffffffffc0201538:	00868713          	addi	a4,a3,8
ffffffffc020153c:	60f7302f          	amoand.d	zero,a5,(a4)
ffffffffc0201540:	8536                	mv	a0,a3
ffffffffc0201542:	8082                	ret
ffffffffc0201544:	679c                	ld	a5,8(a5)
ffffffffc0201546:	04c78d63          	beq	a5,a2,ffffffffc02015a0 <best_fit_alloc_pages+0xea>
ffffffffc020154a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020154e:	02071693          	slli	a3,a4,0x20
ffffffffc0201552:	9281                	srli	a3,a3,0x20
ffffffffc0201554:	00a6e863          	bltu	a3,a0,ffffffffc0201564 <best_fit_alloc_pages+0xae>
ffffffffc0201558:	86ae                	mv	a3,a1
ffffffffc020155a:	0106a803          	lw	a6,16(a3)
ffffffffc020155e:	fe878593          	addi	a1,a5,-24
ffffffffc0201562:	bf41                	j	ffffffffc02014f2 <best_fit_alloc_pages+0x3c>
ffffffffc0201564:	679c                	ld	a5,8(a5)
ffffffffc0201566:	86ae                	mv	a3,a1
ffffffffc0201568:	f6c799e3          	bne	a5,a2,ffffffffc02014da <best_fit_alloc_pages+0x24>
ffffffffc020156c:	b76d                	j	ffffffffc0201516 <best_fit_alloc_pages+0x60>
ffffffffc020156e:	00251793          	slli	a5,a0,0x2
ffffffffc0201572:	97aa                	add	a5,a5,a0
ffffffffc0201574:	078e                	slli	a5,a5,0x3
ffffffffc0201576:	9d89                	subw	a1,a1,a0
ffffffffc0201578:	97b6                	add	a5,a5,a3
ffffffffc020157a:	cb8c                	sw	a1,16(a5)
ffffffffc020157c:	00878813          	addi	a6,a5,8
ffffffffc0201580:	4589                	li	a1,2
ffffffffc0201582:	40b8302f          	amoor.d	zero,a1,(a6)
ffffffffc0201586:	670c                	ld	a1,8(a4)
ffffffffc0201588:	01878813          	addi	a6,a5,24
ffffffffc020158c:	0105b023          	sd	a6,0(a1)
ffffffffc0201590:	01073423          	sd	a6,8(a4)
ffffffffc0201594:	f38c                	sd	a1,32(a5)
ffffffffc0201596:	ef98                	sd	a4,24(a5)
ffffffffc0201598:	bf59                	j	ffffffffc020152e <best_fit_alloc_pages+0x78>
ffffffffc020159a:	4681                	li	a3,0
ffffffffc020159c:	8536                	mv	a0,a3
ffffffffc020159e:	8082                	ret
ffffffffc02015a0:	86ae                	mv	a3,a1
ffffffffc02015a2:	bf95                	j	ffffffffc0201516 <best_fit_alloc_pages+0x60>
ffffffffc02015a4:	1141                	addi	sp,sp,-16
ffffffffc02015a6:	00001697          	auipc	a3,0x1
ffffffffc02015aa:	48a68693          	addi	a3,a3,1162 # ffffffffc0202a30 <etext+0xb40>
ffffffffc02015ae:	00001617          	auipc	a2,0x1
ffffffffc02015b2:	1a260613          	addi	a2,a2,418 # ffffffffc0202750 <etext+0x860>
ffffffffc02015b6:	03d00593          	li	a1,61
ffffffffc02015ba:	00001517          	auipc	a0,0x1
ffffffffc02015be:	1ae50513          	addi	a0,a0,430 # ffffffffc0202768 <etext+0x878>
ffffffffc02015c2:	e406                	sd	ra,8(sp)
ffffffffc02015c4:	db7fe0ef          	jal	ffffffffc020037a <__panic>

ffffffffc02015c8 <best_fit_init_memmap>:
ffffffffc02015c8:	1141                	addi	sp,sp,-16
ffffffffc02015ca:	e406                	sd	ra,8(sp)
ffffffffc02015cc:	c9e1                	beqz	a1,ffffffffc020169c <best_fit_init_memmap+0xd4>
ffffffffc02015ce:	00259713          	slli	a4,a1,0x2
ffffffffc02015d2:	972e                	add	a4,a4,a1
ffffffffc02015d4:	070e                	slli	a4,a4,0x3
ffffffffc02015d6:	00e506b3          	add	a3,a0,a4
ffffffffc02015da:	87aa                	mv	a5,a0
ffffffffc02015dc:	cf11                	beqz	a4,ffffffffc02015f8 <best_fit_init_memmap+0x30>
ffffffffc02015de:	6798                	ld	a4,8(a5)
ffffffffc02015e0:	8b05                	andi	a4,a4,1
ffffffffc02015e2:	cf49                	beqz	a4,ffffffffc020167c <best_fit_init_memmap+0xb4>
ffffffffc02015e4:	0007a823          	sw	zero,16(a5)
ffffffffc02015e8:	0007b423          	sd	zero,8(a5)
ffffffffc02015ec:	0007a023          	sw	zero,0(a5)
ffffffffc02015f0:	02878793          	addi	a5,a5,40
ffffffffc02015f4:	fed795e3          	bne	a5,a3,ffffffffc02015de <best_fit_init_memmap+0x16>
ffffffffc02015f8:	c90c                	sw	a1,16(a0)
ffffffffc02015fa:	4789                	li	a5,2
ffffffffc02015fc:	00850713          	addi	a4,a0,8
ffffffffc0201600:	40f7302f          	amoor.d	zero,a5,(a4)
ffffffffc0201604:	00005717          	auipc	a4,0x5
ffffffffc0201608:	a3472703          	lw	a4,-1484(a4) # ffffffffc0206038 <free_area+0x10>
ffffffffc020160c:	00005697          	auipc	a3,0x5
ffffffffc0201610:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0206028 <free_area>
ffffffffc0201614:	669c                	ld	a5,8(a3)
ffffffffc0201616:	9f2d                	addw	a4,a4,a1
ffffffffc0201618:	ca98                	sw	a4,16(a3)
ffffffffc020161a:	01850613          	addi	a2,a0,24
ffffffffc020161e:	4581                	li	a1,0
ffffffffc0201620:	04d78763          	beq	a5,a3,ffffffffc020166e <best_fit_init_memmap+0xa6>
ffffffffc0201624:	fe878713          	addi	a4,a5,-24
ffffffffc0201628:	00e56a63          	bltu	a0,a4,ffffffffc020163c <best_fit_init_memmap+0x74>
ffffffffc020162c:	6798                	ld	a4,8(a5)
ffffffffc020162e:	02d70263          	beq	a4,a3,ffffffffc0201652 <best_fit_init_memmap+0x8a>
ffffffffc0201632:	87ba                	mv	a5,a4
ffffffffc0201634:	fe878713          	addi	a4,a5,-24
ffffffffc0201638:	fee57ae3          	bgeu	a0,a4,ffffffffc020162c <best_fit_init_memmap+0x64>
ffffffffc020163c:	c199                	beqz	a1,ffffffffc0201642 <best_fit_init_memmap+0x7a>
ffffffffc020163e:	0106b023          	sd	a6,0(a3)
ffffffffc0201642:	6398                	ld	a4,0(a5)
ffffffffc0201644:	60a2                	ld	ra,8(sp)
ffffffffc0201646:	e390                	sd	a2,0(a5)
ffffffffc0201648:	e710                	sd	a2,8(a4)
ffffffffc020164a:	ed18                	sd	a4,24(a0)
ffffffffc020164c:	f11c                	sd	a5,32(a0)
ffffffffc020164e:	0141                	addi	sp,sp,16
ffffffffc0201650:	8082                	ret
ffffffffc0201652:	e790                	sd	a2,8(a5)
ffffffffc0201654:	f114                	sd	a3,32(a0)
ffffffffc0201656:	6798                	ld	a4,8(a5)
ffffffffc0201658:	ed1c                	sd	a5,24(a0)
ffffffffc020165a:	8832                	mv	a6,a2
ffffffffc020165c:	00d70563          	beq	a4,a3,ffffffffc0201666 <best_fit_init_memmap+0x9e>
ffffffffc0201660:	4585                	li	a1,1
ffffffffc0201662:	87ba                	mv	a5,a4
ffffffffc0201664:	bfc1                	j	ffffffffc0201634 <best_fit_init_memmap+0x6c>
ffffffffc0201666:	60a2                	ld	ra,8(sp)
ffffffffc0201668:	e290                	sd	a2,0(a3)
ffffffffc020166a:	0141                	addi	sp,sp,16
ffffffffc020166c:	8082                	ret
ffffffffc020166e:	60a2                	ld	ra,8(sp)
ffffffffc0201670:	e390                	sd	a2,0(a5)
ffffffffc0201672:	e790                	sd	a2,8(a5)
ffffffffc0201674:	f11c                	sd	a5,32(a0)
ffffffffc0201676:	ed1c                	sd	a5,24(a0)
ffffffffc0201678:	0141                	addi	sp,sp,16
ffffffffc020167a:	8082                	ret
ffffffffc020167c:	00001697          	auipc	a3,0x1
ffffffffc0201680:	3e468693          	addi	a3,a3,996 # ffffffffc0202a60 <etext+0xb70>
ffffffffc0201684:	00001617          	auipc	a2,0x1
ffffffffc0201688:	0cc60613          	addi	a2,a2,204 # ffffffffc0202750 <etext+0x860>
ffffffffc020168c:	02400593          	li	a1,36
ffffffffc0201690:	00001517          	auipc	a0,0x1
ffffffffc0201694:	0d850513          	addi	a0,a0,216 # ffffffffc0202768 <etext+0x878>
ffffffffc0201698:	ce3fe0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020169c:	00001697          	auipc	a3,0x1
ffffffffc02016a0:	39468693          	addi	a3,a3,916 # ffffffffc0202a30 <etext+0xb40>
ffffffffc02016a4:	00001617          	auipc	a2,0x1
ffffffffc02016a8:	0ac60613          	addi	a2,a2,172 # ffffffffc0202750 <etext+0x860>
ffffffffc02016ac:	02100593          	li	a1,33
ffffffffc02016b0:	00001517          	auipc	a0,0x1
ffffffffc02016b4:	0b850513          	addi	a0,a0,184 # ffffffffc0202768 <etext+0x878>
ffffffffc02016b8:	cc3fe0ef          	jal	ffffffffc020037a <__panic>

ffffffffc02016bc <alloc_pages>:
ffffffffc02016bc:	00005797          	auipc	a5,0x5
ffffffffc02016c0:	da47b783          	ld	a5,-604(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc02016c4:	6f9c                	ld	a5,24(a5)
ffffffffc02016c6:	8782                	jr	a5

ffffffffc02016c8 <free_pages>:
ffffffffc02016c8:	00005797          	auipc	a5,0x5
ffffffffc02016cc:	d987b783          	ld	a5,-616(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc02016d0:	739c                	ld	a5,32(a5)
ffffffffc02016d2:	8782                	jr	a5

ffffffffc02016d4 <nr_free_pages>:
ffffffffc02016d4:	00005797          	auipc	a5,0x5
ffffffffc02016d8:	d8c7b783          	ld	a5,-628(a5) # ffffffffc0206460 <pmm_manager>
ffffffffc02016dc:	779c                	ld	a5,40(a5)
ffffffffc02016de:	8782                	jr	a5

ffffffffc02016e0 <pmm_init>:
ffffffffc02016e0:	00001797          	auipc	a5,0x1
ffffffffc02016e4:	6c878793          	addi	a5,a5,1736 # ffffffffc0202da8 <best_fit_pmm_manager>
ffffffffc02016e8:	638c                	ld	a1,0(a5)
ffffffffc02016ea:	711d                	addi	sp,sp,-96
ffffffffc02016ec:	ec86                	sd	ra,88(sp)
ffffffffc02016ee:	e8a2                	sd	s0,80(sp)
ffffffffc02016f0:	e4a6                	sd	s1,72(sp)
ffffffffc02016f2:	f852                	sd	s4,48(sp)
ffffffffc02016f4:	e0ca                	sd	s2,64(sp)
ffffffffc02016f6:	fc4e                	sd	s3,56(sp)
ffffffffc02016f8:	f456                	sd	s5,40(sp)
ffffffffc02016fa:	f05a                	sd	s6,32(sp)
ffffffffc02016fc:	ec5e                	sd	s7,24(sp)
ffffffffc02016fe:	00005417          	auipc	s0,0x5
ffffffffc0201702:	d6240413          	addi	s0,s0,-670 # ffffffffc0206460 <pmm_manager>
ffffffffc0201706:	00001517          	auipc	a0,0x1
ffffffffc020170a:	38250513          	addi	a0,a0,898 # ffffffffc0202a88 <etext+0xb98>
ffffffffc020170e:	e01c                	sd	a5,0(s0)
ffffffffc0201710:	9bdfe0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0201714:	601c                	ld	a5,0(s0)
ffffffffc0201716:	00005497          	auipc	s1,0x5
ffffffffc020171a:	d6248493          	addi	s1,s1,-670 # ffffffffc0206478 <va_pa_offset>
ffffffffc020171e:	679c                	ld	a5,8(a5)
ffffffffc0201720:	9782                	jalr	a5
ffffffffc0201722:	57f5                	li	a5,-3
ffffffffc0201724:	07fa                	slli	a5,a5,0x1e
ffffffffc0201726:	e09c                	sd	a5,0(s1)
ffffffffc0201728:	838ff0ef          	jal	ffffffffc0200760 <get_memory_base>
ffffffffc020172c:	8a2a                	mv	s4,a0
ffffffffc020172e:	83cff0ef          	jal	ffffffffc020076a <get_memory_size>
ffffffffc0201732:	001a3793          	seqz	a5,s4
ffffffffc0201736:	00153713          	seqz	a4,a0
ffffffffc020173a:	8fd9                	or	a5,a5,a4
ffffffffc020173c:	1c079e63          	bnez	a5,ffffffffc0201918 <pmm_init+0x238>
ffffffffc0201740:	00aa0bb3          	add	s7,s4,a0
ffffffffc0201744:	7b7d                	lui	s6,0xfffff
ffffffffc0201746:	016bf933          	and	s2,s7,s6
ffffffffc020174a:	1b2a7b63          	bgeu	s4,s2,ffffffffc0201900 <pmm_init+0x220>
ffffffffc020174e:	00c95793          	srli	a5,s2,0xc
ffffffffc0201752:	00005997          	auipc	s3,0x5
ffffffffc0201756:	d2e98993          	addi	s3,s3,-722 # ffffffffc0206480 <npage>
ffffffffc020175a:	00f9b023          	sd	a5,0(s3)
ffffffffc020175e:	00080ab7          	lui	s5,0x80
ffffffffc0201762:	18faf363          	bgeu	s5,a5,ffffffffc02018e8 <pmm_init+0x208>
ffffffffc0201766:	e42a                	sd	a0,8(sp)
ffffffffc0201768:	00001517          	auipc	a0,0x1
ffffffffc020176c:	3d850513          	addi	a0,a0,984 # ffffffffc0202b40 <etext+0xc50>
ffffffffc0201770:	95dfe0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0201774:	65a2                	ld	a1,8(sp)
ffffffffc0201776:	fffb8693          	addi	a3,s7,-1
ffffffffc020177a:	8652                	mv	a2,s4
ffffffffc020177c:	00001517          	auipc	a0,0x1
ffffffffc0201780:	3dc50513          	addi	a0,a0,988 # ffffffffc0202b58 <etext+0xc68>
ffffffffc0201784:	949fe0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0201788:	00006697          	auipc	a3,0x6
ffffffffc020178c:	d0f68693          	addi	a3,a3,-753 # ffffffffc0207497 <end+0xfff>
ffffffffc0201790:	0166f6b3          	and	a3,a3,s6
ffffffffc0201794:	c02007b7          	lui	a5,0xc0200
ffffffffc0201798:	12f6ec63          	bltu	a3,a5,ffffffffc02018d0 <pmm_init+0x1f0>
ffffffffc020179c:	0009b503          	ld	a0,0(s3)
ffffffffc02017a0:	609c                	ld	a5,0(s1)
ffffffffc02017a2:	41550533          	sub	a0,a0,s5
ffffffffc02017a6:	00251593          	slli	a1,a0,0x2
ffffffffc02017aa:	95aa                	add	a1,a1,a0
ffffffffc02017ac:	058e                	slli	a1,a1,0x3
ffffffffc02017ae:	95b6                	add	a1,a1,a3
ffffffffc02017b0:	8d9d                	sub	a1,a1,a5
ffffffffc02017b2:	10b96363          	bltu	s2,a1,ffffffffc02018b8 <pmm_init+0x1d8>
ffffffffc02017b6:	00005817          	auipc	a6,0x5
ffffffffc02017ba:	cd280813          	addi	a6,a6,-814 # ffffffffc0206488 <pages>
ffffffffc02017be:	00d83023          	sd	a3,0(a6)
ffffffffc02017c2:	c931                	beqz	a0,ffffffffc0201816 <pmm_init+0x136>
ffffffffc02017c4:	01868793          	addi	a5,a3,24
ffffffffc02017c8:	f29c                	sd	a5,32(a3)
ffffffffc02017ca:	ee9c                	sd	a5,24(a3)
ffffffffc02017cc:	0006b423          	sd	zero,8(a3)
ffffffffc02017d0:	0006a823          	sw	zero,16(a3)
ffffffffc02017d4:	0006a023          	sw	zero,0(a3)
ffffffffc02017d8:	4705                	li	a4,1
ffffffffc02017da:	00868793          	addi	a5,a3,8
ffffffffc02017de:	40e7b02f          	amoor.d	zero,a4,(a5)
ffffffffc02017e2:	02e50a63          	beq	a0,a4,ffffffffc0201816 <pmm_init+0x136>
ffffffffc02017e6:	88ba                	mv	a7,a4
ffffffffc02017e8:	02800693          	li	a3,40
ffffffffc02017ec:	00083783          	ld	a5,0(a6)
ffffffffc02017f0:	97b6                	add	a5,a5,a3
ffffffffc02017f2:	01878613          	addi	a2,a5,24 # ffffffffc0200018 <kern_entry+0x18>
ffffffffc02017f6:	0007b423          	sd	zero,8(a5)
ffffffffc02017fa:	0007a823          	sw	zero,16(a5)
ffffffffc02017fe:	0007a023          	sw	zero,0(a5)
ffffffffc0201802:	f390                	sd	a2,32(a5)
ffffffffc0201804:	ef90                	sd	a2,24(a5)
ffffffffc0201806:	07a1                	addi	a5,a5,8
ffffffffc0201808:	4117b02f          	amoor.d	zero,a7,(a5)
ffffffffc020180c:	0705                	addi	a4,a4,1
ffffffffc020180e:	02868693          	addi	a3,a3,40
ffffffffc0201812:	fce51de3          	bne	a0,a4,ffffffffc02017ec <pmm_init+0x10c>
ffffffffc0201816:	6785                	lui	a5,0x1
ffffffffc0201818:	17fd                	addi	a5,a5,-1 # fff <sbadaddr+0xebc>
ffffffffc020181a:	97ae                	add	a5,a5,a1
ffffffffc020181c:	777d                	lui	a4,0xfffff
ffffffffc020181e:	8ff9                	and	a5,a5,a4
ffffffffc0201820:	0927f563          	bgeu	a5,s2,ffffffffc02018aa <pmm_init+0x1ca>
ffffffffc0201824:	0009b703          	ld	a4,0(s3)
ffffffffc0201828:	00c7d693          	srli	a3,a5,0xc
ffffffffc020182c:	10e6ff63          	bgeu	a3,a4,ffffffffc020194a <pmm_init+0x26a>
ffffffffc0201830:	fff80737          	lui	a4,0xfff80
ffffffffc0201834:	6010                	ld	a2,0(s0)
ffffffffc0201836:	96ba                	add	a3,a3,a4
ffffffffc0201838:	00269713          	slli	a4,a3,0x2
ffffffffc020183c:	00083503          	ld	a0,0(a6)
ffffffffc0201840:	9736                	add	a4,a4,a3
ffffffffc0201842:	6a14                	ld	a3,16(a2)
ffffffffc0201844:	40f905b3          	sub	a1,s2,a5
ffffffffc0201848:	070e                	slli	a4,a4,0x3
ffffffffc020184a:	81b1                	srli	a1,a1,0xc
ffffffffc020184c:	953a                	add	a0,a0,a4
ffffffffc020184e:	9682                	jalr	a3
ffffffffc0201850:	601c                	ld	a5,0(s0)
ffffffffc0201852:	7b9c                	ld	a5,48(a5)
ffffffffc0201854:	9782                	jalr	a5
ffffffffc0201856:	00001517          	auipc	a0,0x1
ffffffffc020185a:	3f250513          	addi	a0,a0,1010 # ffffffffc0202c48 <etext+0xd58>
ffffffffc020185e:	86ffe0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0201862:	00003597          	auipc	a1,0x3
ffffffffc0201866:	79e58593          	addi	a1,a1,1950 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020186a:	00005797          	auipc	a5,0x5
ffffffffc020186e:	c0b7b323          	sd	a1,-1018(a5) # ffffffffc0206470 <satp_virtual>
ffffffffc0201872:	c02007b7          	lui	a5,0xc0200
ffffffffc0201876:	0af5ed63          	bltu	a1,a5,ffffffffc0201930 <pmm_init+0x250>
ffffffffc020187a:	609c                	ld	a5,0(s1)
ffffffffc020187c:	6446                	ld	s0,80(sp)
ffffffffc020187e:	60e6                	ld	ra,88(sp)
ffffffffc0201880:	64a6                	ld	s1,72(sp)
ffffffffc0201882:	6906                	ld	s2,64(sp)
ffffffffc0201884:	79e2                	ld	s3,56(sp)
ffffffffc0201886:	7a42                	ld	s4,48(sp)
ffffffffc0201888:	7aa2                	ld	s5,40(sp)
ffffffffc020188a:	7b02                	ld	s6,32(sp)
ffffffffc020188c:	6be2                	ld	s7,24(sp)
ffffffffc020188e:	40f586b3          	sub	a3,a1,a5
ffffffffc0201892:	00005797          	auipc	a5,0x5
ffffffffc0201896:	bcd7bb23          	sd	a3,-1066(a5) # ffffffffc0206468 <satp_physical>
ffffffffc020189a:	00001517          	auipc	a0,0x1
ffffffffc020189e:	3ce50513          	addi	a0,a0,974 # ffffffffc0202c68 <etext+0xd78>
ffffffffc02018a2:	8636                	mv	a2,a3
ffffffffc02018a4:	6125                	addi	sp,sp,96
ffffffffc02018a6:	827fe06f          	j	ffffffffc02000cc <cprintf>
ffffffffc02018aa:	00001517          	auipc	a0,0x1
ffffffffc02018ae:	33e50513          	addi	a0,a0,830 # ffffffffc0202be8 <etext+0xcf8>
ffffffffc02018b2:	81bfe0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc02018b6:	bf69                	j	ffffffffc0201850 <pmm_init+0x170>
ffffffffc02018b8:	00001617          	auipc	a2,0x1
ffffffffc02018bc:	2f860613          	addi	a2,a2,760 # ffffffffc0202bb0 <etext+0xcc0>
ffffffffc02018c0:	08200593          	li	a1,130
ffffffffc02018c4:	00001517          	auipc	a0,0x1
ffffffffc02018c8:	21450513          	addi	a0,a0,532 # ffffffffc0202ad8 <etext+0xbe8>
ffffffffc02018cc:	aaffe0ef          	jal	ffffffffc020037a <__panic>
ffffffffc02018d0:	00001617          	auipc	a2,0x1
ffffffffc02018d4:	2b860613          	addi	a2,a2,696 # ffffffffc0202b88 <etext+0xc98>
ffffffffc02018d8:	07e00593          	li	a1,126
ffffffffc02018dc:	00001517          	auipc	a0,0x1
ffffffffc02018e0:	1fc50513          	addi	a0,a0,508 # ffffffffc0202ad8 <etext+0xbe8>
ffffffffc02018e4:	a97fe0ef          	jal	ffffffffc020037a <__panic>
ffffffffc02018e8:	00001617          	auipc	a2,0x1
ffffffffc02018ec:	23060613          	addi	a2,a2,560 # ffffffffc0202b18 <etext+0xc28>
ffffffffc02018f0:	07500593          	li	a1,117
ffffffffc02018f4:	00001517          	auipc	a0,0x1
ffffffffc02018f8:	1e450513          	addi	a0,a0,484 # ffffffffc0202ad8 <etext+0xbe8>
ffffffffc02018fc:	a7ffe0ef          	jal	ffffffffc020037a <__panic>
ffffffffc0201900:	00001617          	auipc	a2,0x1
ffffffffc0201904:	1e860613          	addi	a2,a2,488 # ffffffffc0202ae8 <etext+0xbf8>
ffffffffc0201908:	06f00593          	li	a1,111
ffffffffc020190c:	00001517          	auipc	a0,0x1
ffffffffc0201910:	1cc50513          	addi	a0,a0,460 # ffffffffc0202ad8 <etext+0xbe8>
ffffffffc0201914:	a67fe0ef          	jal	ffffffffc020037a <__panic>
ffffffffc0201918:	00001617          	auipc	a2,0x1
ffffffffc020191c:	18860613          	addi	a2,a2,392 # ffffffffc0202aa0 <etext+0xbb0>
ffffffffc0201920:	06700593          	li	a1,103
ffffffffc0201924:	00001517          	auipc	a0,0x1
ffffffffc0201928:	1b450513          	addi	a0,a0,436 # ffffffffc0202ad8 <etext+0xbe8>
ffffffffc020192c:	a4ffe0ef          	jal	ffffffffc020037a <__panic>
ffffffffc0201930:	86ae                	mv	a3,a1
ffffffffc0201932:	00001617          	auipc	a2,0x1
ffffffffc0201936:	25660613          	addi	a2,a2,598 # ffffffffc0202b88 <etext+0xc98>
ffffffffc020193a:	0ac00593          	li	a1,172
ffffffffc020193e:	00001517          	auipc	a0,0x1
ffffffffc0201942:	19a50513          	addi	a0,a0,410 # ffffffffc0202ad8 <etext+0xbe8>
ffffffffc0201946:	a35fe0ef          	jal	ffffffffc020037a <__panic>
ffffffffc020194a:	00001617          	auipc	a2,0x1
ffffffffc020194e:	2ce60613          	addi	a2,a2,718 # ffffffffc0202c18 <etext+0xd28>
ffffffffc0201952:	06b00593          	li	a1,107
ffffffffc0201956:	00001517          	auipc	a0,0x1
ffffffffc020195a:	2e250513          	addi	a0,a0,738 # ffffffffc0202c38 <etext+0xd48>
ffffffffc020195e:	a1dfe0ef          	jal	ffffffffc020037a <__panic>

ffffffffc0201962 <printnum>:
ffffffffc0201962:	7179                	addi	sp,sp,-48
ffffffffc0201964:	e052                	sd	s4,0(sp)
ffffffffc0201966:	02d67a33          	remu	s4,a2,a3
ffffffffc020196a:	f022                	sd	s0,32(sp)
ffffffffc020196c:	ec26                	sd	s1,24(sp)
ffffffffc020196e:	e84a                	sd	s2,16(sp)
ffffffffc0201970:	f406                	sd	ra,40(sp)
ffffffffc0201972:	fff7041b          	addiw	s0,a4,-1 # fffffffffff7ffff <end+0x3fd79b67>
ffffffffc0201976:	84aa                	mv	s1,a0
ffffffffc0201978:	892e                	mv	s2,a1
ffffffffc020197a:	2a01                	sext.w	s4,s4
ffffffffc020197c:	02d67d63          	bgeu	a2,a3,ffffffffc02019b6 <printnum+0x54>
ffffffffc0201980:	e44e                	sd	s3,8(sp)
ffffffffc0201982:	89be                	mv	s3,a5
ffffffffc0201984:	4785                	li	a5,1
ffffffffc0201986:	00e7d763          	bge	a5,a4,ffffffffc0201994 <printnum+0x32>
ffffffffc020198a:	85ca                	mv	a1,s2
ffffffffc020198c:	854e                	mv	a0,s3
ffffffffc020198e:	347d                	addiw	s0,s0,-1
ffffffffc0201990:	9482                	jalr	s1
ffffffffc0201992:	fc65                	bnez	s0,ffffffffc020198a <printnum+0x28>
ffffffffc0201994:	69a2                	ld	s3,8(sp)
ffffffffc0201996:	00001797          	auipc	a5,0x1
ffffffffc020199a:	31278793          	addi	a5,a5,786 # ffffffffc0202ca8 <etext+0xdb8>
ffffffffc020199e:	97d2                	add	a5,a5,s4
ffffffffc02019a0:	7402                	ld	s0,32(sp)
ffffffffc02019a2:	0007c503          	lbu	a0,0(a5)
ffffffffc02019a6:	70a2                	ld	ra,40(sp)
ffffffffc02019a8:	6a02                	ld	s4,0(sp)
ffffffffc02019aa:	85ca                	mv	a1,s2
ffffffffc02019ac:	87a6                	mv	a5,s1
ffffffffc02019ae:	6942                	ld	s2,16(sp)
ffffffffc02019b0:	64e2                	ld	s1,24(sp)
ffffffffc02019b2:	6145                	addi	sp,sp,48
ffffffffc02019b4:	8782                	jr	a5
ffffffffc02019b6:	02d65633          	divu	a2,a2,a3
ffffffffc02019ba:	8722                	mv	a4,s0
ffffffffc02019bc:	fa7ff0ef          	jal	ffffffffc0201962 <printnum>
ffffffffc02019c0:	bfd9                	j	ffffffffc0201996 <printnum+0x34>

ffffffffc02019c2 <vprintfmt>:
ffffffffc02019c2:	7119                	addi	sp,sp,-128
ffffffffc02019c4:	f4a6                	sd	s1,104(sp)
ffffffffc02019c6:	f0ca                	sd	s2,96(sp)
ffffffffc02019c8:	ecce                	sd	s3,88(sp)
ffffffffc02019ca:	e8d2                	sd	s4,80(sp)
ffffffffc02019cc:	e4d6                	sd	s5,72(sp)
ffffffffc02019ce:	e0da                	sd	s6,64(sp)
ffffffffc02019d0:	f862                	sd	s8,48(sp)
ffffffffc02019d2:	fc86                	sd	ra,120(sp)
ffffffffc02019d4:	f8a2                	sd	s0,112(sp)
ffffffffc02019d6:	fc5e                	sd	s7,56(sp)
ffffffffc02019d8:	f466                	sd	s9,40(sp)
ffffffffc02019da:	f06a                	sd	s10,32(sp)
ffffffffc02019dc:	ec6e                	sd	s11,24(sp)
ffffffffc02019de:	84aa                	mv	s1,a0
ffffffffc02019e0:	8c32                	mv	s8,a2
ffffffffc02019e2:	8a36                	mv	s4,a3
ffffffffc02019e4:	892e                	mv	s2,a1
ffffffffc02019e6:	02500993          	li	s3,37
ffffffffc02019ea:	05500b13          	li	s6,85
ffffffffc02019ee:	00001a97          	auipc	s5,0x1
ffffffffc02019f2:	3f2a8a93          	addi	s5,s5,1010 # ffffffffc0202de0 <best_fit_pmm_manager+0x38>
ffffffffc02019f6:	000c4503          	lbu	a0,0(s8)
ffffffffc02019fa:	001c0413          	addi	s0,s8,1
ffffffffc02019fe:	01350a63          	beq	a0,s3,ffffffffc0201a12 <vprintfmt+0x50>
ffffffffc0201a02:	cd0d                	beqz	a0,ffffffffc0201a3c <vprintfmt+0x7a>
ffffffffc0201a04:	85ca                	mv	a1,s2
ffffffffc0201a06:	9482                	jalr	s1
ffffffffc0201a08:	00044503          	lbu	a0,0(s0)
ffffffffc0201a0c:	0405                	addi	s0,s0,1
ffffffffc0201a0e:	ff351ae3          	bne	a0,s3,ffffffffc0201a02 <vprintfmt+0x40>
ffffffffc0201a12:	5cfd                	li	s9,-1
ffffffffc0201a14:	8d66                	mv	s10,s9
ffffffffc0201a16:	02000d93          	li	s11,32
ffffffffc0201a1a:	4b81                	li	s7,0
ffffffffc0201a1c:	4601                	li	a2,0
ffffffffc0201a1e:	00044683          	lbu	a3,0(s0)
ffffffffc0201a22:	00140c13          	addi	s8,s0,1
ffffffffc0201a26:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201a2a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a2e:	04bb6263          	bltu	s6,a1,ffffffffc0201a72 <vprintfmt+0xb0>
ffffffffc0201a32:	058a                	slli	a1,a1,0x2
ffffffffc0201a34:	95d6                	add	a1,a1,s5
ffffffffc0201a36:	4198                	lw	a4,0(a1)
ffffffffc0201a38:	9756                	add	a4,a4,s5
ffffffffc0201a3a:	8702                	jr	a4
ffffffffc0201a3c:	70e6                	ld	ra,120(sp)
ffffffffc0201a3e:	7446                	ld	s0,112(sp)
ffffffffc0201a40:	74a6                	ld	s1,104(sp)
ffffffffc0201a42:	7906                	ld	s2,96(sp)
ffffffffc0201a44:	69e6                	ld	s3,88(sp)
ffffffffc0201a46:	6a46                	ld	s4,80(sp)
ffffffffc0201a48:	6aa6                	ld	s5,72(sp)
ffffffffc0201a4a:	6b06                	ld	s6,64(sp)
ffffffffc0201a4c:	7be2                	ld	s7,56(sp)
ffffffffc0201a4e:	7c42                	ld	s8,48(sp)
ffffffffc0201a50:	7ca2                	ld	s9,40(sp)
ffffffffc0201a52:	7d02                	ld	s10,32(sp)
ffffffffc0201a54:	6de2                	ld	s11,24(sp)
ffffffffc0201a56:	6109                	addi	sp,sp,128
ffffffffc0201a58:	8082                	ret
ffffffffc0201a5a:	8462                	mv	s0,s8
ffffffffc0201a5c:	00044683          	lbu	a3,0(s0)
ffffffffc0201a60:	2605                	addiw	a2,a2,1
ffffffffc0201a62:	00140c13          	addi	s8,s0,1
ffffffffc0201a66:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201a6a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a6e:	fcbb72e3          	bgeu	s6,a1,ffffffffc0201a32 <vprintfmt+0x70>
ffffffffc0201a72:	85ca                	mv	a1,s2
ffffffffc0201a74:	02500513          	li	a0,37
ffffffffc0201a78:	9482                	jalr	s1
ffffffffc0201a7a:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201a7e:	02500713          	li	a4,37
ffffffffc0201a82:	8c22                	mv	s8,s0
ffffffffc0201a84:	f6e789e3          	beq	a5,a4,ffffffffc02019f6 <vprintfmt+0x34>
ffffffffc0201a88:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201a8c:	1c7d                	addi	s8,s8,-1
ffffffffc0201a8e:	fee79de3          	bne	a5,a4,ffffffffc0201a88 <vprintfmt+0xc6>
ffffffffc0201a92:	b795                	j	ffffffffc02019f6 <vprintfmt+0x34>
ffffffffc0201a94:	00144783          	lbu	a5,1(s0)
ffffffffc0201a98:	4525                	li	a0,9
ffffffffc0201a9a:	fd068c9b          	addiw	s9,a3,-48
ffffffffc0201a9e:	fd07871b          	addiw	a4,a5,-48
ffffffffc0201aa2:	8462                	mv	s0,s8
ffffffffc0201aa4:	02e56363          	bltu	a0,a4,ffffffffc0201aca <vprintfmt+0x108>
ffffffffc0201aa8:	002c971b          	slliw	a4,s9,0x2
ffffffffc0201aac:	00144683          	lbu	a3,1(s0)
ffffffffc0201ab0:	0197073b          	addw	a4,a4,s9
ffffffffc0201ab4:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201ab8:	9f3d                	addw	a4,a4,a5
ffffffffc0201aba:	fd06859b          	addiw	a1,a3,-48
ffffffffc0201abe:	0405                	addi	s0,s0,1
ffffffffc0201ac0:	fd070c9b          	addiw	s9,a4,-48
ffffffffc0201ac4:	87b6                	mv	a5,a3
ffffffffc0201ac6:	feb571e3          	bgeu	a0,a1,ffffffffc0201aa8 <vprintfmt+0xe6>
ffffffffc0201aca:	f40d5ae3          	bgez	s10,ffffffffc0201a1e <vprintfmt+0x5c>
ffffffffc0201ace:	8d66                	mv	s10,s9
ffffffffc0201ad0:	5cfd                	li	s9,-1
ffffffffc0201ad2:	b7b1                	j	ffffffffc0201a1e <vprintfmt+0x5c>
ffffffffc0201ad4:	8db6                	mv	s11,a3
ffffffffc0201ad6:	8462                	mv	s0,s8
ffffffffc0201ad8:	b799                	j	ffffffffc0201a1e <vprintfmt+0x5c>
ffffffffc0201ada:	000a2c83          	lw	s9,0(s4)
ffffffffc0201ade:	8462                	mv	s0,s8
ffffffffc0201ae0:	0a21                	addi	s4,s4,8
ffffffffc0201ae2:	b7e5                	j	ffffffffc0201aca <vprintfmt+0x108>
ffffffffc0201ae4:	4785                	li	a5,1
ffffffffc0201ae6:	008a0713          	addi	a4,s4,8
ffffffffc0201aea:	00c7c463          	blt	a5,a2,ffffffffc0201af2 <vprintfmt+0x130>
ffffffffc0201aee:	1a060b63          	beqz	a2,ffffffffc0201ca4 <vprintfmt+0x2e2>
ffffffffc0201af2:	000a3603          	ld	a2,0(s4)
ffffffffc0201af6:	46c1                	li	a3,16
ffffffffc0201af8:	8a3a                	mv	s4,a4
ffffffffc0201afa:	000d879b          	sext.w	a5,s11
ffffffffc0201afe:	876a                	mv	a4,s10
ffffffffc0201b00:	85ca                	mv	a1,s2
ffffffffc0201b02:	8526                	mv	a0,s1
ffffffffc0201b04:	e5fff0ef          	jal	ffffffffc0201962 <printnum>
ffffffffc0201b08:	b5fd                	j	ffffffffc02019f6 <vprintfmt+0x34>
ffffffffc0201b0a:	000a2503          	lw	a0,0(s4)
ffffffffc0201b0e:	85ca                	mv	a1,s2
ffffffffc0201b10:	0a21                	addi	s4,s4,8
ffffffffc0201b12:	9482                	jalr	s1
ffffffffc0201b14:	b5cd                	j	ffffffffc02019f6 <vprintfmt+0x34>
ffffffffc0201b16:	4785                	li	a5,1
ffffffffc0201b18:	008a0713          	addi	a4,s4,8
ffffffffc0201b1c:	00c7c463          	blt	a5,a2,ffffffffc0201b24 <vprintfmt+0x162>
ffffffffc0201b20:	16060d63          	beqz	a2,ffffffffc0201c9a <vprintfmt+0x2d8>
ffffffffc0201b24:	000a3603          	ld	a2,0(s4)
ffffffffc0201b28:	46a9                	li	a3,10
ffffffffc0201b2a:	8a3a                	mv	s4,a4
ffffffffc0201b2c:	b7f9                	j	ffffffffc0201afa <vprintfmt+0x138>
ffffffffc0201b2e:	8462                	mv	s0,s8
ffffffffc0201b30:	4b85                	li	s7,1
ffffffffc0201b32:	b5f5                	j	ffffffffc0201a1e <vprintfmt+0x5c>
ffffffffc0201b34:	85ca                	mv	a1,s2
ffffffffc0201b36:	02500513          	li	a0,37
ffffffffc0201b3a:	9482                	jalr	s1
ffffffffc0201b3c:	bd6d                	j	ffffffffc02019f6 <vprintfmt+0x34>
ffffffffc0201b3e:	4785                	li	a5,1
ffffffffc0201b40:	008a0713          	addi	a4,s4,8
ffffffffc0201b44:	00c7c463          	blt	a5,a2,ffffffffc0201b4c <vprintfmt+0x18a>
ffffffffc0201b48:	14060463          	beqz	a2,ffffffffc0201c90 <vprintfmt+0x2ce>
ffffffffc0201b4c:	000a3603          	ld	a2,0(s4)
ffffffffc0201b50:	46a1                	li	a3,8
ffffffffc0201b52:	8a3a                	mv	s4,a4
ffffffffc0201b54:	b75d                	j	ffffffffc0201afa <vprintfmt+0x138>
ffffffffc0201b56:	87ea                	mv	a5,s10
ffffffffc0201b58:	000d5363          	bgez	s10,ffffffffc0201b5e <vprintfmt+0x19c>
ffffffffc0201b5c:	4781                	li	a5,0
ffffffffc0201b5e:	00078d1b          	sext.w	s10,a5
ffffffffc0201b62:	8462                	mv	s0,s8
ffffffffc0201b64:	bd6d                	j	ffffffffc0201a1e <vprintfmt+0x5c>
ffffffffc0201b66:	85ca                	mv	a1,s2
ffffffffc0201b68:	03000513          	li	a0,48
ffffffffc0201b6c:	9482                	jalr	s1
ffffffffc0201b6e:	85ca                	mv	a1,s2
ffffffffc0201b70:	07800513          	li	a0,120
ffffffffc0201b74:	9482                	jalr	s1
ffffffffc0201b76:	000a3603          	ld	a2,0(s4)
ffffffffc0201b7a:	46c1                	li	a3,16
ffffffffc0201b7c:	0a21                	addi	s4,s4,8
ffffffffc0201b7e:	bfb5                	j	ffffffffc0201afa <vprintfmt+0x138>
ffffffffc0201b80:	000d841b          	sext.w	s0,s11
ffffffffc0201b84:	fd340793          	addi	a5,s0,-45
ffffffffc0201b88:	00f037b3          	snez	a5,a5
ffffffffc0201b8c:	01a02733          	sgtz	a4,s10
ffffffffc0201b90:	000a3d83          	ld	s11,0(s4)
ffffffffc0201b94:	8f7d                	and	a4,a4,a5
ffffffffc0201b96:	008a0793          	addi	a5,s4,8
ffffffffc0201b9a:	e03e                	sd	a5,0(sp)
ffffffffc0201b9c:	100d8963          	beqz	s11,ffffffffc0201cae <vprintfmt+0x2ec>
ffffffffc0201ba0:	12071063          	bnez	a4,ffffffffc0201cc0 <vprintfmt+0x2fe>
ffffffffc0201ba4:	000dc783          	lbu	a5,0(s11)
ffffffffc0201ba8:	0007851b          	sext.w	a0,a5
ffffffffc0201bac:	c78d                	beqz	a5,ffffffffc0201bd6 <vprintfmt+0x214>
ffffffffc0201bae:	0d85                	addi	s11,s11,1
ffffffffc0201bb0:	547d                	li	s0,-1
ffffffffc0201bb2:	05e00a13          	li	s4,94
ffffffffc0201bb6:	000cc563          	bltz	s9,ffffffffc0201bc0 <vprintfmt+0x1fe>
ffffffffc0201bba:	3cfd                	addiw	s9,s9,-1
ffffffffc0201bbc:	008c8d63          	beq	s9,s0,ffffffffc0201bd6 <vprintfmt+0x214>
ffffffffc0201bc0:	020b9663          	bnez	s7,ffffffffc0201bec <vprintfmt+0x22a>
ffffffffc0201bc4:	85ca                	mv	a1,s2
ffffffffc0201bc6:	9482                	jalr	s1
ffffffffc0201bc8:	000dc783          	lbu	a5,0(s11)
ffffffffc0201bcc:	0d85                	addi	s11,s11,1
ffffffffc0201bce:	3d7d                	addiw	s10,s10,-1
ffffffffc0201bd0:	0007851b          	sext.w	a0,a5
ffffffffc0201bd4:	f3ed                	bnez	a5,ffffffffc0201bb6 <vprintfmt+0x1f4>
ffffffffc0201bd6:	01a05963          	blez	s10,ffffffffc0201be8 <vprintfmt+0x226>
ffffffffc0201bda:	85ca                	mv	a1,s2
ffffffffc0201bdc:	02000513          	li	a0,32
ffffffffc0201be0:	3d7d                	addiw	s10,s10,-1
ffffffffc0201be2:	9482                	jalr	s1
ffffffffc0201be4:	fe0d1be3          	bnez	s10,ffffffffc0201bda <vprintfmt+0x218>
ffffffffc0201be8:	6a02                	ld	s4,0(sp)
ffffffffc0201bea:	b531                	j	ffffffffc02019f6 <vprintfmt+0x34>
ffffffffc0201bec:	3781                	addiw	a5,a5,-32
ffffffffc0201bee:	fcfa7be3          	bgeu	s4,a5,ffffffffc0201bc4 <vprintfmt+0x202>
ffffffffc0201bf2:	03f00513          	li	a0,63
ffffffffc0201bf6:	85ca                	mv	a1,s2
ffffffffc0201bf8:	9482                	jalr	s1
ffffffffc0201bfa:	000dc783          	lbu	a5,0(s11)
ffffffffc0201bfe:	0d85                	addi	s11,s11,1
ffffffffc0201c00:	3d7d                	addiw	s10,s10,-1
ffffffffc0201c02:	0007851b          	sext.w	a0,a5
ffffffffc0201c06:	dbe1                	beqz	a5,ffffffffc0201bd6 <vprintfmt+0x214>
ffffffffc0201c08:	fa0cd9e3          	bgez	s9,ffffffffc0201bba <vprintfmt+0x1f8>
ffffffffc0201c0c:	b7c5                	j	ffffffffc0201bec <vprintfmt+0x22a>
ffffffffc0201c0e:	4705                	li	a4,1
ffffffffc0201c10:	008a0793          	addi	a5,s4,8
ffffffffc0201c14:	00c74363          	blt	a4,a2,ffffffffc0201c1a <vprintfmt+0x258>
ffffffffc0201c18:	ca2d                	beqz	a2,ffffffffc0201c8a <vprintfmt+0x2c8>
ffffffffc0201c1a:	000a3603          	ld	a2,0(s4)
ffffffffc0201c1e:	8a3e                	mv	s4,a5
ffffffffc0201c20:	46a9                	li	a3,10
ffffffffc0201c22:	ec065ce3          	bgez	a2,ffffffffc0201afa <vprintfmt+0x138>
ffffffffc0201c26:	85ca                	mv	a1,s2
ffffffffc0201c28:	02d00513          	li	a0,45
ffffffffc0201c2c:	e432                	sd	a2,8(sp)
ffffffffc0201c2e:	e036                	sd	a3,0(sp)
ffffffffc0201c30:	9482                	jalr	s1
ffffffffc0201c32:	6622                	ld	a2,8(sp)
ffffffffc0201c34:	6682                	ld	a3,0(sp)
ffffffffc0201c36:	40c00633          	neg	a2,a2
ffffffffc0201c3a:	b5c1                	j	ffffffffc0201afa <vprintfmt+0x138>
ffffffffc0201c3c:	000a2783          	lw	a5,0(s4)
ffffffffc0201c40:	4619                	li	a2,6
ffffffffc0201c42:	0a21                	addi	s4,s4,8
ffffffffc0201c44:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201c48:	8fb9                	xor	a5,a5,a4
ffffffffc0201c4a:	40e786bb          	subw	a3,a5,a4
ffffffffc0201c4e:	02d64563          	blt	a2,a3,ffffffffc0201c78 <vprintfmt+0x2b6>
ffffffffc0201c52:	00001797          	auipc	a5,0x1
ffffffffc0201c56:	2e678793          	addi	a5,a5,742 # ffffffffc0202f38 <error_string>
ffffffffc0201c5a:	00369713          	slli	a4,a3,0x3
ffffffffc0201c5e:	97ba                	add	a5,a5,a4
ffffffffc0201c60:	639c                	ld	a5,0(a5)
ffffffffc0201c62:	cb99                	beqz	a5,ffffffffc0201c78 <vprintfmt+0x2b6>
ffffffffc0201c64:	86be                	mv	a3,a5
ffffffffc0201c66:	00001617          	auipc	a2,0x1
ffffffffc0201c6a:	07260613          	addi	a2,a2,114 # ffffffffc0202cd8 <etext+0xde8>
ffffffffc0201c6e:	85ca                	mv	a1,s2
ffffffffc0201c70:	8526                	mv	a0,s1
ffffffffc0201c72:	0a0000ef          	jal	ffffffffc0201d12 <printfmt>
ffffffffc0201c76:	b341                	j	ffffffffc02019f6 <vprintfmt+0x34>
ffffffffc0201c78:	00001617          	auipc	a2,0x1
ffffffffc0201c7c:	05060613          	addi	a2,a2,80 # ffffffffc0202cc8 <etext+0xdd8>
ffffffffc0201c80:	85ca                	mv	a1,s2
ffffffffc0201c82:	8526                	mv	a0,s1
ffffffffc0201c84:	08e000ef          	jal	ffffffffc0201d12 <printfmt>
ffffffffc0201c88:	b3bd                	j	ffffffffc02019f6 <vprintfmt+0x34>
ffffffffc0201c8a:	000a2603          	lw	a2,0(s4)
ffffffffc0201c8e:	bf41                	j	ffffffffc0201c1e <vprintfmt+0x25c>
ffffffffc0201c90:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c94:	46a1                	li	a3,8
ffffffffc0201c96:	8a3a                	mv	s4,a4
ffffffffc0201c98:	b58d                	j	ffffffffc0201afa <vprintfmt+0x138>
ffffffffc0201c9a:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c9e:	46a9                	li	a3,10
ffffffffc0201ca0:	8a3a                	mv	s4,a4
ffffffffc0201ca2:	bda1                	j	ffffffffc0201afa <vprintfmt+0x138>
ffffffffc0201ca4:	000a6603          	lwu	a2,0(s4)
ffffffffc0201ca8:	46c1                	li	a3,16
ffffffffc0201caa:	8a3a                	mv	s4,a4
ffffffffc0201cac:	b5b9                	j	ffffffffc0201afa <vprintfmt+0x138>
ffffffffc0201cae:	ef1d                	bnez	a4,ffffffffc0201cec <vprintfmt+0x32a>
ffffffffc0201cb0:	02800793          	li	a5,40
ffffffffc0201cb4:	853e                	mv	a0,a5
ffffffffc0201cb6:	00001d97          	auipc	s11,0x1
ffffffffc0201cba:	00bd8d93          	addi	s11,s11,11 # ffffffffc0202cc1 <etext+0xdd1>
ffffffffc0201cbe:	bdcd                	j	ffffffffc0201bb0 <vprintfmt+0x1ee>
ffffffffc0201cc0:	85e6                	mv	a1,s9
ffffffffc0201cc2:	856e                	mv	a0,s11
ffffffffc0201cc4:	1a0000ef          	jal	ffffffffc0201e64 <strnlen>
ffffffffc0201cc8:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201ccc:	01a05863          	blez	s10,ffffffffc0201cdc <vprintfmt+0x31a>
ffffffffc0201cd0:	85ca                	mv	a1,s2
ffffffffc0201cd2:	8522                	mv	a0,s0
ffffffffc0201cd4:	3d7d                	addiw	s10,s10,-1
ffffffffc0201cd6:	9482                	jalr	s1
ffffffffc0201cd8:	fe0d1ce3          	bnez	s10,ffffffffc0201cd0 <vprintfmt+0x30e>
ffffffffc0201cdc:	000dc783          	lbu	a5,0(s11)
ffffffffc0201ce0:	0007851b          	sext.w	a0,a5
ffffffffc0201ce4:	ec0795e3          	bnez	a5,ffffffffc0201bae <vprintfmt+0x1ec>
ffffffffc0201ce8:	6a02                	ld	s4,0(sp)
ffffffffc0201cea:	b331                	j	ffffffffc02019f6 <vprintfmt+0x34>
ffffffffc0201cec:	85e6                	mv	a1,s9
ffffffffc0201cee:	00001517          	auipc	a0,0x1
ffffffffc0201cf2:	fd250513          	addi	a0,a0,-46 # ffffffffc0202cc0 <etext+0xdd0>
ffffffffc0201cf6:	16e000ef          	jal	ffffffffc0201e64 <strnlen>
ffffffffc0201cfa:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201cfe:	02800793          	li	a5,40
ffffffffc0201d02:	00001d97          	auipc	s11,0x1
ffffffffc0201d06:	fbed8d93          	addi	s11,s11,-66 # ffffffffc0202cc0 <etext+0xdd0>
ffffffffc0201d0a:	853e                	mv	a0,a5
ffffffffc0201d0c:	fda042e3          	bgtz	s10,ffffffffc0201cd0 <vprintfmt+0x30e>
ffffffffc0201d10:	bd79                	j	ffffffffc0201bae <vprintfmt+0x1ec>

ffffffffc0201d12 <printfmt>:
ffffffffc0201d12:	715d                	addi	sp,sp,-80
ffffffffc0201d14:	02810313          	addi	t1,sp,40
ffffffffc0201d18:	f436                	sd	a3,40(sp)
ffffffffc0201d1a:	869a                	mv	a3,t1
ffffffffc0201d1c:	ec06                	sd	ra,24(sp)
ffffffffc0201d1e:	f83a                	sd	a4,48(sp)
ffffffffc0201d20:	fc3e                	sd	a5,56(sp)
ffffffffc0201d22:	e0c2                	sd	a6,64(sp)
ffffffffc0201d24:	e4c6                	sd	a7,72(sp)
ffffffffc0201d26:	e41a                	sd	t1,8(sp)
ffffffffc0201d28:	c9bff0ef          	jal	ffffffffc02019c2 <vprintfmt>
ffffffffc0201d2c:	60e2                	ld	ra,24(sp)
ffffffffc0201d2e:	6161                	addi	sp,sp,80
ffffffffc0201d30:	8082                	ret

ffffffffc0201d32 <readline>:
ffffffffc0201d32:	7179                	addi	sp,sp,-48
ffffffffc0201d34:	f406                	sd	ra,40(sp)
ffffffffc0201d36:	f022                	sd	s0,32(sp)
ffffffffc0201d38:	ec26                	sd	s1,24(sp)
ffffffffc0201d3a:	e84a                	sd	s2,16(sp)
ffffffffc0201d3c:	e44e                	sd	s3,8(sp)
ffffffffc0201d3e:	c901                	beqz	a0,ffffffffc0201d4e <readline+0x1c>
ffffffffc0201d40:	85aa                	mv	a1,a0
ffffffffc0201d42:	00001517          	auipc	a0,0x1
ffffffffc0201d46:	f9650513          	addi	a0,a0,-106 # ffffffffc0202cd8 <etext+0xde8>
ffffffffc0201d4a:	b82fe0ef          	jal	ffffffffc02000cc <cprintf>
ffffffffc0201d4e:	4981                	li	s3,0
ffffffffc0201d50:	44fd                	li	s1,31
ffffffffc0201d52:	00004917          	auipc	s2,0x4
ffffffffc0201d56:	2ee90913          	addi	s2,s2,750 # ffffffffc0206040 <buf>
ffffffffc0201d5a:	bf4fe0ef          	jal	ffffffffc020014e <getchar>
ffffffffc0201d5e:	ff850793          	addi	a5,a0,-8
ffffffffc0201d62:	ff650713          	addi	a4,a0,-10
ffffffffc0201d66:	ff350693          	addi	a3,a0,-13
ffffffffc0201d6a:	00a4a833          	slt	a6,s1,a0
ffffffffc0201d6e:	3ff9a593          	slti	a1,s3,1023
ffffffffc0201d72:	0017b793          	seqz	a5,a5
ffffffffc0201d76:	01302633          	sgtz	a2,s3
ffffffffc0201d7a:	00173713          	seqz	a4,a4
ffffffffc0201d7e:	0016b693          	seqz	a3,a3
ffffffffc0201d82:	842a                	mv	s0,a0
ffffffffc0201d84:	00b87833          	and	a6,a6,a1
ffffffffc0201d88:	8ff1                	and	a5,a5,a2
ffffffffc0201d8a:	8f55                	or	a4,a4,a3
ffffffffc0201d8c:	04054363          	bltz	a0,ffffffffc0201dd2 <readline+0xa0>
ffffffffc0201d90:	02081463          	bnez	a6,ffffffffc0201db8 <readline+0x86>
ffffffffc0201d94:	eb95                	bnez	a5,ffffffffc0201dc8 <readline+0x96>
ffffffffc0201d96:	d371                	beqz	a4,ffffffffc0201d5a <readline+0x28>
ffffffffc0201d98:	b68fe0ef          	jal	ffffffffc0200100 <cputchar>
ffffffffc0201d9c:	00004517          	auipc	a0,0x4
ffffffffc0201da0:	2a450513          	addi	a0,a0,676 # ffffffffc0206040 <buf>
ffffffffc0201da4:	99aa                	add	s3,s3,a0
ffffffffc0201da6:	00098023          	sb	zero,0(s3)
ffffffffc0201daa:	70a2                	ld	ra,40(sp)
ffffffffc0201dac:	7402                	ld	s0,32(sp)
ffffffffc0201dae:	64e2                	ld	s1,24(sp)
ffffffffc0201db0:	6942                	ld	s2,16(sp)
ffffffffc0201db2:	69a2                	ld	s3,8(sp)
ffffffffc0201db4:	6145                	addi	sp,sp,48
ffffffffc0201db6:	8082                	ret
ffffffffc0201db8:	b48fe0ef          	jal	ffffffffc0200100 <cputchar>
ffffffffc0201dbc:	013907b3          	add	a5,s2,s3
ffffffffc0201dc0:	00878023          	sb	s0,0(a5)
ffffffffc0201dc4:	2985                	addiw	s3,s3,1
ffffffffc0201dc6:	bf51                	j	ffffffffc0201d5a <readline+0x28>
ffffffffc0201dc8:	4521                	li	a0,8
ffffffffc0201dca:	b36fe0ef          	jal	ffffffffc0200100 <cputchar>
ffffffffc0201dce:	39fd                	addiw	s3,s3,-1
ffffffffc0201dd0:	b769                	j	ffffffffc0201d5a <readline+0x28>
ffffffffc0201dd2:	70a2                	ld	ra,40(sp)
ffffffffc0201dd4:	7402                	ld	s0,32(sp)
ffffffffc0201dd6:	64e2                	ld	s1,24(sp)
ffffffffc0201dd8:	6942                	ld	s2,16(sp)
ffffffffc0201dda:	69a2                	ld	s3,8(sp)
ffffffffc0201ddc:	4501                	li	a0,0
ffffffffc0201dde:	6145                	addi	sp,sp,48
ffffffffc0201de0:	8082                	ret

ffffffffc0201de2 <sbi_console_putchar>:
ffffffffc0201de2:	00004717          	auipc	a4,0x4
ffffffffc0201de6:	23e73703          	ld	a4,574(a4) # ffffffffc0206020 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201dea:	4781                	li	a5,0
ffffffffc0201dec:	88ba                	mv	a7,a4
ffffffffc0201dee:	852a                	mv	a0,a0
ffffffffc0201df0:	85be                	mv	a1,a5
ffffffffc0201df2:	863e                	mv	a2,a5
ffffffffc0201df4:	00000073          	ecall
ffffffffc0201df8:	87aa                	mv	a5,a0
ffffffffc0201dfa:	8082                	ret

ffffffffc0201dfc <sbi_set_timer>:
ffffffffc0201dfc:	00004717          	auipc	a4,0x4
ffffffffc0201e00:	69473703          	ld	a4,1684(a4) # ffffffffc0206490 <SBI_SET_TIMER>
ffffffffc0201e04:	4781                	li	a5,0
ffffffffc0201e06:	88ba                	mv	a7,a4
ffffffffc0201e08:	852a                	mv	a0,a0
ffffffffc0201e0a:	85be                	mv	a1,a5
ffffffffc0201e0c:	863e                	mv	a2,a5
ffffffffc0201e0e:	00000073          	ecall
ffffffffc0201e12:	87aa                	mv	a5,a0
ffffffffc0201e14:	8082                	ret

ffffffffc0201e16 <sbi_console_getchar>:
ffffffffc0201e16:	00004797          	auipc	a5,0x4
ffffffffc0201e1a:	2027b783          	ld	a5,514(a5) # ffffffffc0206018 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e1e:	4501                	li	a0,0
ffffffffc0201e20:	88be                	mv	a7,a5
ffffffffc0201e22:	852a                	mv	a0,a0
ffffffffc0201e24:	85aa                	mv	a1,a0
ffffffffc0201e26:	862a                	mv	a2,a0
ffffffffc0201e28:	00000073          	ecall
ffffffffc0201e2c:	852a                	mv	a0,a0
ffffffffc0201e2e:	2501                	sext.w	a0,a0
ffffffffc0201e30:	8082                	ret

ffffffffc0201e32 <sbi_shutdown>:
ffffffffc0201e32:	00004717          	auipc	a4,0x4
ffffffffc0201e36:	1de73703          	ld	a4,478(a4) # ffffffffc0206010 <SBI_SHUTDOWN>
ffffffffc0201e3a:	4781                	li	a5,0
ffffffffc0201e3c:	88ba                	mv	a7,a4
ffffffffc0201e3e:	853e                	mv	a0,a5
ffffffffc0201e40:	85be                	mv	a1,a5
ffffffffc0201e42:	863e                	mv	a2,a5
ffffffffc0201e44:	00000073          	ecall
ffffffffc0201e48:	87aa                	mv	a5,a0
ffffffffc0201e4a:	8082                	ret

ffffffffc0201e4c <strlen>:
ffffffffc0201e4c:	00054783          	lbu	a5,0(a0)
ffffffffc0201e50:	cb81                	beqz	a5,ffffffffc0201e60 <strlen+0x14>
ffffffffc0201e52:	4781                	li	a5,0
ffffffffc0201e54:	0785                	addi	a5,a5,1
ffffffffc0201e56:	00f50733          	add	a4,a0,a5
ffffffffc0201e5a:	00074703          	lbu	a4,0(a4)
ffffffffc0201e5e:	fb7d                	bnez	a4,ffffffffc0201e54 <strlen+0x8>
ffffffffc0201e60:	853e                	mv	a0,a5
ffffffffc0201e62:	8082                	ret

ffffffffc0201e64 <strnlen>:
ffffffffc0201e64:	4781                	li	a5,0
ffffffffc0201e66:	e589                	bnez	a1,ffffffffc0201e70 <strnlen+0xc>
ffffffffc0201e68:	a819                	j	ffffffffc0201e7e <strnlen+0x1a>
ffffffffc0201e6a:	0785                	addi	a5,a5,1
ffffffffc0201e6c:	00f58963          	beq	a1,a5,ffffffffc0201e7e <strnlen+0x1a>
ffffffffc0201e70:	00f50733          	add	a4,a0,a5
ffffffffc0201e74:	00074703          	lbu	a4,0(a4)
ffffffffc0201e78:	fb6d                	bnez	a4,ffffffffc0201e6a <strnlen+0x6>
ffffffffc0201e7a:	853e                	mv	a0,a5
ffffffffc0201e7c:	8082                	ret
ffffffffc0201e7e:	87ae                	mv	a5,a1
ffffffffc0201e80:	853e                	mv	a0,a5
ffffffffc0201e82:	8082                	ret

ffffffffc0201e84 <strcmp>:
ffffffffc0201e84:	00054783          	lbu	a5,0(a0)
ffffffffc0201e88:	cb91                	beqz	a5,ffffffffc0201e9c <strcmp+0x18>
ffffffffc0201e8a:	0005c703          	lbu	a4,0(a1)
ffffffffc0201e8e:	0505                	addi	a0,a0,1
ffffffffc0201e90:	0585                	addi	a1,a1,1
ffffffffc0201e92:	fef709e3          	beq	a4,a5,ffffffffc0201e84 <strcmp>
ffffffffc0201e96:	40e7853b          	subw	a0,a5,a4
ffffffffc0201e9a:	8082                	ret
ffffffffc0201e9c:	0005c703          	lbu	a4,0(a1)
ffffffffc0201ea0:	bfdd                	j	ffffffffc0201e96 <strcmp+0x12>

ffffffffc0201ea2 <strncmp>:
ffffffffc0201ea2:	ce01                	beqz	a2,ffffffffc0201eba <strncmp+0x18>
ffffffffc0201ea4:	00054783          	lbu	a5,0(a0)
ffffffffc0201ea8:	167d                	addi	a2,a2,-1
ffffffffc0201eaa:	cb91                	beqz	a5,ffffffffc0201ebe <strncmp+0x1c>
ffffffffc0201eac:	0005c703          	lbu	a4,0(a1)
ffffffffc0201eb0:	00f71763          	bne	a4,a5,ffffffffc0201ebe <strncmp+0x1c>
ffffffffc0201eb4:	0505                	addi	a0,a0,1
ffffffffc0201eb6:	0585                	addi	a1,a1,1
ffffffffc0201eb8:	f675                	bnez	a2,ffffffffc0201ea4 <strncmp+0x2>
ffffffffc0201eba:	4501                	li	a0,0
ffffffffc0201ebc:	8082                	ret
ffffffffc0201ebe:	00054503          	lbu	a0,0(a0)
ffffffffc0201ec2:	0005c783          	lbu	a5,0(a1)
ffffffffc0201ec6:	9d1d                	subw	a0,a0,a5
ffffffffc0201ec8:	8082                	ret

ffffffffc0201eca <strchr>:
ffffffffc0201eca:	a021                	j	ffffffffc0201ed2 <strchr+0x8>
ffffffffc0201ecc:	00f58863          	beq	a1,a5,ffffffffc0201edc <strchr+0x12>
ffffffffc0201ed0:	0505                	addi	a0,a0,1
ffffffffc0201ed2:	00054783          	lbu	a5,0(a0)
ffffffffc0201ed6:	fbfd                	bnez	a5,ffffffffc0201ecc <strchr+0x2>
ffffffffc0201ed8:	4501                	li	a0,0
ffffffffc0201eda:	8082                	ret
ffffffffc0201edc:	8082                	ret

ffffffffc0201ede <memset>:
ffffffffc0201ede:	ca01                	beqz	a2,ffffffffc0201eee <memset+0x10>
ffffffffc0201ee0:	962a                	add	a2,a2,a0
ffffffffc0201ee2:	87aa                	mv	a5,a0
ffffffffc0201ee4:	0785                	addi	a5,a5,1
ffffffffc0201ee6:	feb78fa3          	sb	a1,-1(a5)
ffffffffc0201eea:	fef61de3          	bne	a2,a5,ffffffffc0201ee4 <memset+0x6>
ffffffffc0201eee:	8082                	ret
