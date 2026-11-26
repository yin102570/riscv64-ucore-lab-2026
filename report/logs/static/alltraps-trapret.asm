
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200d44 <__alltraps>:
ffffffffc0200d44:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200d48:	00011463          	bnez	sp,ffffffffc0200d50 <__alltraps+0xc>
ffffffffc0200d4c:	14002173          	csrr	sp,sscratch
ffffffffc0200d50:	712d                	addi	sp,sp,-288
ffffffffc0200d52:	e002                	sd	zero,0(sp)
ffffffffc0200d54:	e406                	sd	ra,8(sp)
ffffffffc0200d56:	ec0e                	sd	gp,24(sp)
ffffffffc0200d58:	f012                	sd	tp,32(sp)
ffffffffc0200d5a:	f416                	sd	t0,40(sp)
ffffffffc0200d5c:	f81a                	sd	t1,48(sp)
ffffffffc0200d5e:	fc1e                	sd	t2,56(sp)
ffffffffc0200d60:	e0a2                	sd	s0,64(sp)
ffffffffc0200d62:	e4a6                	sd	s1,72(sp)
ffffffffc0200d64:	e8aa                	sd	a0,80(sp)
ffffffffc0200d66:	ecae                	sd	a1,88(sp)
ffffffffc0200d68:	f0b2                	sd	a2,96(sp)
ffffffffc0200d6a:	f4b6                	sd	a3,104(sp)
ffffffffc0200d6c:	f8ba                	sd	a4,112(sp)
ffffffffc0200d6e:	fcbe                	sd	a5,120(sp)
ffffffffc0200d70:	e142                	sd	a6,128(sp)
ffffffffc0200d72:	e546                	sd	a7,136(sp)
ffffffffc0200d74:	e94a                	sd	s2,144(sp)
ffffffffc0200d76:	ed4e                	sd	s3,152(sp)
ffffffffc0200d78:	f152                	sd	s4,160(sp)
ffffffffc0200d7a:	f556                	sd	s5,168(sp)
ffffffffc0200d7c:	f95a                	sd	s6,176(sp)
ffffffffc0200d7e:	fd5e                	sd	s7,184(sp)
ffffffffc0200d80:	e1e2                	sd	s8,192(sp)
ffffffffc0200d82:	e5e6                	sd	s9,200(sp)
ffffffffc0200d84:	e9ea                	sd	s10,208(sp)
ffffffffc0200d86:	edee                	sd	s11,216(sp)
ffffffffc0200d88:	f1f2                	sd	t3,224(sp)
ffffffffc0200d8a:	f5f6                	sd	t4,232(sp)
ffffffffc0200d8c:	f9fa                	sd	t5,240(sp)
ffffffffc0200d8e:	fdfe                	sd	t6,248(sp)
ffffffffc0200d90:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200d94:	100024f3          	csrr	s1,sstatus
ffffffffc0200d98:	14102973          	csrr	s2,sepc
ffffffffc0200d9c:	143029f3          	csrr	s3,stval
ffffffffc0200da0:	14202a73          	csrr	s4,scause
ffffffffc0200da4:	e822                	sd	s0,16(sp)
ffffffffc0200da6:	e226                	sd	s1,256(sp)
ffffffffc0200da8:	e64a                	sd	s2,264(sp)
ffffffffc0200daa:	ea4e                	sd	s3,272(sp)
ffffffffc0200dac:	ee52                	sd	s4,280(sp)
ffffffffc0200dae:	850a                	mv	a0,sp
ffffffffc0200db0:	f0bff0ef          	jal	ffffffffc0200cba <trap>

ffffffffc0200db4 <__trapret>:
ffffffffc0200db4:	6492                	ld	s1,256(sp)
ffffffffc0200db6:	6932                	ld	s2,264(sp)
ffffffffc0200db8:	1004f413          	andi	s0,s1,256
ffffffffc0200dbc:	e401                	bnez	s0,ffffffffc0200dc4 <__trapret+0x10>
ffffffffc0200dbe:	1200                	addi	s0,sp,288
ffffffffc0200dc0:	14041073          	csrw	sscratch,s0
ffffffffc0200dc4:	10049073          	csrw	sstatus,s1
ffffffffc0200dc8:	14191073          	csrw	sepc,s2
ffffffffc0200dcc:	60a2                	ld	ra,8(sp)
ffffffffc0200dce:	61e2                	ld	gp,24(sp)
ffffffffc0200dd0:	7202                	ld	tp,32(sp)
ffffffffc0200dd2:	72a2                	ld	t0,40(sp)
ffffffffc0200dd4:	7342                	ld	t1,48(sp)
ffffffffc0200dd6:	73e2                	ld	t2,56(sp)
ffffffffc0200dd8:	6406                	ld	s0,64(sp)
ffffffffc0200dda:	64a6                	ld	s1,72(sp)
ffffffffc0200ddc:	6546                	ld	a0,80(sp)
ffffffffc0200dde:	65e6                	ld	a1,88(sp)
ffffffffc0200de0:	7606                	ld	a2,96(sp)
ffffffffc0200de2:	76a6                	ld	a3,104(sp)
ffffffffc0200de4:	7746                	ld	a4,112(sp)
ffffffffc0200de6:	77e6                	ld	a5,120(sp)
ffffffffc0200de8:	680a                	ld	a6,128(sp)
ffffffffc0200dea:	68aa                	ld	a7,136(sp)
ffffffffc0200dec:	694a                	ld	s2,144(sp)
ffffffffc0200dee:	69ea                	ld	s3,152(sp)
ffffffffc0200df0:	7a0a                	ld	s4,160(sp)
ffffffffc0200df2:	7aaa                	ld	s5,168(sp)
ffffffffc0200df4:	7b4a                	ld	s6,176(sp)
ffffffffc0200df6:	7bea                	ld	s7,184(sp)
ffffffffc0200df8:	6c0e                	ld	s8,192(sp)
ffffffffc0200dfa:	6cae                	ld	s9,200(sp)
ffffffffc0200dfc:	6d4e                	ld	s10,208(sp)
ffffffffc0200dfe:	6dee                	ld	s11,216(sp)
ffffffffc0200e00:	7e0e                	ld	t3,224(sp)
ffffffffc0200e02:	7eae                	ld	t4,232(sp)
ffffffffc0200e04:	7f4e                	ld	t5,240(sp)
ffffffffc0200e06:	7fee                	ld	t6,248(sp)
ffffffffc0200e08:	6142                	ld	sp,16(sp)
ffffffffc0200e0a:	10200073          	sret

ffffffffc0200e0e <forkrets>:
ffffffffc0200e0e:	812a                	mv	sp,a0
ffffffffc0200e10:	b755                	j	ffffffffc0200db4 <__trapret>
