
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9f013103          	ld	sp,-1552(sp) # 800089f0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	a1070713          	addi	a4,a4,-1520 # 80008a60 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	15e78793          	addi	a5,a5,350 # 800061c0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc92f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f2478793          	addi	a5,a5,-220 # 80000fd0 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	708080e7          	jalr	1800(ra) # 80002832 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	796080e7          	jalr	1942(ra) # 800008d0 <uartputc>
    for (i = 0; i < n; i++)
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000186:	00060b1b          	sext.w	s6,a2
    acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	a1650513          	addi	a0,a0,-1514 # 80010ba0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b9c080e7          	jalr	-1124(ra) # 80000d2e <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	a0648493          	addi	s1,s1,-1530 # 80010ba0 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a9690913          	addi	s2,s2,-1386 # 80010c38 <cons+0x98>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

        if (c == C('D'))
    800001aa:	4b91                	li	s7,4
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
            break;

        dst++;
        --n;

        if (c == '\n')
    800001ae:	4ca9                	li	s9,10
    while (n > 0)
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
        while (cons.r == cons.w)
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
            if (killed(myproc()))
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	aac080e7          	jalr	-1364(ra) # 80001c6c <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	4b4080e7          	jalr	1204(ra) # 8000267c <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	1fe080e7          	jalr	510(ra) # 800023d4 <sleep>
        while (cons.r == cons.w)
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
        if (c == C('D'))
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
        cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	5ca080e7          	jalr	1482(ra) # 800027dc <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1
        if (c == '\n')
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	97a50513          	addi	a0,a0,-1670 # 80010ba0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	bb4080e7          	jalr	-1100(ra) # 80000de2 <release>

    return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
                release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	96450513          	addi	a0,a0,-1692 # 80010ba0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	b9e080e7          	jalr	-1122(ra) # 80000de2 <release>
                return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
            if (n < target)
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
                cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	9cf72323          	sw	a5,-1594(a4) # 80010c38 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
        uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	572080e7          	jalr	1394(ra) # 800007fe <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
        uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	560080e7          	jalr	1376(ra) # 800007fe <uartputc_sync>
        uartputc_sync(' ');
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	554080e7          	jalr	1364(ra) # 800007fe <uartputc_sync>
        uartputc_sync('\b');
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	54a080e7          	jalr	1354(ra) # 800007fe <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	8d450513          	addi	a0,a0,-1836 # 80010ba0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a5a080e7          	jalr	-1446(ra) # 80000d2e <acquire>

    switch (c)
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	596080e7          	jalr	1430(ra) # 80002888 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	8a650513          	addi	a0,a0,-1882 # 80010ba0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	ae0080e7          	jalr	-1312(ra) # 80000de2 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
    switch (c)
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	88270713          	addi	a4,a4,-1918 # 80010ba0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
            consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	85878793          	addi	a5,a5,-1960 # 80010ba0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8c27a783          	lw	a5,-1854(a5) # 80010c38 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
        while (cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	81670713          	addi	a4,a4,-2026 # 80010ba0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	80648493          	addi	s1,s1,-2042 # 80010ba0 <cons>
        while (cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
            cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
        while (cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	7ca70713          	addi	a4,a4,1994 # 80010ba0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
            cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	84f72a23          	sw	a5,-1964(a4) # 80010c40 <cons+0xa0>
            consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
            consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	78e78793          	addi	a5,a5,1934 # 80010ba0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	80c7a323          	sw	a2,-2042(a5) # 80010c3c <cons+0x9c>
                wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	7fa50513          	addi	a0,a0,2042 # 80010c38 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	ff2080e7          	jalr	-14(ra) # 80002438 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	74050513          	addi	a0,a0,1856 # 80010ba0 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	836080e7          	jalr	-1994(ra) # 80000c9e <initlock>

    uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	33e080e7          	jalr	830(ra) # 800007ae <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000478:	00241797          	auipc	a5,0x241
    8000047c:	8c078793          	addi	a5,a5,-1856 # 80240d38 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
    char buf[16];
    int i;
    uint x;

    if (sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
        x = -xx;
    else
        x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

    i = 0;
    800004b6:	4701                	li	a4,0
    do
    {
        buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
    } while ((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

    if (sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
        buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

    while (--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
        consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
    while (--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
        x = -xx;
    80000538:	40a0053b          	negw	a0,a0
    if (sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
        x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    if (locking)
        release(&pr.lock);
}

void panic(char *s, ...)
{
    80000540:	711d                	addi	sp,sp,-96
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
    8000054c:	e40c                	sd	a1,8(s0)
    8000054e:	e810                	sd	a2,16(s0)
    80000550:	ec14                	sd	a3,24(s0)
    80000552:	f018                	sd	a4,32(s0)
    80000554:	f41c                	sd	a5,40(s0)
    80000556:	03043823          	sd	a6,48(s0)
    8000055a:	03143c23          	sd	a7,56(s0)
    pr.locking = 0;
    8000055e:	00010797          	auipc	a5,0x10
    80000562:	7007a123          	sw	zero,1794(a5) # 80010c60 <pr+0x18>
    printf("panic: ");
    80000566:	00008517          	auipc	a0,0x8
    8000056a:	ab250513          	addi	a0,a0,-1358 # 80008018 <etext+0x18>
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	02e080e7          	jalr	46(ra) # 8000059c <printf>
    printf(s);
    80000576:	8526                	mv	a0,s1
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	024080e7          	jalr	36(ra) # 8000059c <printf>
    printf("\n");
    80000580:	00008517          	auipc	a0,0x8
    80000584:	b8050513          	addi	a0,a0,-1152 # 80008100 <digits+0xc0>
    80000588:	00000097          	auipc	ra,0x0
    8000058c:	014080e7          	jalr	20(ra) # 8000059c <printf>
    panicked = 1; // freeze uart output from other CPUs
    80000590:	4785                	li	a5,1
    80000592:	00008717          	auipc	a4,0x8
    80000596:	46f72f23          	sw	a5,1150(a4) # 80008a10 <panicked>
    for (;;)
    8000059a:	a001                	j	8000059a <panic+0x5a>

000000008000059c <printf>:
{
    8000059c:	7131                	addi	sp,sp,-192
    8000059e:	fc86                	sd	ra,120(sp)
    800005a0:	f8a2                	sd	s0,112(sp)
    800005a2:	f4a6                	sd	s1,104(sp)
    800005a4:	f0ca                	sd	s2,96(sp)
    800005a6:	ecce                	sd	s3,88(sp)
    800005a8:	e8d2                	sd	s4,80(sp)
    800005aa:	e4d6                	sd	s5,72(sp)
    800005ac:	e0da                	sd	s6,64(sp)
    800005ae:	fc5e                	sd	s7,56(sp)
    800005b0:	f862                	sd	s8,48(sp)
    800005b2:	f466                	sd	s9,40(sp)
    800005b4:	f06a                	sd	s10,32(sp)
    800005b6:	ec6e                	sd	s11,24(sp)
    800005b8:	0100                	addi	s0,sp,128
    800005ba:	8a2a                	mv	s4,a0
    800005bc:	e40c                	sd	a1,8(s0)
    800005be:	e810                	sd	a2,16(s0)
    800005c0:	ec14                	sd	a3,24(s0)
    800005c2:	f018                	sd	a4,32(s0)
    800005c4:	f41c                	sd	a5,40(s0)
    800005c6:	03043823          	sd	a6,48(s0)
    800005ca:	03143c23          	sd	a7,56(s0)
    locking = pr.locking;
    800005ce:	00010d97          	auipc	s11,0x10
    800005d2:	692dad83          	lw	s11,1682(s11) # 80010c60 <pr+0x18>
    if (locking)
    800005d6:	020d9b63          	bnez	s11,8000060c <printf+0x70>
    if (fmt == 0)
    800005da:	040a0263          	beqz	s4,8000061e <printf+0x82>
    va_start(ap, fmt);
    800005de:	00840793          	addi	a5,s0,8
    800005e2:	f8f43423          	sd	a5,-120(s0)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    800005e6:	000a4503          	lbu	a0,0(s4)
    800005ea:	14050f63          	beqz	a0,80000748 <printf+0x1ac>
    800005ee:	4981                	li	s3,0
        if (c != '%')
    800005f0:	02500a93          	li	s5,37
        switch (c)
    800005f4:	07000b93          	li	s7,112
    consputc('x');
    800005f8:	4d41                	li	s10,16
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005fa:	00008b17          	auipc	s6,0x8
    800005fe:	a46b0b13          	addi	s6,s6,-1466 # 80008040 <digits>
        switch (c)
    80000602:	07300c93          	li	s9,115
    80000606:	06400c13          	li	s8,100
    8000060a:	a82d                	j	80000644 <printf+0xa8>
        acquire(&pr.lock);
    8000060c:	00010517          	auipc	a0,0x10
    80000610:	63c50513          	addi	a0,a0,1596 # 80010c48 <pr>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	71a080e7          	jalr	1818(ra) # 80000d2e <acquire>
    8000061c:	bf7d                	j	800005da <printf+0x3e>
        panic("null fmt");
    8000061e:	00008517          	auipc	a0,0x8
    80000622:	a0a50513          	addi	a0,a0,-1526 # 80008028 <etext+0x28>
    80000626:	00000097          	auipc	ra,0x0
    8000062a:	f1a080e7          	jalr	-230(ra) # 80000540 <panic>
            consputc(c);
    8000062e:	00000097          	auipc	ra,0x0
    80000632:	c4e080e7          	jalr	-946(ra) # 8000027c <consputc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c503          	lbu	a0,0(a5)
    80000640:	10050463          	beqz	a0,80000748 <printf+0x1ac>
        if (c != '%')
    80000644:	ff5515e3          	bne	a0,s5,8000062e <printf+0x92>
        c = fmt[++i] & 0xff;
    80000648:	2985                	addiw	s3,s3,1
    8000064a:	013a07b3          	add	a5,s4,s3
    8000064e:	0007c783          	lbu	a5,0(a5)
    80000652:	0007849b          	sext.w	s1,a5
        if (c == 0)
    80000656:	cbed                	beqz	a5,80000748 <printf+0x1ac>
        switch (c)
    80000658:	05778a63          	beq	a5,s7,800006ac <printf+0x110>
    8000065c:	02fbf663          	bgeu	s7,a5,80000688 <printf+0xec>
    80000660:	09978863          	beq	a5,s9,800006f0 <printf+0x154>
    80000664:	07800713          	li	a4,120
    80000668:	0ce79563          	bne	a5,a4,80000732 <printf+0x196>
            printint(va_arg(ap, int), 16, 1);
    8000066c:	f8843783          	ld	a5,-120(s0)
    80000670:	00878713          	addi	a4,a5,8
    80000674:	f8e43423          	sd	a4,-120(s0)
    80000678:	4605                	li	a2,1
    8000067a:	85ea                	mv	a1,s10
    8000067c:	4388                	lw	a0,0(a5)
    8000067e:	00000097          	auipc	ra,0x0
    80000682:	e1e080e7          	jalr	-482(ra) # 8000049c <printint>
            break;
    80000686:	bf45                	j	80000636 <printf+0x9a>
        switch (c)
    80000688:	09578f63          	beq	a5,s5,80000726 <printf+0x18a>
    8000068c:	0b879363          	bne	a5,s8,80000732 <printf+0x196>
            printint(va_arg(ap, int), 10, 1);
    80000690:	f8843783          	ld	a5,-120(s0)
    80000694:	00878713          	addi	a4,a5,8
    80000698:	f8e43423          	sd	a4,-120(s0)
    8000069c:	4605                	li	a2,1
    8000069e:	45a9                	li	a1,10
    800006a0:	4388                	lw	a0,0(a5)
    800006a2:	00000097          	auipc	ra,0x0
    800006a6:	dfa080e7          	jalr	-518(ra) # 8000049c <printint>
            break;
    800006aa:	b771                	j	80000636 <printf+0x9a>
            printptr(va_arg(ap, uint64));
    800006ac:	f8843783          	ld	a5,-120(s0)
    800006b0:	00878713          	addi	a4,a5,8
    800006b4:	f8e43423          	sd	a4,-120(s0)
    800006b8:	0007b903          	ld	s2,0(a5)
    consputc('0');
    800006bc:	03000513          	li	a0,48
    800006c0:	00000097          	auipc	ra,0x0
    800006c4:	bbc080e7          	jalr	-1092(ra) # 8000027c <consputc>
    consputc('x');
    800006c8:	07800513          	li	a0,120
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
    800006d4:	84ea                	mv	s1,s10
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d6:	03c95793          	srli	a5,s2,0x3c
    800006da:	97da                	add	a5,a5,s6
    800006dc:	0007c503          	lbu	a0,0(a5)
    800006e0:	00000097          	auipc	ra,0x0
    800006e4:	b9c080e7          	jalr	-1124(ra) # 8000027c <consputc>
    for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e8:	0912                	slli	s2,s2,0x4
    800006ea:	34fd                	addiw	s1,s1,-1
    800006ec:	f4ed                	bnez	s1,800006d6 <printf+0x13a>
    800006ee:	b7a1                	j	80000636 <printf+0x9a>
            if ((s = va_arg(ap, char *)) == 0)
    800006f0:	f8843783          	ld	a5,-120(s0)
    800006f4:	00878713          	addi	a4,a5,8
    800006f8:	f8e43423          	sd	a4,-120(s0)
    800006fc:	6384                	ld	s1,0(a5)
    800006fe:	cc89                	beqz	s1,80000718 <printf+0x17c>
            for (; *s; s++)
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	d90d                	beqz	a0,80000636 <printf+0x9a>
                consputc(*s);
    80000706:	00000097          	auipc	ra,0x0
    8000070a:	b76080e7          	jalr	-1162(ra) # 8000027c <consputc>
            for (; *s; s++)
    8000070e:	0485                	addi	s1,s1,1
    80000710:	0004c503          	lbu	a0,0(s1)
    80000714:	f96d                	bnez	a0,80000706 <printf+0x16a>
    80000716:	b705                	j	80000636 <printf+0x9a>
                s = "(null)";
    80000718:	00008497          	auipc	s1,0x8
    8000071c:	90848493          	addi	s1,s1,-1784 # 80008020 <etext+0x20>
            for (; *s; s++)
    80000720:	02800513          	li	a0,40
    80000724:	b7cd                	j	80000706 <printf+0x16a>
            consputc('%');
    80000726:	8556                	mv	a0,s5
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b54080e7          	jalr	-1196(ra) # 8000027c <consputc>
            break;
    80000730:	b719                	j	80000636 <printf+0x9a>
            consputc('%');
    80000732:	8556                	mv	a0,s5
    80000734:	00000097          	auipc	ra,0x0
    80000738:	b48080e7          	jalr	-1208(ra) # 8000027c <consputc>
            consputc(c);
    8000073c:	8526                	mv	a0,s1
    8000073e:	00000097          	auipc	ra,0x0
    80000742:	b3e080e7          	jalr	-1218(ra) # 8000027c <consputc>
            break;
    80000746:	bdc5                	j	80000636 <printf+0x9a>
    if (locking)
    80000748:	020d9163          	bnez	s11,8000076a <printf+0x1ce>
}
    8000074c:	70e6                	ld	ra,120(sp)
    8000074e:	7446                	ld	s0,112(sp)
    80000750:	74a6                	ld	s1,104(sp)
    80000752:	7906                	ld	s2,96(sp)
    80000754:	69e6                	ld	s3,88(sp)
    80000756:	6a46                	ld	s4,80(sp)
    80000758:	6aa6                	ld	s5,72(sp)
    8000075a:	6b06                	ld	s6,64(sp)
    8000075c:	7be2                	ld	s7,56(sp)
    8000075e:	7c42                	ld	s8,48(sp)
    80000760:	7ca2                	ld	s9,40(sp)
    80000762:	7d02                	ld	s10,32(sp)
    80000764:	6de2                	ld	s11,24(sp)
    80000766:	6129                	addi	sp,sp,192
    80000768:	8082                	ret
        release(&pr.lock);
    8000076a:	00010517          	auipc	a0,0x10
    8000076e:	4de50513          	addi	a0,a0,1246 # 80010c48 <pr>
    80000772:	00000097          	auipc	ra,0x0
    80000776:	670080e7          	jalr	1648(ra) # 80000de2 <release>
}
    8000077a:	bfc9                	j	8000074c <printf+0x1b0>

000000008000077c <printfinit>:
        ;
}

void printfinit(void)
{
    8000077c:	1101                	addi	sp,sp,-32
    8000077e:	ec06                	sd	ra,24(sp)
    80000780:	e822                	sd	s0,16(sp)
    80000782:	e426                	sd	s1,8(sp)
    80000784:	1000                	addi	s0,sp,32
    initlock(&pr.lock, "pr");
    80000786:	00010497          	auipc	s1,0x10
    8000078a:	4c248493          	addi	s1,s1,1218 # 80010c48 <pr>
    8000078e:	00008597          	auipc	a1,0x8
    80000792:	8aa58593          	addi	a1,a1,-1878 # 80008038 <etext+0x38>
    80000796:	8526                	mv	a0,s1
    80000798:	00000097          	auipc	ra,0x0
    8000079c:	506080e7          	jalr	1286(ra) # 80000c9e <initlock>
    pr.locking = 1;
    800007a0:	4785                	li	a5,1
    800007a2:	cc9c                	sw	a5,24(s1)
}
    800007a4:	60e2                	ld	ra,24(sp)
    800007a6:	6442                	ld	s0,16(sp)
    800007a8:	64a2                	ld	s1,8(sp)
    800007aa:	6105                	addi	sp,sp,32
    800007ac:	8082                	ret

00000000800007ae <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007ae:	1141                	addi	sp,sp,-16
    800007b0:	e406                	sd	ra,8(sp)
    800007b2:	e022                	sd	s0,0(sp)
    800007b4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b6:	100007b7          	lui	a5,0x10000
    800007ba:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007be:	f8000713          	li	a4,-128
    800007c2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c6:	470d                	li	a4,3
    800007c8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007cc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007d0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d4:	469d                	li	a3,7
    800007d6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007da:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007de:	00008597          	auipc	a1,0x8
    800007e2:	87a58593          	addi	a1,a1,-1926 # 80008058 <digits+0x18>
    800007e6:	00010517          	auipc	a0,0x10
    800007ea:	48250513          	addi	a0,a0,1154 # 80010c68 <uart_tx_lock>
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	4b0080e7          	jalr	1200(ra) # 80000c9e <initlock>
}
    800007f6:	60a2                	ld	ra,8(sp)
    800007f8:	6402                	ld	s0,0(sp)
    800007fa:	0141                	addi	sp,sp,16
    800007fc:	8082                	ret

00000000800007fe <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fe:	1101                	addi	sp,sp,-32
    80000800:	ec06                	sd	ra,24(sp)
    80000802:	e822                	sd	s0,16(sp)
    80000804:	e426                	sd	s1,8(sp)
    80000806:	1000                	addi	s0,sp,32
    80000808:	84aa                	mv	s1,a0
  push_off();
    8000080a:	00000097          	auipc	ra,0x0
    8000080e:	4d8080e7          	jalr	1240(ra) # 80000ce2 <push_off>

  if(panicked){
    80000812:	00008797          	auipc	a5,0x8
    80000816:	1fe7a783          	lw	a5,510(a5) # 80008a10 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081e:	c391                	beqz	a5,80000822 <uartputc_sync+0x24>
    for(;;)
    80000820:	a001                	j	80000820 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000822:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dfe5                	beqz	a5,80000822 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f513          	zext.b	a0,s1
    80000830:	100007b7          	lui	a5,0x10000
    80000834:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	54a080e7          	jalr	1354(ra) # 80000d82 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	1ce7b783          	ld	a5,462(a5) # 80008a18 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	1ce73703          	ld	a4,462(a4) # 80008a20 <uart_tx_w>
    8000085a:	06f70a63          	beq	a4,a5,800008ce <uartstart+0x84>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000874:	00010a17          	auipc	s4,0x10
    80000878:	3f4a0a13          	addi	s4,s4,1012 # 80010c68 <uart_tx_lock>
    uart_tx_r += 1;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	19c48493          	addi	s1,s1,412 # 80008a18 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	19c98993          	addi	s3,s3,412 # 80008a20 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	02077713          	andi	a4,a4,32
    80000894:	c705                	beqz	a4,800008bc <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f7f713          	andi	a4,a5,31
    8000089a:	9752                	add	a4,a4,s4
    8000089c:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    800008a0:	0785                	addi	a5,a5,1
    800008a2:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	b92080e7          	jalr	-1134(ra) # 80002438 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	609c                	ld	a5,0(s1)
    800008b4:	0009b703          	ld	a4,0(s3)
    800008b8:	fcf71ae3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	38650513          	addi	a0,a0,902 # 80010c68 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	444080e7          	jalr	1092(ra) # 80000d2e <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	11e7a783          	lw	a5,286(a5) # 80008a10 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008717          	auipc	a4,0x8
    80000900:	12473703          	ld	a4,292(a4) # 80008a20 <uart_tx_w>
    80000904:	00008797          	auipc	a5,0x8
    80000908:	1147b783          	ld	a5,276(a5) # 80008a18 <uart_tx_r>
    8000090c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010997          	auipc	s3,0x10
    80000914:	35898993          	addi	s3,s3,856 # 80010c68 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	10048493          	addi	s1,s1,256 # 80008a18 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	10090913          	addi	s2,s2,256 # 80008a20 <uart_tx_w>
    80000928:	00e79f63          	bne	a5,a4,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85ce                	mv	a1,s3
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	aa4080e7          	jalr	-1372(ra) # 800023d4 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093703          	ld	a4,0(s2)
    8000093c:	609c                	ld	a5,0(s1)
    8000093e:	02078793          	addi	a5,a5,32
    80000942:	fee785e3          	beq	a5,a4,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	32248493          	addi	s1,s1,802 # 80010c68 <uart_tx_lock>
    8000094e:	01f77793          	andi	a5,a4,31
    80000952:	97a6                	add	a5,a5,s1
    80000954:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000958:	0705                	addi	a4,a4,1
    8000095a:	00008797          	auipc	a5,0x8
    8000095e:	0ce7b323          	sd	a4,198(a5) # 80008a20 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee8080e7          	jalr	-280(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	476080e7          	jalr	1142(ra) # 80000de2 <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb81                	beqz	a5,800009a6 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a0:	6422                	ld	s0,8(sp)
    800009a2:	0141                	addi	sp,sp,16
    800009a4:	8082                	ret
    return -1;
    800009a6:	557d                	li	a0,-1
    800009a8:	bfe5                	j	800009a0 <uartgetc+0x1a>

00000000800009aa <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009aa:	1101                	addi	sp,sp,-32
    800009ac:	ec06                	sd	ra,24(sp)
    800009ae:	e822                	sd	s0,16(sp)
    800009b0:	e426                	sd	s1,8(sp)
    800009b2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b4:	54fd                	li	s1,-1
    800009b6:	a029                	j	800009c0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009b8:	00000097          	auipc	ra,0x0
    800009bc:	906080e7          	jalr	-1786(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	fc6080e7          	jalr	-58(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c8:	fe9518e3          	bne	a0,s1,800009b8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009cc:	00010497          	auipc	s1,0x10
    800009d0:	29c48493          	addi	s1,s1,668 # 80010c68 <uart_tx_lock>
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	358080e7          	jalr	856(ra) # 80000d2e <acquire>
  uartstart();
    800009de:	00000097          	auipc	ra,0x0
    800009e2:	e6c080e7          	jalr	-404(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    800009e6:	8526                	mv	a0,s1
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	3fa080e7          	jalr	1018(ra) # 80000de2 <release>
}
    800009f0:	60e2                	ld	ra,24(sp)
    800009f2:	6442                	ld	s0,16(sp)
    800009f4:	64a2                	ld	s1,8(sp)
    800009f6:	6105                	addi	sp,sp,32
    800009f8:	8082                	ret

00000000800009fa <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009fa:	1101                	addi	sp,sp,-32
    800009fc:	ec06                	sd	ra,24(sp)
    800009fe:	e822                	sd	s0,16(sp)
    80000a00:	e426                	sd	s1,8(sp)
    80000a02:	e04a                	sd	s2,0(sp)
    80000a04:	1000                	addi	s0,sp,32
    struct run *r;
    r = (struct run *)pa;
    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    80000a06:	03451793          	slli	a5,a0,0x34
    80000a0a:	ebbd                	bnez	a5,80000a80 <kfree+0x86>
    80000a0c:	84aa                	mv	s1,a0
    80000a0e:	00241797          	auipc	a5,0x241
    80000a12:	4c278793          	addi	a5,a5,1218 # 80241ed0 <end>
    80000a16:	06f56563          	bltu	a0,a5,80000a80 <kfree+0x86>
    80000a1a:	47c5                	li	a5,17
    80000a1c:	07ee                	slli	a5,a5,0x1b
    80000a1e:	06f57163          	bgeu	a0,a5,80000a80 <kfree+0x86>
        panic("kfree");
    // when we free the page decraese the refcnt of the pa
    // we need to acquire the lock
    // and get the really current cnt for the current fucntion
    acquire(&kmem.lock);
    80000a22:	00010517          	auipc	a0,0x10
    80000a26:	27e50513          	addi	a0,a0,638 # 80010ca0 <kmem>
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	304080e7          	jalr	772(ra) # 80000d2e <acquire>
    int pn = (uint64)r / PGSIZE;
    80000a32:	00c4d793          	srli	a5,s1,0xc
    80000a36:	2781                	sext.w	a5,a5
    if (refcnt[pn] < 1)
    80000a38:	00279693          	slli	a3,a5,0x2
    80000a3c:	00010717          	auipc	a4,0x10
    80000a40:	28470713          	addi	a4,a4,644 # 80010cc0 <refcnt>
    80000a44:	9736                	add	a4,a4,a3
    80000a46:	4318                	lw	a4,0(a4)
    80000a48:	04e05463          	blez	a4,80000a90 <kfree+0x96>
        panic("kfree panic");
    refcnt[pn] -= 1;
    80000a4c:	377d                	addiw	a4,a4,-1
    80000a4e:	0007091b          	sext.w	s2,a4
    80000a52:	078a                	slli	a5,a5,0x2
    80000a54:	00010697          	auipc	a3,0x10
    80000a58:	26c68693          	addi	a3,a3,620 # 80010cc0 <refcnt>
    80000a5c:	97b6                	add	a5,a5,a3
    80000a5e:	c398                	sw	a4,0(a5)
    int tmp = refcnt[pn];
    release(&kmem.lock);
    80000a60:	00010517          	auipc	a0,0x10
    80000a64:	24050513          	addi	a0,a0,576 # 80010ca0 <kmem>
    80000a68:	00000097          	auipc	ra,0x0
    80000a6c:	37a080e7          	jalr	890(ra) # 80000de2 <release>

    if (tmp > 0)
    80000a70:	03205863          	blez	s2,80000aa0 <kfree+0xa6>

    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
}
    80000a74:	60e2                	ld	ra,24(sp)
    80000a76:	6442                	ld	s0,16(sp)
    80000a78:	64a2                	ld	s1,8(sp)
    80000a7a:	6902                	ld	s2,0(sp)
    80000a7c:	6105                	addi	sp,sp,32
    80000a7e:	8082                	ret
        panic("kfree");
    80000a80:	00007517          	auipc	a0,0x7
    80000a84:	5e050513          	addi	a0,a0,1504 # 80008060 <digits+0x20>
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	ab8080e7          	jalr	-1352(ra) # 80000540 <panic>
        panic("kfree panic");
    80000a90:	00007517          	auipc	a0,0x7
    80000a94:	5d850513          	addi	a0,a0,1496 # 80008068 <digits+0x28>
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	aa8080e7          	jalr	-1368(ra) # 80000540 <panic>
    memset(pa, 1, PGSIZE);
    80000aa0:	6605                	lui	a2,0x1
    80000aa2:	4585                	li	a1,1
    80000aa4:	8526                	mv	a0,s1
    80000aa6:	00000097          	auipc	ra,0x0
    80000aaa:	384080e7          	jalr	900(ra) # 80000e2a <memset>
    acquire(&kmem.lock);
    80000aae:	00010917          	auipc	s2,0x10
    80000ab2:	1f290913          	addi	s2,s2,498 # 80010ca0 <kmem>
    80000ab6:	854a                	mv	a0,s2
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	276080e7          	jalr	630(ra) # 80000d2e <acquire>
    r->next = kmem.freelist;
    80000ac0:	01893783          	ld	a5,24(s2)
    80000ac4:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000ac6:	00993c23          	sd	s1,24(s2)
    release(&kmem.lock);
    80000aca:	854a                	mv	a0,s2
    80000acc:	00000097          	auipc	ra,0x0
    80000ad0:	316080e7          	jalr	790(ra) # 80000de2 <release>
    80000ad4:	b745                	j	80000a74 <kfree+0x7a>

0000000080000ad6 <freerange>:
{
    80000ad6:	7139                	addi	sp,sp,-64
    80000ad8:	fc06                	sd	ra,56(sp)
    80000ada:	f822                	sd	s0,48(sp)
    80000adc:	f426                	sd	s1,40(sp)
    80000ade:	f04a                	sd	s2,32(sp)
    80000ae0:	ec4e                	sd	s3,24(sp)
    80000ae2:	e852                	sd	s4,16(sp)
    80000ae4:	e456                	sd	s5,8(sp)
    80000ae6:	e05a                	sd	s6,0(sp)
    80000ae8:	0080                	addi	s0,sp,64
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000aea:	6785                	lui	a5,0x1
    80000aec:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000af0:	953a                	add	a0,a0,a4
    80000af2:	777d                	lui	a4,0xfffff
    80000af4:	00e574b3          	and	s1,a0,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000af8:	97a6                	add	a5,a5,s1
    80000afa:	02f5ea63          	bltu	a1,a5,80000b2e <freerange+0x58>
    80000afe:	892e                	mv	s2,a1
        refcnt[(uint64)p / PGSIZE] = 1;
    80000b00:	00010b17          	auipc	s6,0x10
    80000b04:	1c0b0b13          	addi	s6,s6,448 # 80010cc0 <refcnt>
    80000b08:	4a85                	li	s5,1
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b0a:	6a05                	lui	s4,0x1
    80000b0c:	6989                	lui	s3,0x2
        refcnt[(uint64)p / PGSIZE] = 1;
    80000b0e:	00c4d793          	srli	a5,s1,0xc
    80000b12:	078a                	slli	a5,a5,0x2
    80000b14:	97da                	add	a5,a5,s6
    80000b16:	0157a023          	sw	s5,0(a5)
        kfree(p);
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	ede080e7          	jalr	-290(ra) # 800009fa <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b24:	87a6                	mv	a5,s1
    80000b26:	94d2                	add	s1,s1,s4
    80000b28:	97ce                	add	a5,a5,s3
    80000b2a:	fef972e3          	bgeu	s2,a5,80000b0e <freerange+0x38>
}
    80000b2e:	70e2                	ld	ra,56(sp)
    80000b30:	7442                	ld	s0,48(sp)
    80000b32:	74a2                	ld	s1,40(sp)
    80000b34:	7902                	ld	s2,32(sp)
    80000b36:	69e2                	ld	s3,24(sp)
    80000b38:	6a42                	ld	s4,16(sp)
    80000b3a:	6aa2                	ld	s5,8(sp)
    80000b3c:	6b02                	ld	s6,0(sp)
    80000b3e:	6121                	addi	sp,sp,64
    80000b40:	8082                	ret

0000000080000b42 <kinit>:
{
    80000b42:	1141                	addi	sp,sp,-16
    80000b44:	e406                	sd	ra,8(sp)
    80000b46:	e022                	sd	s0,0(sp)
    80000b48:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000b4a:	00007597          	auipc	a1,0x7
    80000b4e:	52e58593          	addi	a1,a1,1326 # 80008078 <digits+0x38>
    80000b52:	00010517          	auipc	a0,0x10
    80000b56:	14e50513          	addi	a0,a0,334 # 80010ca0 <kmem>
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	144080e7          	jalr	324(ra) # 80000c9e <initlock>
    freerange(end, (void *)PHYSTOP);
    80000b62:	45c5                	li	a1,17
    80000b64:	05ee                	slli	a1,a1,0x1b
    80000b66:	00241517          	auipc	a0,0x241
    80000b6a:	36a50513          	addi	a0,a0,874 # 80241ed0 <end>
    80000b6e:	00000097          	auipc	ra,0x0
    80000b72:	f68080e7          	jalr	-152(ra) # 80000ad6 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000b76:	00008797          	auipc	a5,0x8
    80000b7a:	eb27b783          	ld	a5,-334(a5) # 80008a28 <FREE_PAGES>
    80000b7e:	00008717          	auipc	a4,0x8
    80000b82:	eaf73923          	sd	a5,-334(a4) # 80008a30 <MAX_PAGES>
}
    80000b86:	60a2                	ld	ra,8(sp)
    80000b88:	6402                	ld	s0,0(sp)
    80000b8a:	0141                	addi	sp,sp,16
    80000b8c:	8082                	ret

0000000080000b8e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b8e:	1101                	addi	sp,sp,-32
    80000b90:	ec06                	sd	ra,24(sp)
    80000b92:	e822                	sd	s0,16(sp)
    80000b94:	e426                	sd	s1,8(sp)
    80000b96:	1000                	addi	s0,sp,32
    struct run *r;

    acquire(&kmem.lock);
    80000b98:	00010497          	auipc	s1,0x10
    80000b9c:	10848493          	addi	s1,s1,264 # 80010ca0 <kmem>
    80000ba0:	8526                	mv	a0,s1
    80000ba2:	00000097          	auipc	ra,0x0
    80000ba6:	18c080e7          	jalr	396(ra) # 80000d2e <acquire>
    r = kmem.freelist;
    80000baa:	6c84                	ld	s1,24(s1)

    if (r)
    80000bac:	c4a5                	beqz	s1,80000c14 <kalloc+0x86>
    {
        int pn = (uint64)r / PGSIZE;
    80000bae:	00c4d793          	srli	a5,s1,0xc
    80000bb2:	2781                	sext.w	a5,a5
        if (refcnt[pn] != 0)
    80000bb4:	00279693          	slli	a3,a5,0x2
    80000bb8:	00010717          	auipc	a4,0x10
    80000bbc:	10870713          	addi	a4,a4,264 # 80010cc0 <refcnt>
    80000bc0:	9736                	add	a4,a4,a3
    80000bc2:	4318                	lw	a4,0(a4)
    80000bc4:	e321                	bnez	a4,80000c04 <kalloc+0x76>
        {
            panic("refcnt kalloc");
        }
        refcnt[pn] = 1;
    80000bc6:	078a                	slli	a5,a5,0x2
    80000bc8:	00010717          	auipc	a4,0x10
    80000bcc:	0f870713          	addi	a4,a4,248 # 80010cc0 <refcnt>
    80000bd0:	97ba                	add	a5,a5,a4
    80000bd2:	4705                	li	a4,1
    80000bd4:	c398                	sw	a4,0(a5)
        kmem.freelist = r->next;
    80000bd6:	609c                	ld	a5,0(s1)
    80000bd8:	00010517          	auipc	a0,0x10
    80000bdc:	0c850513          	addi	a0,a0,200 # 80010ca0 <kmem>
    80000be0:	ed1c                	sd	a5,24(a0)
    }

    release(&kmem.lock);
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	200080e7          	jalr	512(ra) # 80000de2 <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000bea:	6605                	lui	a2,0x1
    80000bec:	4595                	li	a1,5
    80000bee:	8526                	mv	a0,s1
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	23a080e7          	jalr	570(ra) # 80000e2a <memset>
    return (void *)r;
}
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	60e2                	ld	ra,24(sp)
    80000bfc:	6442                	ld	s0,16(sp)
    80000bfe:	64a2                	ld	s1,8(sp)
    80000c00:	6105                	addi	sp,sp,32
    80000c02:	8082                	ret
            panic("refcnt kalloc");
    80000c04:	00007517          	auipc	a0,0x7
    80000c08:	47c50513          	addi	a0,a0,1148 # 80008080 <digits+0x40>
    80000c0c:	00000097          	auipc	ra,0x0
    80000c10:	934080e7          	jalr	-1740(ra) # 80000540 <panic>
    release(&kmem.lock);
    80000c14:	00010517          	auipc	a0,0x10
    80000c18:	08c50513          	addi	a0,a0,140 # 80010ca0 <kmem>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	1c6080e7          	jalr	454(ra) # 80000de2 <release>
    if (r)
    80000c24:	bfd1                	j	80000bf8 <kalloc+0x6a>

0000000080000c26 <increse>:

void increse(uint64 pa)
{
    80000c26:	1101                	addi	sp,sp,-32
    80000c28:	ec06                	sd	ra,24(sp)
    80000c2a:	e822                	sd	s0,16(sp)
    80000c2c:	e426                	sd	s1,8(sp)
    80000c2e:	1000                	addi	s0,sp,32
    80000c30:	84aa                	mv	s1,a0
    // acquire the lock
    acquire(&kmem.lock);
    80000c32:	00010517          	auipc	a0,0x10
    80000c36:	06e50513          	addi	a0,a0,110 # 80010ca0 <kmem>
    80000c3a:	00000097          	auipc	ra,0x0
    80000c3e:	0f4080e7          	jalr	244(ra) # 80000d2e <acquire>
    int pn = pa / PGSIZE;
    if (pa > PHYSTOP || refcnt[pn] < 1)
    80000c42:	4745                	li	a4,17
    80000c44:	076e                	slli	a4,a4,0x1b
    80000c46:	04976463          	bltu	a4,s1,80000c8e <increse+0x68>
    80000c4a:	00c4d793          	srli	a5,s1,0xc
    80000c4e:	2781                	sext.w	a5,a5
    80000c50:	00279693          	slli	a3,a5,0x2
    80000c54:	00010717          	auipc	a4,0x10
    80000c58:	06c70713          	addi	a4,a4,108 # 80010cc0 <refcnt>
    80000c5c:	9736                	add	a4,a4,a3
    80000c5e:	4318                	lw	a4,0(a4)
    80000c60:	02e05763          	blez	a4,80000c8e <increse+0x68>
    {
        panic("increase ref cnt");
    }
    refcnt[pn]++;
    80000c64:	078a                	slli	a5,a5,0x2
    80000c66:	00010697          	auipc	a3,0x10
    80000c6a:	05a68693          	addi	a3,a3,90 # 80010cc0 <refcnt>
    80000c6e:	97b6                	add	a5,a5,a3
    80000c70:	2705                	addiw	a4,a4,1
    80000c72:	c398                	sw	a4,0(a5)
    release(&kmem.lock);
    80000c74:	00010517          	auipc	a0,0x10
    80000c78:	02c50513          	addi	a0,a0,44 # 80010ca0 <kmem>
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	166080e7          	jalr	358(ra) # 80000de2 <release>
}
    80000c84:	60e2                	ld	ra,24(sp)
    80000c86:	6442                	ld	s0,16(sp)
    80000c88:	64a2                	ld	s1,8(sp)
    80000c8a:	6105                	addi	sp,sp,32
    80000c8c:	8082                	ret
        panic("increase ref cnt");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8aa080e7          	jalr	-1878(ra) # 80000540 <panic>

0000000080000c9e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c9e:	1141                	addi	sp,sp,-16
    80000ca0:	e422                	sd	s0,8(sp)
    80000ca2:	0800                	addi	s0,sp,16
  lk->name = name;
    80000ca4:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000ca6:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000caa:	00053823          	sd	zero,16(a0)
}
    80000cae:	6422                	ld	s0,8(sp)
    80000cb0:	0141                	addi	sp,sp,16
    80000cb2:	8082                	ret

0000000080000cb4 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000cb4:	411c                	lw	a5,0(a0)
    80000cb6:	e399                	bnez	a5,80000cbc <holding+0x8>
    80000cb8:	4501                	li	a0,0
  return r;
}
    80000cba:	8082                	ret
{
    80000cbc:	1101                	addi	sp,sp,-32
    80000cbe:	ec06                	sd	ra,24(sp)
    80000cc0:	e822                	sd	s0,16(sp)
    80000cc2:	e426                	sd	s1,8(sp)
    80000cc4:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cc6:	6904                	ld	s1,16(a0)
    80000cc8:	00001097          	auipc	ra,0x1
    80000ccc:	f88080e7          	jalr	-120(ra) # 80001c50 <mycpu>
    80000cd0:	40a48533          	sub	a0,s1,a0
    80000cd4:	00153513          	seqz	a0,a0
}
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret

0000000080000ce2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000ce2:	1101                	addi	sp,sp,-32
    80000ce4:	ec06                	sd	ra,24(sp)
    80000ce6:	e822                	sd	s0,16(sp)
    80000ce8:	e426                	sd	s1,8(sp)
    80000cea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cec:	100024f3          	csrr	s1,sstatus
    80000cf0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cf4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cf6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cfa:	00001097          	auipc	ra,0x1
    80000cfe:	f56080e7          	jalr	-170(ra) # 80001c50 <mycpu>
    80000d02:	5d3c                	lw	a5,120(a0)
    80000d04:	cf89                	beqz	a5,80000d1e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d06:	00001097          	auipc	ra,0x1
    80000d0a:	f4a080e7          	jalr	-182(ra) # 80001c50 <mycpu>
    80000d0e:	5d3c                	lw	a5,120(a0)
    80000d10:	2785                	addiw	a5,a5,1
    80000d12:	dd3c                	sw	a5,120(a0)
}
    80000d14:	60e2                	ld	ra,24(sp)
    80000d16:	6442                	ld	s0,16(sp)
    80000d18:	64a2                	ld	s1,8(sp)
    80000d1a:	6105                	addi	sp,sp,32
    80000d1c:	8082                	ret
    mycpu()->intena = old;
    80000d1e:	00001097          	auipc	ra,0x1
    80000d22:	f32080e7          	jalr	-206(ra) # 80001c50 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d26:	8085                	srli	s1,s1,0x1
    80000d28:	8885                	andi	s1,s1,1
    80000d2a:	dd64                	sw	s1,124(a0)
    80000d2c:	bfe9                	j	80000d06 <push_off+0x24>

0000000080000d2e <acquire>:
{
    80000d2e:	1101                	addi	sp,sp,-32
    80000d30:	ec06                	sd	ra,24(sp)
    80000d32:	e822                	sd	s0,16(sp)
    80000d34:	e426                	sd	s1,8(sp)
    80000d36:	1000                	addi	s0,sp,32
    80000d38:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d3a:	00000097          	auipc	ra,0x0
    80000d3e:	fa8080e7          	jalr	-88(ra) # 80000ce2 <push_off>
  if(holding(lk))
    80000d42:	8526                	mv	a0,s1
    80000d44:	00000097          	auipc	ra,0x0
    80000d48:	f70080e7          	jalr	-144(ra) # 80000cb4 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d4c:	4705                	li	a4,1
  if(holding(lk))
    80000d4e:	e115                	bnez	a0,80000d72 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d50:	87ba                	mv	a5,a4
    80000d52:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d56:	2781                	sext.w	a5,a5
    80000d58:	ffe5                	bnez	a5,80000d50 <acquire+0x22>
  __sync_synchronize();
    80000d5a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d5e:	00001097          	auipc	ra,0x1
    80000d62:	ef2080e7          	jalr	-270(ra) # 80001c50 <mycpu>
    80000d66:	e888                	sd	a0,16(s1)
}
    80000d68:	60e2                	ld	ra,24(sp)
    80000d6a:	6442                	ld	s0,16(sp)
    80000d6c:	64a2                	ld	s1,8(sp)
    80000d6e:	6105                	addi	sp,sp,32
    80000d70:	8082                	ret
    panic("acquire");
    80000d72:	00007517          	auipc	a0,0x7
    80000d76:	33650513          	addi	a0,a0,822 # 800080a8 <digits+0x68>
    80000d7a:	fffff097          	auipc	ra,0xfffff
    80000d7e:	7c6080e7          	jalr	1990(ra) # 80000540 <panic>

0000000080000d82 <pop_off>:

void
pop_off(void)
{
    80000d82:	1141                	addi	sp,sp,-16
    80000d84:	e406                	sd	ra,8(sp)
    80000d86:	e022                	sd	s0,0(sp)
    80000d88:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d8a:	00001097          	auipc	ra,0x1
    80000d8e:	ec6080e7          	jalr	-314(ra) # 80001c50 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d92:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d96:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d98:	e78d                	bnez	a5,80000dc2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d9a:	5d3c                	lw	a5,120(a0)
    80000d9c:	02f05b63          	blez	a5,80000dd2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000da0:	37fd                	addiw	a5,a5,-1
    80000da2:	0007871b          	sext.w	a4,a5
    80000da6:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000da8:	eb09                	bnez	a4,80000dba <pop_off+0x38>
    80000daa:	5d7c                	lw	a5,124(a0)
    80000dac:	c799                	beqz	a5,80000dba <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000db2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000db6:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000dba:	60a2                	ld	ra,8(sp)
    80000dbc:	6402                	ld	s0,0(sp)
    80000dbe:	0141                	addi	sp,sp,16
    80000dc0:	8082                	ret
    panic("pop_off - interruptible");
    80000dc2:	00007517          	auipc	a0,0x7
    80000dc6:	2ee50513          	addi	a0,a0,750 # 800080b0 <digits+0x70>
    80000dca:	fffff097          	auipc	ra,0xfffff
    80000dce:	776080e7          	jalr	1910(ra) # 80000540 <panic>
    panic("pop_off");
    80000dd2:	00007517          	auipc	a0,0x7
    80000dd6:	2f650513          	addi	a0,a0,758 # 800080c8 <digits+0x88>
    80000dda:	fffff097          	auipc	ra,0xfffff
    80000dde:	766080e7          	jalr	1894(ra) # 80000540 <panic>

0000000080000de2 <release>:
{
    80000de2:	1101                	addi	sp,sp,-32
    80000de4:	ec06                	sd	ra,24(sp)
    80000de6:	e822                	sd	s0,16(sp)
    80000de8:	e426                	sd	s1,8(sp)
    80000dea:	1000                	addi	s0,sp,32
    80000dec:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dee:	00000097          	auipc	ra,0x0
    80000df2:	ec6080e7          	jalr	-314(ra) # 80000cb4 <holding>
    80000df6:	c115                	beqz	a0,80000e1a <release+0x38>
  lk->cpu = 0;
    80000df8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dfc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e00:	0f50000f          	fence	iorw,ow
    80000e04:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e08:	00000097          	auipc	ra,0x0
    80000e0c:	f7a080e7          	jalr	-134(ra) # 80000d82 <pop_off>
}
    80000e10:	60e2                	ld	ra,24(sp)
    80000e12:	6442                	ld	s0,16(sp)
    80000e14:	64a2                	ld	s1,8(sp)
    80000e16:	6105                	addi	sp,sp,32
    80000e18:	8082                	ret
    panic("release");
    80000e1a:	00007517          	auipc	a0,0x7
    80000e1e:	2b650513          	addi	a0,a0,694 # 800080d0 <digits+0x90>
    80000e22:	fffff097          	auipc	ra,0xfffff
    80000e26:	71e080e7          	jalr	1822(ra) # 80000540 <panic>

0000000080000e2a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e2a:	1141                	addi	sp,sp,-16
    80000e2c:	e422                	sd	s0,8(sp)
    80000e2e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e30:	ca19                	beqz	a2,80000e46 <memset+0x1c>
    80000e32:	87aa                	mv	a5,a0
    80000e34:	1602                	slli	a2,a2,0x20
    80000e36:	9201                	srli	a2,a2,0x20
    80000e38:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e3c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e40:	0785                	addi	a5,a5,1
    80000e42:	fee79de3          	bne	a5,a4,80000e3c <memset+0x12>
  }
  return dst;
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret

0000000080000e4c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e4c:	1141                	addi	sp,sp,-16
    80000e4e:	e422                	sd	s0,8(sp)
    80000e50:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e52:	ca05                	beqz	a2,80000e82 <memcmp+0x36>
    80000e54:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000e58:	1682                	slli	a3,a3,0x20
    80000e5a:	9281                	srli	a3,a3,0x20
    80000e5c:	0685                	addi	a3,a3,1
    80000e5e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	0005c703          	lbu	a4,0(a1)
    80000e68:	00e79863          	bne	a5,a4,80000e78 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e6c:	0505                	addi	a0,a0,1
    80000e6e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e70:	fed518e3          	bne	a0,a3,80000e60 <memcmp+0x14>
  }

  return 0;
    80000e74:	4501                	li	a0,0
    80000e76:	a019                	j	80000e7c <memcmp+0x30>
      return *s1 - *s2;
    80000e78:	40e7853b          	subw	a0,a5,a4
}
    80000e7c:	6422                	ld	s0,8(sp)
    80000e7e:	0141                	addi	sp,sp,16
    80000e80:	8082                	ret
  return 0;
    80000e82:	4501                	li	a0,0
    80000e84:	bfe5                	j	80000e7c <memcmp+0x30>

0000000080000e86 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e86:	1141                	addi	sp,sp,-16
    80000e88:	e422                	sd	s0,8(sp)
    80000e8a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e8c:	c205                	beqz	a2,80000eac <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e8e:	02a5e263          	bltu	a1,a0,80000eb2 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e92:	1602                	slli	a2,a2,0x20
    80000e94:	9201                	srli	a2,a2,0x20
    80000e96:	00c587b3          	add	a5,a1,a2
{
    80000e9a:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e9c:	0585                	addi	a1,a1,1
    80000e9e:	0705                	addi	a4,a4,1
    80000ea0:	fff5c683          	lbu	a3,-1(a1)
    80000ea4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000ea8:	fef59ae3          	bne	a1,a5,80000e9c <memmove+0x16>

  return dst;
}
    80000eac:	6422                	ld	s0,8(sp)
    80000eae:	0141                	addi	sp,sp,16
    80000eb0:	8082                	ret
  if(s < d && s + n > d){
    80000eb2:	02061693          	slli	a3,a2,0x20
    80000eb6:	9281                	srli	a3,a3,0x20
    80000eb8:	00d58733          	add	a4,a1,a3
    80000ebc:	fce57be3          	bgeu	a0,a4,80000e92 <memmove+0xc>
    d += n;
    80000ec0:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ec2:	fff6079b          	addiw	a5,a2,-1
    80000ec6:	1782                	slli	a5,a5,0x20
    80000ec8:	9381                	srli	a5,a5,0x20
    80000eca:	fff7c793          	not	a5,a5
    80000ece:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000ed0:	177d                	addi	a4,a4,-1
    80000ed2:	16fd                	addi	a3,a3,-1
    80000ed4:	00074603          	lbu	a2,0(a4)
    80000ed8:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000edc:	fee79ae3          	bne	a5,a4,80000ed0 <memmove+0x4a>
    80000ee0:	b7f1                	j	80000eac <memmove+0x26>

0000000080000ee2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ee2:	1141                	addi	sp,sp,-16
    80000ee4:	e406                	sd	ra,8(sp)
    80000ee6:	e022                	sd	s0,0(sp)
    80000ee8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000eea:	00000097          	auipc	ra,0x0
    80000eee:	f9c080e7          	jalr	-100(ra) # 80000e86 <memmove>
}
    80000ef2:	60a2                	ld	ra,8(sp)
    80000ef4:	6402                	ld	s0,0(sp)
    80000ef6:	0141                	addi	sp,sp,16
    80000ef8:	8082                	ret

0000000080000efa <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000efa:	1141                	addi	sp,sp,-16
    80000efc:	e422                	sd	s0,8(sp)
    80000efe:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f00:	ce11                	beqz	a2,80000f1c <strncmp+0x22>
    80000f02:	00054783          	lbu	a5,0(a0)
    80000f06:	cf89                	beqz	a5,80000f20 <strncmp+0x26>
    80000f08:	0005c703          	lbu	a4,0(a1)
    80000f0c:	00f71a63          	bne	a4,a5,80000f20 <strncmp+0x26>
    n--, p++, q++;
    80000f10:	367d                	addiw	a2,a2,-1
    80000f12:	0505                	addi	a0,a0,1
    80000f14:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f16:	f675                	bnez	a2,80000f02 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f18:	4501                	li	a0,0
    80000f1a:	a809                	j	80000f2c <strncmp+0x32>
    80000f1c:	4501                	li	a0,0
    80000f1e:	a039                	j	80000f2c <strncmp+0x32>
  if(n == 0)
    80000f20:	ca09                	beqz	a2,80000f32 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f22:	00054503          	lbu	a0,0(a0)
    80000f26:	0005c783          	lbu	a5,0(a1)
    80000f2a:	9d1d                	subw	a0,a0,a5
}
    80000f2c:	6422                	ld	s0,8(sp)
    80000f2e:	0141                	addi	sp,sp,16
    80000f30:	8082                	ret
    return 0;
    80000f32:	4501                	li	a0,0
    80000f34:	bfe5                	j	80000f2c <strncmp+0x32>

0000000080000f36 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f36:	1141                	addi	sp,sp,-16
    80000f38:	e422                	sd	s0,8(sp)
    80000f3a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f3c:	872a                	mv	a4,a0
    80000f3e:	8832                	mv	a6,a2
    80000f40:	367d                	addiw	a2,a2,-1
    80000f42:	01005963          	blez	a6,80000f54 <strncpy+0x1e>
    80000f46:	0705                	addi	a4,a4,1
    80000f48:	0005c783          	lbu	a5,0(a1)
    80000f4c:	fef70fa3          	sb	a5,-1(a4)
    80000f50:	0585                	addi	a1,a1,1
    80000f52:	f7f5                	bnez	a5,80000f3e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f54:	86ba                	mv	a3,a4
    80000f56:	00c05c63          	blez	a2,80000f6e <strncpy+0x38>
    *s++ = 0;
    80000f5a:	0685                	addi	a3,a3,1
    80000f5c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f60:	40d707bb          	subw	a5,a4,a3
    80000f64:	37fd                	addiw	a5,a5,-1
    80000f66:	010787bb          	addw	a5,a5,a6
    80000f6a:	fef048e3          	bgtz	a5,80000f5a <strncpy+0x24>
  return os;
}
    80000f6e:	6422                	ld	s0,8(sp)
    80000f70:	0141                	addi	sp,sp,16
    80000f72:	8082                	ret

0000000080000f74 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f74:	1141                	addi	sp,sp,-16
    80000f76:	e422                	sd	s0,8(sp)
    80000f78:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f7a:	02c05363          	blez	a2,80000fa0 <safestrcpy+0x2c>
    80000f7e:	fff6069b          	addiw	a3,a2,-1
    80000f82:	1682                	slli	a3,a3,0x20
    80000f84:	9281                	srli	a3,a3,0x20
    80000f86:	96ae                	add	a3,a3,a1
    80000f88:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f8a:	00d58963          	beq	a1,a3,80000f9c <safestrcpy+0x28>
    80000f8e:	0585                	addi	a1,a1,1
    80000f90:	0785                	addi	a5,a5,1
    80000f92:	fff5c703          	lbu	a4,-1(a1)
    80000f96:	fee78fa3          	sb	a4,-1(a5)
    80000f9a:	fb65                	bnez	a4,80000f8a <safestrcpy+0x16>
    ;
  *s = 0;
    80000f9c:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <strlen>:

int
strlen(const char *s)
{
    80000fa6:	1141                	addi	sp,sp,-16
    80000fa8:	e422                	sd	s0,8(sp)
    80000faa:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fac:	00054783          	lbu	a5,0(a0)
    80000fb0:	cf91                	beqz	a5,80000fcc <strlen+0x26>
    80000fb2:	0505                	addi	a0,a0,1
    80000fb4:	87aa                	mv	a5,a0
    80000fb6:	4685                	li	a3,1
    80000fb8:	9e89                	subw	a3,a3,a0
    80000fba:	00f6853b          	addw	a0,a3,a5
    80000fbe:	0785                	addi	a5,a5,1
    80000fc0:	fff7c703          	lbu	a4,-1(a5)
    80000fc4:	fb7d                	bnez	a4,80000fba <strlen+0x14>
    ;
  return n;
}
    80000fc6:	6422                	ld	s0,8(sp)
    80000fc8:	0141                	addi	sp,sp,16
    80000fca:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fcc:	4501                	li	a0,0
    80000fce:	bfe5                	j	80000fc6 <strlen+0x20>

0000000080000fd0 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fd0:	1141                	addi	sp,sp,-16
    80000fd2:	e406                	sd	ra,8(sp)
    80000fd4:	e022                	sd	s0,0(sp)
    80000fd6:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fd8:	00001097          	auipc	ra,0x1
    80000fdc:	c68080e7          	jalr	-920(ra) # 80001c40 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fe0:	00008717          	auipc	a4,0x8
    80000fe4:	a5870713          	addi	a4,a4,-1448 # 80008a38 <started>
  if(cpuid() == 0){
    80000fe8:	c139                	beqz	a0,8000102e <main+0x5e>
    while(started == 0)
    80000fea:	431c                	lw	a5,0(a4)
    80000fec:	2781                	sext.w	a5,a5
    80000fee:	dff5                	beqz	a5,80000fea <main+0x1a>
      ;
    __sync_synchronize();
    80000ff0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ff4:	00001097          	auipc	ra,0x1
    80000ff8:	c4c080e7          	jalr	-948(ra) # 80001c40 <cpuid>
    80000ffc:	85aa                	mv	a1,a0
    80000ffe:	00007517          	auipc	a0,0x7
    80001002:	0f250513          	addi	a0,a0,242 # 800080f0 <digits+0xb0>
    80001006:	fffff097          	auipc	ra,0xfffff
    8000100a:	596080e7          	jalr	1430(ra) # 8000059c <printf>
    kvminithart();    // turn on paging
    8000100e:	00000097          	auipc	ra,0x0
    80001012:	0d8080e7          	jalr	216(ra) # 800010e6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001016:	00002097          	auipc	ra,0x2
    8000101a:	af6080e7          	jalr	-1290(ra) # 80002b0c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000101e:	00005097          	auipc	ra,0x5
    80001022:	1e2080e7          	jalr	482(ra) # 80006200 <plicinithart>
  }

  scheduler();        
    80001026:	00001097          	auipc	ra,0x1
    8000102a:	28c080e7          	jalr	652(ra) # 800022b2 <scheduler>
    consoleinit();
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	422080e7          	jalr	1058(ra) # 80000450 <consoleinit>
    printfinit();
    80001036:	fffff097          	auipc	ra,0xfffff
    8000103a:	746080e7          	jalr	1862(ra) # 8000077c <printfinit>
    printf("\n");
    8000103e:	00007517          	auipc	a0,0x7
    80001042:	0c250513          	addi	a0,a0,194 # 80008100 <digits+0xc0>
    80001046:	fffff097          	auipc	ra,0xfffff
    8000104a:	556080e7          	jalr	1366(ra) # 8000059c <printf>
    printf("xv6 kernel is booting\n");
    8000104e:	00007517          	auipc	a0,0x7
    80001052:	08a50513          	addi	a0,a0,138 # 800080d8 <digits+0x98>
    80001056:	fffff097          	auipc	ra,0xfffff
    8000105a:	546080e7          	jalr	1350(ra) # 8000059c <printf>
    printf("\n");
    8000105e:	00007517          	auipc	a0,0x7
    80001062:	0a250513          	addi	a0,a0,162 # 80008100 <digits+0xc0>
    80001066:	fffff097          	auipc	ra,0xfffff
    8000106a:	536080e7          	jalr	1334(ra) # 8000059c <printf>
    kinit();         // physical page allocator
    8000106e:	00000097          	auipc	ra,0x0
    80001072:	ad4080e7          	jalr	-1324(ra) # 80000b42 <kinit>
    kvminit();       // create kernel page table
    80001076:	00000097          	auipc	ra,0x0
    8000107a:	326080e7          	jalr	806(ra) # 8000139c <kvminit>
    kvminithart();   // turn on paging
    8000107e:	00000097          	auipc	ra,0x0
    80001082:	068080e7          	jalr	104(ra) # 800010e6 <kvminithart>
    procinit();      // process table
    80001086:	00001097          	auipc	ra,0x1
    8000108a:	ad8080e7          	jalr	-1320(ra) # 80001b5e <procinit>
    trapinit();      // trap vectors
    8000108e:	00002097          	auipc	ra,0x2
    80001092:	a56080e7          	jalr	-1450(ra) # 80002ae4 <trapinit>
    trapinithart();  // install kernel trap vector
    80001096:	00002097          	auipc	ra,0x2
    8000109a:	a76080e7          	jalr	-1418(ra) # 80002b0c <trapinithart>
    plicinit();      // set up interrupt controller
    8000109e:	00005097          	auipc	ra,0x5
    800010a2:	14c080e7          	jalr	332(ra) # 800061ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010a6:	00005097          	auipc	ra,0x5
    800010aa:	15a080e7          	jalr	346(ra) # 80006200 <plicinithart>
    binit();         // buffer cache
    800010ae:	00002097          	auipc	ra,0x2
    800010b2:	2fc080e7          	jalr	764(ra) # 800033aa <binit>
    iinit();         // inode table
    800010b6:	00003097          	auipc	ra,0x3
    800010ba:	99c080e7          	jalr	-1636(ra) # 80003a52 <iinit>
    fileinit();      // file table
    800010be:	00004097          	auipc	ra,0x4
    800010c2:	942080e7          	jalr	-1726(ra) # 80004a00 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010c6:	00005097          	auipc	ra,0x5
    800010ca:	242080e7          	jalr	578(ra) # 80006308 <virtio_disk_init>
    userinit();      // first user process
    800010ce:	00001097          	auipc	ra,0x1
    800010d2:	e76080e7          	jalr	-394(ra) # 80001f44 <userinit>
    __sync_synchronize();
    800010d6:	0ff0000f          	fence
    started = 1;
    800010da:	4785                	li	a5,1
    800010dc:	00008717          	auipc	a4,0x8
    800010e0:	94f72e23          	sw	a5,-1700(a4) # 80008a38 <started>
    800010e4:	b789                	j	80001026 <main+0x56>

00000000800010e6 <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    800010e6:	1141                	addi	sp,sp,-16
    800010e8:	e422                	sd	s0,8(sp)
    800010ea:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010ec:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010f0:	00008797          	auipc	a5,0x8
    800010f4:	9507b783          	ld	a5,-1712(a5) # 80008a40 <kernel_pagetable>
    800010f8:	83b1                	srli	a5,a5,0xc
    800010fa:	577d                	li	a4,-1
    800010fc:	177e                	slli	a4,a4,0x3f
    800010fe:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001100:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001104:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001108:	6422                	ld	s0,8(sp)
    8000110a:	0141                	addi	sp,sp,16
    8000110c:	8082                	ret

000000008000110e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000110e:	7139                	addi	sp,sp,-64
    80001110:	fc06                	sd	ra,56(sp)
    80001112:	f822                	sd	s0,48(sp)
    80001114:	f426                	sd	s1,40(sp)
    80001116:	f04a                	sd	s2,32(sp)
    80001118:	ec4e                	sd	s3,24(sp)
    8000111a:	e852                	sd	s4,16(sp)
    8000111c:	e456                	sd	s5,8(sp)
    8000111e:	e05a                	sd	s6,0(sp)
    80001120:	0080                	addi	s0,sp,64
    80001122:	84aa                	mv	s1,a0
    80001124:	89ae                	mv	s3,a1
    80001126:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    80001128:	57fd                	li	a5,-1
    8000112a:	83e9                	srli	a5,a5,0x1a
    8000112c:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    8000112e:	4b31                	li	s6,12
  if (va >= MAXVA)
    80001130:	04b7f263          	bgeu	a5,a1,80001174 <walk+0x66>
    panic("walk");
    80001134:	00007517          	auipc	a0,0x7
    80001138:	fd450513          	addi	a0,a0,-44 # 80008108 <digits+0xc8>
    8000113c:	fffff097          	auipc	ra,0xfffff
    80001140:	404080e7          	jalr	1028(ra) # 80000540 <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    80001144:	060a8663          	beqz	s5,800011b0 <walk+0xa2>
    80001148:	00000097          	auipc	ra,0x0
    8000114c:	a46080e7          	jalr	-1466(ra) # 80000b8e <kalloc>
    80001150:	84aa                	mv	s1,a0
    80001152:	c529                	beqz	a0,8000119c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001154:	6605                	lui	a2,0x1
    80001156:	4581                	li	a1,0
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	cd2080e7          	jalr	-814(ra) # 80000e2a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001160:	00c4d793          	srli	a5,s1,0xc
    80001164:	07aa                	slli	a5,a5,0xa
    80001166:	0017e793          	ori	a5,a5,1
    8000116a:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    8000116e:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    80001170:	036a0063          	beq	s4,s6,80001190 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001174:	0149d933          	srl	s2,s3,s4
    80001178:	1ff97913          	andi	s2,s2,511
    8000117c:	090e                	slli	s2,s2,0x3
    8000117e:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    80001180:	00093483          	ld	s1,0(s2)
    80001184:	0014f793          	andi	a5,s1,1
    80001188:	dfd5                	beqz	a5,80001144 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000118a:	80a9                	srli	s1,s1,0xa
    8000118c:	04b2                	slli	s1,s1,0xc
    8000118e:	b7c5                	j	8000116e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001190:	00c9d513          	srli	a0,s3,0xc
    80001194:	1ff57513          	andi	a0,a0,511
    80001198:	050e                	slli	a0,a0,0x3
    8000119a:	9526                	add	a0,a0,s1
}
    8000119c:	70e2                	ld	ra,56(sp)
    8000119e:	7442                	ld	s0,48(sp)
    800011a0:	74a2                	ld	s1,40(sp)
    800011a2:	7902                	ld	s2,32(sp)
    800011a4:	69e2                	ld	s3,24(sp)
    800011a6:	6a42                	ld	s4,16(sp)
    800011a8:	6aa2                	ld	s5,8(sp)
    800011aa:	6b02                	ld	s6,0(sp)
    800011ac:	6121                	addi	sp,sp,64
    800011ae:	8082                	ret
        return 0;
    800011b0:	4501                	li	a0,0
    800011b2:	b7ed                	j	8000119c <walk+0x8e>

00000000800011b4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    800011b4:	57fd                	li	a5,-1
    800011b6:	83e9                	srli	a5,a5,0x1a
    800011b8:	00b7f463          	bgeu	a5,a1,800011c0 <walkaddr+0xc>
    return 0;
    800011bc:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011be:	8082                	ret
{
    800011c0:	1141                	addi	sp,sp,-16
    800011c2:	e406                	sd	ra,8(sp)
    800011c4:	e022                	sd	s0,0(sp)
    800011c6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011c8:	4601                	li	a2,0
    800011ca:	00000097          	auipc	ra,0x0
    800011ce:	f44080e7          	jalr	-188(ra) # 8000110e <walk>
  if (pte == 0)
    800011d2:	c105                	beqz	a0,800011f2 <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    800011d4:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    800011d6:	0117f693          	andi	a3,a5,17
    800011da:	4745                	li	a4,17
    return 0;
    800011dc:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    800011de:	00e68663          	beq	a3,a4,800011ea <walkaddr+0x36>
}
    800011e2:	60a2                	ld	ra,8(sp)
    800011e4:	6402                	ld	s0,0(sp)
    800011e6:	0141                	addi	sp,sp,16
    800011e8:	8082                	ret
  pa = PTE2PA(*pte);
    800011ea:	83a9                	srli	a5,a5,0xa
    800011ec:	00c79513          	slli	a0,a5,0xc
  return pa;
    800011f0:	bfcd                	j	800011e2 <walkaddr+0x2e>
    return 0;
    800011f2:	4501                	li	a0,0
    800011f4:	b7fd                	j	800011e2 <walkaddr+0x2e>

00000000800011f6 <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011f6:	715d                	addi	sp,sp,-80
    800011f8:	e486                	sd	ra,72(sp)
    800011fa:	e0a2                	sd	s0,64(sp)
    800011fc:	fc26                	sd	s1,56(sp)
    800011fe:	f84a                	sd	s2,48(sp)
    80001200:	f44e                	sd	s3,40(sp)
    80001202:	f052                	sd	s4,32(sp)
    80001204:	ec56                	sd	s5,24(sp)
    80001206:	e85a                	sd	s6,16(sp)
    80001208:	e45e                	sd	s7,8(sp)
    8000120a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    8000120c:	c639                	beqz	a2,8000125a <mappages+0x64>
    8000120e:	8aaa                	mv	s5,a0
    80001210:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    80001212:	777d                	lui	a4,0xfffff
    80001214:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001218:	fff58993          	addi	s3,a1,-1
    8000121c:	99b2                	add	s3,s3,a2
    8000121e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001222:	893e                	mv	s2,a5
    80001224:	40f68a33          	sub	s4,a3,a5
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    80001228:	6b85                	lui	s7,0x1
    8000122a:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    8000122e:	4605                	li	a2,1
    80001230:	85ca                	mv	a1,s2
    80001232:	8556                	mv	a0,s5
    80001234:	00000097          	auipc	ra,0x0
    80001238:	eda080e7          	jalr	-294(ra) # 8000110e <walk>
    8000123c:	cd1d                	beqz	a0,8000127a <mappages+0x84>
    if (*pte & PTE_V)
    8000123e:	611c                	ld	a5,0(a0)
    80001240:	8b85                	andi	a5,a5,1
    80001242:	e785                	bnez	a5,8000126a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001244:	80b1                	srli	s1,s1,0xc
    80001246:	04aa                	slli	s1,s1,0xa
    80001248:	0164e4b3          	or	s1,s1,s6
    8000124c:	0014e493          	ori	s1,s1,1
    80001250:	e104                	sd	s1,0(a0)
    if (a == last)
    80001252:	05390063          	beq	s2,s3,80001292 <mappages+0x9c>
    a += PGSIZE;
    80001256:	995e                	add	s2,s2,s7
    if ((pte = walk(pagetable, a, 1)) == 0)
    80001258:	bfc9                	j	8000122a <mappages+0x34>
    panic("mappages: size");
    8000125a:	00007517          	auipc	a0,0x7
    8000125e:	eb650513          	addi	a0,a0,-330 # 80008110 <digits+0xd0>
    80001262:	fffff097          	auipc	ra,0xfffff
    80001266:	2de080e7          	jalr	734(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000126a:	00007517          	auipc	a0,0x7
    8000126e:	eb650513          	addi	a0,a0,-330 # 80008120 <digits+0xe0>
    80001272:	fffff097          	auipc	ra,0xfffff
    80001276:	2ce080e7          	jalr	718(ra) # 80000540 <panic>
      return -1;
    8000127a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000127c:	60a6                	ld	ra,72(sp)
    8000127e:	6406                	ld	s0,64(sp)
    80001280:	74e2                	ld	s1,56(sp)
    80001282:	7942                	ld	s2,48(sp)
    80001284:	79a2                	ld	s3,40(sp)
    80001286:	7a02                	ld	s4,32(sp)
    80001288:	6ae2                	ld	s5,24(sp)
    8000128a:	6b42                	ld	s6,16(sp)
    8000128c:	6ba2                	ld	s7,8(sp)
    8000128e:	6161                	addi	sp,sp,80
    80001290:	8082                	ret
  return 0;
    80001292:	4501                	li	a0,0
    80001294:	b7e5                	j	8000127c <mappages+0x86>

0000000080001296 <kvmmap>:
{
    80001296:	1141                	addi	sp,sp,-16
    80001298:	e406                	sd	ra,8(sp)
    8000129a:	e022                	sd	s0,0(sp)
    8000129c:	0800                	addi	s0,sp,16
    8000129e:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012a0:	86b2                	mv	a3,a2
    800012a2:	863e                	mv	a2,a5
    800012a4:	00000097          	auipc	ra,0x0
    800012a8:	f52080e7          	jalr	-174(ra) # 800011f6 <mappages>
    800012ac:	e509                	bnez	a0,800012b6 <kvmmap+0x20>
}
    800012ae:	60a2                	ld	ra,8(sp)
    800012b0:	6402                	ld	s0,0(sp)
    800012b2:	0141                	addi	sp,sp,16
    800012b4:	8082                	ret
    panic("kvmmap");
    800012b6:	00007517          	auipc	a0,0x7
    800012ba:	e7a50513          	addi	a0,a0,-390 # 80008130 <digits+0xf0>
    800012be:	fffff097          	auipc	ra,0xfffff
    800012c2:	282080e7          	jalr	642(ra) # 80000540 <panic>

00000000800012c6 <kvmmake>:
{
    800012c6:	1101                	addi	sp,sp,-32
    800012c8:	ec06                	sd	ra,24(sp)
    800012ca:	e822                	sd	s0,16(sp)
    800012cc:	e426                	sd	s1,8(sp)
    800012ce:	e04a                	sd	s2,0(sp)
    800012d0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	8bc080e7          	jalr	-1860(ra) # 80000b8e <kalloc>
    800012da:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012dc:	6605                	lui	a2,0x1
    800012de:	4581                	li	a1,0
    800012e0:	00000097          	auipc	ra,0x0
    800012e4:	b4a080e7          	jalr	-1206(ra) # 80000e2a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012e8:	4719                	li	a4,6
    800012ea:	6685                	lui	a3,0x1
    800012ec:	10000637          	lui	a2,0x10000
    800012f0:	100005b7          	lui	a1,0x10000
    800012f4:	8526                	mv	a0,s1
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	fa0080e7          	jalr	-96(ra) # 80001296 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012fe:	4719                	li	a4,6
    80001300:	6685                	lui	a3,0x1
    80001302:	10001637          	lui	a2,0x10001
    80001306:	100015b7          	lui	a1,0x10001
    8000130a:	8526                	mv	a0,s1
    8000130c:	00000097          	auipc	ra,0x0
    80001310:	f8a080e7          	jalr	-118(ra) # 80001296 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001314:	4719                	li	a4,6
    80001316:	004006b7          	lui	a3,0x400
    8000131a:	0c000637          	lui	a2,0xc000
    8000131e:	0c0005b7          	lui	a1,0xc000
    80001322:	8526                	mv	a0,s1
    80001324:	00000097          	auipc	ra,0x0
    80001328:	f72080e7          	jalr	-142(ra) # 80001296 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    8000132c:	00007917          	auipc	s2,0x7
    80001330:	cd490913          	addi	s2,s2,-812 # 80008000 <etext>
    80001334:	4729                	li	a4,10
    80001336:	80007697          	auipc	a3,0x80007
    8000133a:	cca68693          	addi	a3,a3,-822 # 8000 <_entry-0x7fff8000>
    8000133e:	4605                	li	a2,1
    80001340:	067e                	slli	a2,a2,0x1f
    80001342:	85b2                	mv	a1,a2
    80001344:	8526                	mv	a0,s1
    80001346:	00000097          	auipc	ra,0x0
    8000134a:	f50080e7          	jalr	-176(ra) # 80001296 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    8000134e:	4719                	li	a4,6
    80001350:	46c5                	li	a3,17
    80001352:	06ee                	slli	a3,a3,0x1b
    80001354:	412686b3          	sub	a3,a3,s2
    80001358:	864a                	mv	a2,s2
    8000135a:	85ca                	mv	a1,s2
    8000135c:	8526                	mv	a0,s1
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	f38080e7          	jalr	-200(ra) # 80001296 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001366:	4729                	li	a4,10
    80001368:	6685                	lui	a3,0x1
    8000136a:	00006617          	auipc	a2,0x6
    8000136e:	c9660613          	addi	a2,a2,-874 # 80007000 <_trampoline>
    80001372:	040005b7          	lui	a1,0x4000
    80001376:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001378:	05b2                	slli	a1,a1,0xc
    8000137a:	8526                	mv	a0,s1
    8000137c:	00000097          	auipc	ra,0x0
    80001380:	f1a080e7          	jalr	-230(ra) # 80001296 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001384:	8526                	mv	a0,s1
    80001386:	00000097          	auipc	ra,0x0
    8000138a:	742080e7          	jalr	1858(ra) # 80001ac8 <proc_mapstacks>
}
    8000138e:	8526                	mv	a0,s1
    80001390:	60e2                	ld	ra,24(sp)
    80001392:	6442                	ld	s0,16(sp)
    80001394:	64a2                	ld	s1,8(sp)
    80001396:	6902                	ld	s2,0(sp)
    80001398:	6105                	addi	sp,sp,32
    8000139a:	8082                	ret

000000008000139c <kvminit>:
{
    8000139c:	1141                	addi	sp,sp,-16
    8000139e:	e406                	sd	ra,8(sp)
    800013a0:	e022                	sd	s0,0(sp)
    800013a2:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	f22080e7          	jalr	-222(ra) # 800012c6 <kvmmake>
    800013ac:	00007797          	auipc	a5,0x7
    800013b0:	68a7ba23          	sd	a0,1684(a5) # 80008a40 <kernel_pagetable>
}
    800013b4:	60a2                	ld	ra,8(sp)
    800013b6:	6402                	ld	s0,0(sp)
    800013b8:	0141                	addi	sp,sp,16
    800013ba:	8082                	ret

00000000800013bc <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013bc:	715d                	addi	sp,sp,-80
    800013be:	e486                	sd	ra,72(sp)
    800013c0:	e0a2                	sd	s0,64(sp)
    800013c2:	fc26                	sd	s1,56(sp)
    800013c4:	f84a                	sd	s2,48(sp)
    800013c6:	f44e                	sd	s3,40(sp)
    800013c8:	f052                	sd	s4,32(sp)
    800013ca:	ec56                	sd	s5,24(sp)
    800013cc:	e85a                	sd	s6,16(sp)
    800013ce:	e45e                	sd	s7,8(sp)
    800013d0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    800013d2:	03459793          	slli	a5,a1,0x34
    800013d6:	e795                	bnez	a5,80001402 <uvmunmap+0x46>
    800013d8:	8a2a                	mv	s4,a0
    800013da:	892e                	mv	s2,a1
    800013dc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800013de:	0632                	slli	a2,a2,0xc
    800013e0:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    800013e4:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800013e6:	6b05                	lui	s6,0x1
    800013e8:	0735e263          	bltu	a1,s3,8000144c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    800013ec:	60a6                	ld	ra,72(sp)
    800013ee:	6406                	ld	s0,64(sp)
    800013f0:	74e2                	ld	s1,56(sp)
    800013f2:	7942                	ld	s2,48(sp)
    800013f4:	79a2                	ld	s3,40(sp)
    800013f6:	7a02                	ld	s4,32(sp)
    800013f8:	6ae2                	ld	s5,24(sp)
    800013fa:	6b42                	ld	s6,16(sp)
    800013fc:	6ba2                	ld	s7,8(sp)
    800013fe:	6161                	addi	sp,sp,80
    80001400:	8082                	ret
    panic("uvmunmap: not aligned");
    80001402:	00007517          	auipc	a0,0x7
    80001406:	d3650513          	addi	a0,a0,-714 # 80008138 <digits+0xf8>
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	136080e7          	jalr	310(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001412:	00007517          	auipc	a0,0x7
    80001416:	d3e50513          	addi	a0,a0,-706 # 80008150 <digits+0x110>
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	126080e7          	jalr	294(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001422:	00007517          	auipc	a0,0x7
    80001426:	d3e50513          	addi	a0,a0,-706 # 80008160 <digits+0x120>
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	116080e7          	jalr	278(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001432:	00007517          	auipc	a0,0x7
    80001436:	d4650513          	addi	a0,a0,-698 # 80008178 <digits+0x138>
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	106080e7          	jalr	262(ra) # 80000540 <panic>
    *pte = 0;
    80001442:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001446:	995a                	add	s2,s2,s6
    80001448:	fb3972e3          	bgeu	s2,s3,800013ec <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    8000144c:	4601                	li	a2,0
    8000144e:	85ca                	mv	a1,s2
    80001450:	8552                	mv	a0,s4
    80001452:	00000097          	auipc	ra,0x0
    80001456:	cbc080e7          	jalr	-836(ra) # 8000110e <walk>
    8000145a:	84aa                	mv	s1,a0
    8000145c:	d95d                	beqz	a0,80001412 <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    8000145e:	6108                	ld	a0,0(a0)
    80001460:	00157793          	andi	a5,a0,1
    80001464:	dfdd                	beqz	a5,80001422 <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    80001466:	3ff57793          	andi	a5,a0,1023
    8000146a:	fd7784e3          	beq	a5,s7,80001432 <uvmunmap+0x76>
    if (do_free)
    8000146e:	fc0a8ae3          	beqz	s5,80001442 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001472:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    80001474:	0532                	slli	a0,a0,0xc
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	584080e7          	jalr	1412(ra) # 800009fa <kfree>
    8000147e:	b7d1                	j	80001442 <uvmunmap+0x86>

0000000080001480 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001480:	1101                	addi	sp,sp,-32
    80001482:	ec06                	sd	ra,24(sp)
    80001484:	e822                	sd	s0,16(sp)
    80001486:	e426                	sd	s1,8(sp)
    80001488:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    8000148a:	fffff097          	auipc	ra,0xfffff
    8000148e:	704080e7          	jalr	1796(ra) # 80000b8e <kalloc>
    80001492:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001494:	c519                	beqz	a0,800014a2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001496:	6605                	lui	a2,0x1
    80001498:	4581                	li	a1,0
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	990080e7          	jalr	-1648(ra) # 80000e2a <memset>
  return pagetable;
}
    800014a2:	8526                	mv	a0,s1
    800014a4:	60e2                	ld	ra,24(sp)
    800014a6:	6442                	ld	s0,16(sp)
    800014a8:	64a2                	ld	s1,8(sp)
    800014aa:	6105                	addi	sp,sp,32
    800014ac:	8082                	ret

00000000800014ae <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800014ae:	7179                	addi	sp,sp,-48
    800014b0:	f406                	sd	ra,40(sp)
    800014b2:	f022                	sd	s0,32(sp)
    800014b4:	ec26                	sd	s1,24(sp)
    800014b6:	e84a                	sd	s2,16(sp)
    800014b8:	e44e                	sd	s3,8(sp)
    800014ba:	e052                	sd	s4,0(sp)
    800014bc:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    800014be:	6785                	lui	a5,0x1
    800014c0:	04f67863          	bgeu	a2,a5,80001510 <uvmfirst+0x62>
    800014c4:	8a2a                	mv	s4,a0
    800014c6:	89ae                	mv	s3,a1
    800014c8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014ca:	fffff097          	auipc	ra,0xfffff
    800014ce:	6c4080e7          	jalr	1732(ra) # 80000b8e <kalloc>
    800014d2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014d4:	6605                	lui	a2,0x1
    800014d6:	4581                	li	a1,0
    800014d8:	00000097          	auipc	ra,0x0
    800014dc:	952080e7          	jalr	-1710(ra) # 80000e2a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    800014e0:	4779                	li	a4,30
    800014e2:	86ca                	mv	a3,s2
    800014e4:	6605                	lui	a2,0x1
    800014e6:	4581                	li	a1,0
    800014e8:	8552                	mv	a0,s4
    800014ea:	00000097          	auipc	ra,0x0
    800014ee:	d0c080e7          	jalr	-756(ra) # 800011f6 <mappages>
  memmove(mem, src, sz);
    800014f2:	8626                	mv	a2,s1
    800014f4:	85ce                	mv	a1,s3
    800014f6:	854a                	mv	a0,s2
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	98e080e7          	jalr	-1650(ra) # 80000e86 <memmove>
}
    80001500:	70a2                	ld	ra,40(sp)
    80001502:	7402                	ld	s0,32(sp)
    80001504:	64e2                	ld	s1,24(sp)
    80001506:	6942                	ld	s2,16(sp)
    80001508:	69a2                	ld	s3,8(sp)
    8000150a:	6a02                	ld	s4,0(sp)
    8000150c:	6145                	addi	sp,sp,48
    8000150e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001510:	00007517          	auipc	a0,0x7
    80001514:	c8050513          	addi	a0,a0,-896 # 80008190 <digits+0x150>
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	028080e7          	jalr	40(ra) # 80000540 <panic>

0000000080001520 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001520:	1101                	addi	sp,sp,-32
    80001522:	ec06                	sd	ra,24(sp)
    80001524:	e822                	sd	s0,16(sp)
    80001526:	e426                	sd	s1,8(sp)
    80001528:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    8000152a:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    8000152c:	00b67d63          	bgeu	a2,a1,80001546 <uvmdealloc+0x26>
    80001530:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    80001532:	6785                	lui	a5,0x1
    80001534:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001536:	00f60733          	add	a4,a2,a5
    8000153a:	76fd                	lui	a3,0xfffff
    8000153c:	8f75                	and	a4,a4,a3
    8000153e:	97ae                	add	a5,a5,a1
    80001540:	8ff5                	and	a5,a5,a3
    80001542:	00f76863          	bltu	a4,a5,80001552 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001546:	8526                	mv	a0,s1
    80001548:	60e2                	ld	ra,24(sp)
    8000154a:	6442                	ld	s0,16(sp)
    8000154c:	64a2                	ld	s1,8(sp)
    8000154e:	6105                	addi	sp,sp,32
    80001550:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001552:	8f99                	sub	a5,a5,a4
    80001554:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001556:	4685                	li	a3,1
    80001558:	0007861b          	sext.w	a2,a5
    8000155c:	85ba                	mv	a1,a4
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	e5e080e7          	jalr	-418(ra) # 800013bc <uvmunmap>
    80001566:	b7c5                	j	80001546 <uvmdealloc+0x26>

0000000080001568 <uvmalloc>:
  if (newsz < oldsz)
    80001568:	0ab66563          	bltu	a2,a1,80001612 <uvmalloc+0xaa>
{
    8000156c:	7139                	addi	sp,sp,-64
    8000156e:	fc06                	sd	ra,56(sp)
    80001570:	f822                	sd	s0,48(sp)
    80001572:	f426                	sd	s1,40(sp)
    80001574:	f04a                	sd	s2,32(sp)
    80001576:	ec4e                	sd	s3,24(sp)
    80001578:	e852                	sd	s4,16(sp)
    8000157a:	e456                	sd	s5,8(sp)
    8000157c:	e05a                	sd	s6,0(sp)
    8000157e:	0080                	addi	s0,sp,64
    80001580:	8aaa                	mv	s5,a0
    80001582:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001584:	6785                	lui	a5,0x1
    80001586:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001588:	95be                	add	a1,a1,a5
    8000158a:	77fd                	lui	a5,0xfffff
    8000158c:	00f5f9b3          	and	s3,a1,a5
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001590:	08c9f363          	bgeu	s3,a2,80001616 <uvmalloc+0xae>
    80001594:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001596:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000159a:	fffff097          	auipc	ra,0xfffff
    8000159e:	5f4080e7          	jalr	1524(ra) # 80000b8e <kalloc>
    800015a2:	84aa                	mv	s1,a0
    if (mem == 0)
    800015a4:	c51d                	beqz	a0,800015d2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015a6:	6605                	lui	a2,0x1
    800015a8:	4581                	li	a1,0
    800015aa:	00000097          	auipc	ra,0x0
    800015ae:	880080e7          	jalr	-1920(ra) # 80000e2a <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    800015b2:	875a                	mv	a4,s6
    800015b4:	86a6                	mv	a3,s1
    800015b6:	6605                	lui	a2,0x1
    800015b8:	85ca                	mv	a1,s2
    800015ba:	8556                	mv	a0,s5
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	c3a080e7          	jalr	-966(ra) # 800011f6 <mappages>
    800015c4:	e90d                	bnez	a0,800015f6 <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    800015c6:	6785                	lui	a5,0x1
    800015c8:	993e                	add	s2,s2,a5
    800015ca:	fd4968e3          	bltu	s2,s4,8000159a <uvmalloc+0x32>
  return newsz;
    800015ce:	8552                	mv	a0,s4
    800015d0:	a809                	j	800015e2 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800015d2:	864e                	mv	a2,s3
    800015d4:	85ca                	mv	a1,s2
    800015d6:	8556                	mv	a0,s5
    800015d8:	00000097          	auipc	ra,0x0
    800015dc:	f48080e7          	jalr	-184(ra) # 80001520 <uvmdealloc>
      return 0;
    800015e0:	4501                	li	a0,0
}
    800015e2:	70e2                	ld	ra,56(sp)
    800015e4:	7442                	ld	s0,48(sp)
    800015e6:	74a2                	ld	s1,40(sp)
    800015e8:	7902                	ld	s2,32(sp)
    800015ea:	69e2                	ld	s3,24(sp)
    800015ec:	6a42                	ld	s4,16(sp)
    800015ee:	6aa2                	ld	s5,8(sp)
    800015f0:	6b02                	ld	s6,0(sp)
    800015f2:	6121                	addi	sp,sp,64
    800015f4:	8082                	ret
      kfree(mem);
    800015f6:	8526                	mv	a0,s1
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	402080e7          	jalr	1026(ra) # 800009fa <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001600:	864e                	mv	a2,s3
    80001602:	85ca                	mv	a1,s2
    80001604:	8556                	mv	a0,s5
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	f1a080e7          	jalr	-230(ra) # 80001520 <uvmdealloc>
      return 0;
    8000160e:	4501                	li	a0,0
    80001610:	bfc9                	j	800015e2 <uvmalloc+0x7a>
    return oldsz;
    80001612:	852e                	mv	a0,a1
}
    80001614:	8082                	ret
  return newsz;
    80001616:	8532                	mv	a0,a2
    80001618:	b7e9                	j	800015e2 <uvmalloc+0x7a>

000000008000161a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    8000161a:	7179                	addi	sp,sp,-48
    8000161c:	f406                	sd	ra,40(sp)
    8000161e:	f022                	sd	s0,32(sp)
    80001620:	ec26                	sd	s1,24(sp)
    80001622:	e84a                	sd	s2,16(sp)
    80001624:	e44e                	sd	s3,8(sp)
    80001626:	e052                	sd	s4,0(sp)
    80001628:	1800                	addi	s0,sp,48
    8000162a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    8000162c:	84aa                	mv	s1,a0
    8000162e:	6905                	lui	s2,0x1
    80001630:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001632:	4985                	li	s3,1
    80001634:	a829                	j	8000164e <freewalk+0x34>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001636:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001638:	00c79513          	slli	a0,a5,0xc
    8000163c:	00000097          	auipc	ra,0x0
    80001640:	fde080e7          	jalr	-34(ra) # 8000161a <freewalk>
      pagetable[i] = 0;
    80001644:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    80001648:	04a1                	addi	s1,s1,8
    8000164a:	03248163          	beq	s1,s2,8000166c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000164e:	609c                	ld	a5,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    80001650:	00f7f713          	andi	a4,a5,15
    80001654:	ff3701e3          	beq	a4,s3,80001636 <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    80001658:	8b85                	andi	a5,a5,1
    8000165a:	d7fd                	beqz	a5,80001648 <freewalk+0x2e>
    {
      panic("freewalk: leaf");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b5450513          	addi	a0,a0,-1196 # 800081b0 <digits+0x170>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>
    }
  }
  kfree((void *)pagetable);
    8000166c:	8552                	mv	a0,s4
    8000166e:	fffff097          	auipc	ra,0xfffff
    80001672:	38c080e7          	jalr	908(ra) # 800009fa <kfree>
}
    80001676:	70a2                	ld	ra,40(sp)
    80001678:	7402                	ld	s0,32(sp)
    8000167a:	64e2                	ld	s1,24(sp)
    8000167c:	6942                	ld	s2,16(sp)
    8000167e:	69a2                	ld	s3,8(sp)
    80001680:	6a02                	ld	s4,0(sp)
    80001682:	6145                	addi	sp,sp,48
    80001684:	8082                	ret

0000000080001686 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001686:	1101                	addi	sp,sp,-32
    80001688:	ec06                	sd	ra,24(sp)
    8000168a:	e822                	sd	s0,16(sp)
    8000168c:	e426                	sd	s1,8(sp)
    8000168e:	1000                	addi	s0,sp,32
    80001690:	84aa                	mv	s1,a0
  if (sz > 0)
    80001692:	e999                	bnez	a1,800016a8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    80001694:	8526                	mv	a0,s1
    80001696:	00000097          	auipc	ra,0x0
    8000169a:	f84080e7          	jalr	-124(ra) # 8000161a <freewalk>
}
    8000169e:	60e2                	ld	ra,24(sp)
    800016a0:	6442                	ld	s0,16(sp)
    800016a2:	64a2                	ld	s1,8(sp)
    800016a4:	6105                	addi	sp,sp,32
    800016a6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    800016a8:	6785                	lui	a5,0x1
    800016aa:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016ac:	95be                	add	a1,a1,a5
    800016ae:	4685                	li	a3,1
    800016b0:	00c5d613          	srli	a2,a1,0xc
    800016b4:	4581                	li	a1,0
    800016b6:	00000097          	auipc	ra,0x0
    800016ba:	d06080e7          	jalr	-762(ra) # 800013bc <uvmunmap>
    800016be:	bfd9                	j	80001694 <uvmfree+0xe>

00000000800016c0 <uvmcopy>:
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for (i = 0; i < sz; i += PGSIZE)
    800016c0:	ca55                	beqz	a2,80001774 <uvmcopy+0xb4>
{
    800016c2:	7139                	addi	sp,sp,-64
    800016c4:	fc06                	sd	ra,56(sp)
    800016c6:	f822                	sd	s0,48(sp)
    800016c8:	f426                	sd	s1,40(sp)
    800016ca:	f04a                	sd	s2,32(sp)
    800016cc:	ec4e                	sd	s3,24(sp)
    800016ce:	e852                	sd	s4,16(sp)
    800016d0:	e456                	sd	s5,8(sp)
    800016d2:	e05a                	sd	s6,0(sp)
    800016d4:	0080                	addi	s0,sp,64
    800016d6:	8b2a                	mv	s6,a0
    800016d8:	8aae                	mv	s5,a1
    800016da:	8a32                	mv	s4,a2
  for (i = 0; i < sz; i += PGSIZE)
    800016dc:	4901                	li	s2,0
  {
    if ((pte = walk(old, i, 0)) == 0)
    800016de:	4601                	li	a2,0
    800016e0:	85ca                	mv	a1,s2
    800016e2:	855a                	mv	a0,s6
    800016e4:	00000097          	auipc	ra,0x0
    800016e8:	a2a080e7          	jalr	-1494(ra) # 8000110e <walk>
    800016ec:	c121                	beqz	a0,8000172c <uvmcopy+0x6c>
      panic("uvmcopy: pte should exist");
    if ((*pte & PTE_V) == 0)
    800016ee:	6118                	ld	a4,0(a0)
    800016f0:	00177793          	andi	a5,a4,1
    800016f4:	c7a1                	beqz	a5,8000173c <uvmcopy+0x7c>
      panic("uvmcopy: page not present");
    // fix the permission bits
    pa = PTE2PA(*pte);
    800016f6:	00a75993          	srli	s3,a4,0xa
    800016fa:	09b2                	slli	s3,s3,0xc
    *pte &= ~PTE_W;
    800016fc:	ffb77493          	andi	s1,a4,-5
    80001700:	e104                	sd	s1,0(a0)
    // not allocated
    //  if((mem = kalloc()) == 0)
    //    goto err;
    //  memmove(mem, (char*)pa, PGSIZE);
    // increase refcnt
    increse(pa);
    80001702:	854e                	mv	a0,s3
    80001704:	fffff097          	auipc	ra,0xfffff
    80001708:	522080e7          	jalr	1314(ra) # 80000c26 <increse>
    // map the va to the same pa using flags
    if (mappages(new, i, PGSIZE, (uint64)pa, flags) != 0)
    8000170c:	3fb4f713          	andi	a4,s1,1019
    80001710:	86ce                	mv	a3,s3
    80001712:	6605                	lui	a2,0x1
    80001714:	85ca                	mv	a1,s2
    80001716:	8556                	mv	a0,s5
    80001718:	00000097          	auipc	ra,0x0
    8000171c:	ade080e7          	jalr	-1314(ra) # 800011f6 <mappages>
    80001720:	e515                	bnez	a0,8000174c <uvmcopy+0x8c>
  for (i = 0; i < sz; i += PGSIZE)
    80001722:	6785                	lui	a5,0x1
    80001724:	993e                	add	s2,s2,a5
    80001726:	fb496ce3          	bltu	s2,s4,800016de <uvmcopy+0x1e>
    8000172a:	a81d                	j	80001760 <uvmcopy+0xa0>
      panic("uvmcopy: pte should exist");
    8000172c:	00007517          	auipc	a0,0x7
    80001730:	a9450513          	addi	a0,a0,-1388 # 800081c0 <digits+0x180>
    80001734:	fffff097          	auipc	ra,0xfffff
    80001738:	e0c080e7          	jalr	-500(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000173c:	00007517          	auipc	a0,0x7
    80001740:	aa450513          	addi	a0,a0,-1372 # 800081e0 <digits+0x1a0>
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	dfc080e7          	jalr	-516(ra) # 80000540 <panic>
    }
  }
  return 0;

err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000174c:	4685                	li	a3,1
    8000174e:	00c95613          	srli	a2,s2,0xc
    80001752:	4581                	li	a1,0
    80001754:	8556                	mv	a0,s5
    80001756:	00000097          	auipc	ra,0x0
    8000175a:	c66080e7          	jalr	-922(ra) # 800013bc <uvmunmap>
  return -1;
    8000175e:	557d                	li	a0,-1
}
    80001760:	70e2                	ld	ra,56(sp)
    80001762:	7442                	ld	s0,48(sp)
    80001764:	74a2                	ld	s1,40(sp)
    80001766:	7902                	ld	s2,32(sp)
    80001768:	69e2                	ld	s3,24(sp)
    8000176a:	6a42                	ld	s4,16(sp)
    8000176c:	6aa2                	ld	s5,8(sp)
    8000176e:	6b02                	ld	s6,0(sp)
    80001770:	6121                	addi	sp,sp,64
    80001772:	8082                	ret
  return 0;
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret

0000000080001778 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    80001778:	1141                	addi	sp,sp,-16
    8000177a:	e406                	sd	ra,8(sp)
    8000177c:	e022                	sd	s0,0(sp)
    8000177e:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    80001780:	4601                	li	a2,0
    80001782:	00000097          	auipc	ra,0x0
    80001786:	98c080e7          	jalr	-1652(ra) # 8000110e <walk>
  if (pte == 0)
    8000178a:	c901                	beqz	a0,8000179a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000178c:	611c                	ld	a5,0(a0)
    8000178e:	9bbd                	andi	a5,a5,-17
    80001790:	e11c                	sd	a5,0(a0)
}
    80001792:	60a2                	ld	ra,8(sp)
    80001794:	6402                	ld	s0,0(sp)
    80001796:	0141                	addi	sp,sp,16
    80001798:	8082                	ret
    panic("uvmclear");
    8000179a:	00007517          	auipc	a0,0x7
    8000179e:	a6650513          	addi	a0,a0,-1434 # 80008200 <digits+0x1c0>
    800017a2:	fffff097          	auipc	ra,0xfffff
    800017a6:	d9e080e7          	jalr	-610(ra) # 80000540 <panic>

00000000800017aa <copyout>:
// Return 0 on success, -1 on error.
int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    800017aa:	c6bd                	beqz	a3,80001818 <copyout+0x6e>
{
    800017ac:	715d                	addi	sp,sp,-80
    800017ae:	e486                	sd	ra,72(sp)
    800017b0:	e0a2                	sd	s0,64(sp)
    800017b2:	fc26                	sd	s1,56(sp)
    800017b4:	f84a                	sd	s2,48(sp)
    800017b6:	f44e                	sd	s3,40(sp)
    800017b8:	f052                	sd	s4,32(sp)
    800017ba:	ec56                	sd	s5,24(sp)
    800017bc:	e85a                	sd	s6,16(sp)
    800017be:	e45e                	sd	s7,8(sp)
    800017c0:	e062                	sd	s8,0(sp)
    800017c2:	0880                	addi	s0,sp,80
    800017c4:	8b2a                	mv	s6,a0
    800017c6:	8c2e                	mv	s8,a1
    800017c8:	8a32                	mv	s4,a2
    800017ca:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(dstva);
    800017cc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017ce:	6a85                	lui	s5,0x1
    800017d0:	a015                	j	800017f4 <copyout+0x4a>
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017d2:	9562                	add	a0,a0,s8
    800017d4:	0004861b          	sext.w	a2,s1
    800017d8:	85d2                	mv	a1,s4
    800017da:	41250533          	sub	a0,a0,s2
    800017de:	fffff097          	auipc	ra,0xfffff
    800017e2:	6a8080e7          	jalr	1704(ra) # 80000e86 <memmove>

    len -= n;
    800017e6:	409989b3          	sub	s3,s3,s1
    src += n;
    800017ea:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017ec:	01590c33          	add	s8,s2,s5
  while (len > 0)
    800017f0:	02098263          	beqz	s3,80001814 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017f4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f8:	85ca                	mv	a1,s2
    800017fa:	855a                	mv	a0,s6
    800017fc:	00000097          	auipc	ra,0x0
    80001800:	9b8080e7          	jalr	-1608(ra) # 800011b4 <walkaddr>
    if (pa0 == 0)
    80001804:	cd01                	beqz	a0,8000181c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001806:	418904b3          	sub	s1,s2,s8
    8000180a:	94d6                	add	s1,s1,s5
    8000180c:	fc99f3e3          	bgeu	s3,s1,800017d2 <copyout+0x28>
    80001810:	84ce                	mv	s1,s3
    80001812:	b7c1                	j	800017d2 <copyout+0x28>
  }
  return 0;
    80001814:	4501                	li	a0,0
    80001816:	a021                	j	8000181e <copyout+0x74>
    80001818:	4501                	li	a0,0
}
    8000181a:	8082                	ret
      return -1;
    8000181c:	557d                	li	a0,-1
}
    8000181e:	60a6                	ld	ra,72(sp)
    80001820:	6406                	ld	s0,64(sp)
    80001822:	74e2                	ld	s1,56(sp)
    80001824:	7942                	ld	s2,48(sp)
    80001826:	79a2                	ld	s3,40(sp)
    80001828:	7a02                	ld	s4,32(sp)
    8000182a:	6ae2                	ld	s5,24(sp)
    8000182c:	6b42                	ld	s6,16(sp)
    8000182e:	6ba2                	ld	s7,8(sp)
    80001830:	6c02                	ld	s8,0(sp)
    80001832:	6161                	addi	sp,sp,80
    80001834:	8082                	ret

0000000080001836 <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001836:	caa5                	beqz	a3,800018a6 <copyin+0x70>
{
    80001838:	715d                	addi	sp,sp,-80
    8000183a:	e486                	sd	ra,72(sp)
    8000183c:	e0a2                	sd	s0,64(sp)
    8000183e:	fc26                	sd	s1,56(sp)
    80001840:	f84a                	sd	s2,48(sp)
    80001842:	f44e                	sd	s3,40(sp)
    80001844:	f052                	sd	s4,32(sp)
    80001846:	ec56                	sd	s5,24(sp)
    80001848:	e85a                	sd	s6,16(sp)
    8000184a:	e45e                	sd	s7,8(sp)
    8000184c:	e062                	sd	s8,0(sp)
    8000184e:	0880                	addi	s0,sp,80
    80001850:	8b2a                	mv	s6,a0
    80001852:	8a2e                	mv	s4,a1
    80001854:	8c32                	mv	s8,a2
    80001856:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001858:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000185a:	6a85                	lui	s5,0x1
    8000185c:	a01d                	j	80001882 <copyin+0x4c>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000185e:	018505b3          	add	a1,a0,s8
    80001862:	0004861b          	sext.w	a2,s1
    80001866:	412585b3          	sub	a1,a1,s2
    8000186a:	8552                	mv	a0,s4
    8000186c:	fffff097          	auipc	ra,0xfffff
    80001870:	61a080e7          	jalr	1562(ra) # 80000e86 <memmove>

    len -= n;
    80001874:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001878:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000187a:	01590c33          	add	s8,s2,s5
  while (len > 0)
    8000187e:	02098263          	beqz	s3,800018a2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001882:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001886:	85ca                	mv	a1,s2
    80001888:	855a                	mv	a0,s6
    8000188a:	00000097          	auipc	ra,0x0
    8000188e:	92a080e7          	jalr	-1750(ra) # 800011b4 <walkaddr>
    if (pa0 == 0)
    80001892:	cd01                	beqz	a0,800018aa <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001894:	418904b3          	sub	s1,s2,s8
    80001898:	94d6                	add	s1,s1,s5
    8000189a:	fc99f2e3          	bgeu	s3,s1,8000185e <copyin+0x28>
    8000189e:	84ce                	mv	s1,s3
    800018a0:	bf7d                	j	8000185e <copyin+0x28>
  }
  return 0;
    800018a2:	4501                	li	a0,0
    800018a4:	a021                	j	800018ac <copyin+0x76>
    800018a6:	4501                	li	a0,0
}
    800018a8:	8082                	ret
      return -1;
    800018aa:	557d                	li	a0,-1
}
    800018ac:	60a6                	ld	ra,72(sp)
    800018ae:	6406                	ld	s0,64(sp)
    800018b0:	74e2                	ld	s1,56(sp)
    800018b2:	7942                	ld	s2,48(sp)
    800018b4:	79a2                	ld	s3,40(sp)
    800018b6:	7a02                	ld	s4,32(sp)
    800018b8:	6ae2                	ld	s5,24(sp)
    800018ba:	6b42                	ld	s6,16(sp)
    800018bc:	6ba2                	ld	s7,8(sp)
    800018be:	6c02                	ld	s8,0(sp)
    800018c0:	6161                	addi	sp,sp,80
    800018c2:	8082                	ret

00000000800018c4 <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    800018c4:	c2dd                	beqz	a3,8000196a <copyinstr+0xa6>
{
    800018c6:	715d                	addi	sp,sp,-80
    800018c8:	e486                	sd	ra,72(sp)
    800018ca:	e0a2                	sd	s0,64(sp)
    800018cc:	fc26                	sd	s1,56(sp)
    800018ce:	f84a                	sd	s2,48(sp)
    800018d0:	f44e                	sd	s3,40(sp)
    800018d2:	f052                	sd	s4,32(sp)
    800018d4:	ec56                	sd	s5,24(sp)
    800018d6:	e85a                	sd	s6,16(sp)
    800018d8:	e45e                	sd	s7,8(sp)
    800018da:	0880                	addi	s0,sp,80
    800018dc:	8a2a                	mv	s4,a0
    800018de:	8b2e                	mv	s6,a1
    800018e0:	8bb2                	mv	s7,a2
    800018e2:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    800018e4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018e6:	6985                	lui	s3,0x1
    800018e8:	a02d                	j	80001912 <copyinstr+0x4e>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    800018ea:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018ee:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    800018f0:	37fd                	addiw	a5,a5,-1
    800018f2:	0007851b          	sext.w	a0,a5
  }
  else
  {
    return -1;
  }
}
    800018f6:	60a6                	ld	ra,72(sp)
    800018f8:	6406                	ld	s0,64(sp)
    800018fa:	74e2                	ld	s1,56(sp)
    800018fc:	7942                	ld	s2,48(sp)
    800018fe:	79a2                	ld	s3,40(sp)
    80001900:	7a02                	ld	s4,32(sp)
    80001902:	6ae2                	ld	s5,24(sp)
    80001904:	6b42                	ld	s6,16(sp)
    80001906:	6ba2                	ld	s7,8(sp)
    80001908:	6161                	addi	sp,sp,80
    8000190a:	8082                	ret
    srcva = va0 + PGSIZE;
    8000190c:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    80001910:	c8a9                	beqz	s1,80001962 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001912:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001916:	85ca                	mv	a1,s2
    80001918:	8552                	mv	a0,s4
    8000191a:	00000097          	auipc	ra,0x0
    8000191e:	89a080e7          	jalr	-1894(ra) # 800011b4 <walkaddr>
    if (pa0 == 0)
    80001922:	c131                	beqz	a0,80001966 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001924:	417906b3          	sub	a3,s2,s7
    80001928:	96ce                	add	a3,a3,s3
    8000192a:	00d4f363          	bgeu	s1,a3,80001930 <copyinstr+0x6c>
    8000192e:	86a6                	mv	a3,s1
    char *p = (char *)(pa0 + (srcva - va0));
    80001930:	955e                	add	a0,a0,s7
    80001932:	41250533          	sub	a0,a0,s2
    while (n > 0)
    80001936:	daf9                	beqz	a3,8000190c <copyinstr+0x48>
    80001938:	87da                	mv	a5,s6
      if (*p == '\0')
    8000193a:	41650633          	sub	a2,a0,s6
    8000193e:	fff48593          	addi	a1,s1,-1
    80001942:	95da                	add	a1,a1,s6
    while (n > 0)
    80001944:	96da                	add	a3,a3,s6
      if (*p == '\0')
    80001946:	00f60733          	add	a4,a2,a5
    8000194a:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbd130>
    8000194e:	df51                	beqz	a4,800018ea <copyinstr+0x26>
        *dst = *p;
    80001950:	00e78023          	sb	a4,0(a5)
      --max;
    80001954:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001958:	0785                	addi	a5,a5,1
    while (n > 0)
    8000195a:	fed796e3          	bne	a5,a3,80001946 <copyinstr+0x82>
      dst++;
    8000195e:	8b3e                	mv	s6,a5
    80001960:	b775                	j	8000190c <copyinstr+0x48>
    80001962:	4781                	li	a5,0
    80001964:	b771                	j	800018f0 <copyinstr+0x2c>
      return -1;
    80001966:	557d                	li	a0,-1
    80001968:	b779                	j	800018f6 <copyinstr+0x32>
  int got_null = 0;
    8000196a:	4781                	li	a5,0
  if (got_null)
    8000196c:	37fd                	addiw	a5,a5,-1
    8000196e:	0007851b          	sext.w	a0,a5
}
    80001972:	8082                	ret

0000000080001974 <cowfault>:

int cowfault(pagetable_t pagetable, uint64 va)
{
  if (va >= MAXVA)
    80001974:	57fd                	li	a5,-1
    80001976:	83e9                	srli	a5,a5,0x1a
    80001978:	06b7e863          	bltu	a5,a1,800019e8 <cowfault+0x74>
{
    8000197c:	7179                	addi	sp,sp,-48
    8000197e:	f406                	sd	ra,40(sp)
    80001980:	f022                	sd	s0,32(sp)
    80001982:	ec26                	sd	s1,24(sp)
    80001984:	e84a                	sd	s2,16(sp)
    80001986:	e44e                	sd	s3,8(sp)
    80001988:	1800                	addi	s0,sp,48
    return -1;
  pte_t *pte = walk(pagetable, va, 0);
    8000198a:	4601                	li	a2,0
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	782080e7          	jalr	1922(ra) # 8000110e <walk>
    80001994:	89aa                	mv	s3,a0
  if (pte == 0)
    80001996:	c939                	beqz	a0,800019ec <cowfault+0x78>
    return -1;
  if ((*pte & PTE_U) == 0 || (*pte & PTE_V) == 0)
    80001998:	610c                	ld	a1,0(a0)
    8000199a:	0115f713          	andi	a4,a1,17
    8000199e:	47c5                	li	a5,17
    800019a0:	04f71863          	bne	a4,a5,800019f0 <cowfault+0x7c>
    return -1;
  uint64 pa1 = PTE2PA(*pte);
    800019a4:	81a9                	srli	a1,a1,0xa
    800019a6:	00c59913          	slli	s2,a1,0xc
  uint64 pa2 = (uint64)kalloc();
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	1e4080e7          	jalr	484(ra) # 80000b8e <kalloc>
    800019b2:	84aa                	mv	s1,a0
  if (pa2 == 0)
    800019b4:	c121                	beqz	a0,800019f4 <cowfault+0x80>
  {
    // panic("cow panic kalloc");
    return -1;
  }
  memmove((void *)pa2, (void *)pa1, PGSIZE);
    800019b6:	6605                	lui	a2,0x1
    800019b8:	85ca                	mv	a1,s2
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	4cc080e7          	jalr	1228(ra) # 80000e86 <memmove>
  *pte = PA2PTE(pa2) | PTE_U | PTE_V | PTE_W | PTE_X | PTE_R;
    800019c2:	80b1                	srli	s1,s1,0xc
    800019c4:	04aa                	slli	s1,s1,0xa
    800019c6:	01f4e493          	ori	s1,s1,31
    800019ca:	0099b023          	sd	s1,0(s3) # 1000 <_entry-0x7ffff000>
  kfree((void *)pa1);
    800019ce:	854a                	mv	a0,s2
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	02a080e7          	jalr	42(ra) # 800009fa <kfree>
  return 0;
    800019d8:	4501                	li	a0,0
}
    800019da:	70a2                	ld	ra,40(sp)
    800019dc:	7402                	ld	s0,32(sp)
    800019de:	64e2                	ld	s1,24(sp)
    800019e0:	6942                	ld	s2,16(sp)
    800019e2:	69a2                	ld	s3,8(sp)
    800019e4:	6145                	addi	sp,sp,48
    800019e6:	8082                	ret
    return -1;
    800019e8:	557d                	li	a0,-1
}
    800019ea:	8082                	ret
    return -1;
    800019ec:	557d                	li	a0,-1
    800019ee:	b7f5                	j	800019da <cowfault+0x66>
    return -1;
    800019f0:	557d                	li	a0,-1
    800019f2:	b7e5                	j	800019da <cowfault+0x66>
    return -1;
    800019f4:	557d                	li	a0,-1
    800019f6:	b7d5                	j	800019da <cowfault+0x66>

00000000800019f8 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    800019f8:	715d                	addi	sp,sp,-80
    800019fa:	e486                	sd	ra,72(sp)
    800019fc:	e0a2                	sd	s0,64(sp)
    800019fe:	fc26                	sd	s1,56(sp)
    80001a00:	f84a                	sd	s2,48(sp)
    80001a02:	f44e                	sd	s3,40(sp)
    80001a04:	f052                	sd	s4,32(sp)
    80001a06:	ec56                	sd	s5,24(sp)
    80001a08:	e85a                	sd	s6,16(sp)
    80001a0a:	e45e                	sd	s7,8(sp)
    80001a0c:	e062                	sd	s8,0(sp)
    80001a0e:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a10:	8792                	mv	a5,tp
    int id = r_tp();
    80001a12:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001a14:	0022fa97          	auipc	s5,0x22f
    80001a18:	2aca8a93          	addi	s5,s5,684 # 80230cc0 <cpus>
    80001a1c:	00779713          	slli	a4,a5,0x7
    80001a20:	00ea86b3          	add	a3,s5,a4
    80001a24:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7fdbd130>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001a28:	0721                	addi	a4,a4,8
    80001a2a:	9aba                	add	s5,s5,a4
                c->proc = p;
    80001a2c:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    80001a2e:	00007c17          	auipc	s8,0x7
    80001a32:	f4ac0c13          	addi	s8,s8,-182 # 80008978 <sched_pointer>
    80001a36:	00000b97          	auipc	s7,0x0
    80001a3a:	fc2b8b93          	addi	s7,s7,-62 # 800019f8 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001a3e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001a42:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001a46:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    80001a4a:	0022f497          	auipc	s1,0x22f
    80001a4e:	6a648493          	addi	s1,s1,1702 # 802310f0 <proc>
            if (p->state == RUNNABLE)
    80001a52:	498d                	li	s3,3
                p->state = RUNNING;
    80001a54:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001a56:	00235a17          	auipc	s4,0x235
    80001a5a:	09aa0a13          	addi	s4,s4,154 # 80236af0 <tickslock>
    80001a5e:	a81d                	j	80001a94 <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001a60:	8526                	mv	a0,s1
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	380080e7          	jalr	896(ra) # 80000de2 <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    80001a6a:	60a6                	ld	ra,72(sp)
    80001a6c:	6406                	ld	s0,64(sp)
    80001a6e:	74e2                	ld	s1,56(sp)
    80001a70:	7942                	ld	s2,48(sp)
    80001a72:	79a2                	ld	s3,40(sp)
    80001a74:	7a02                	ld	s4,32(sp)
    80001a76:	6ae2                	ld	s5,24(sp)
    80001a78:	6b42                	ld	s6,16(sp)
    80001a7a:	6ba2                	ld	s7,8(sp)
    80001a7c:	6c02                	ld	s8,0(sp)
    80001a7e:	6161                	addi	sp,sp,80
    80001a80:	8082                	ret
            release(&p->lock);
    80001a82:	8526                	mv	a0,s1
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	35e080e7          	jalr	862(ra) # 80000de2 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001a8c:	16848493          	addi	s1,s1,360
    80001a90:	fb4487e3          	beq	s1,s4,80001a3e <rr_scheduler+0x46>
            acquire(&p->lock);
    80001a94:	8526                	mv	a0,s1
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	298080e7          	jalr	664(ra) # 80000d2e <acquire>
            if (p->state == RUNNABLE)
    80001a9e:	4c9c                	lw	a5,24(s1)
    80001aa0:	ff3791e3          	bne	a5,s3,80001a82 <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001aa4:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001aa8:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001aac:	06048593          	addi	a1,s1,96
    80001ab0:	8556                	mv	a0,s5
    80001ab2:	00001097          	auipc	ra,0x1
    80001ab6:	fc8080e7          	jalr	-56(ra) # 80002a7a <swtch>
                if (sched_pointer != &rr_scheduler)
    80001aba:	000c3783          	ld	a5,0(s8)
    80001abe:	fb7791e3          	bne	a5,s7,80001a60 <rr_scheduler+0x68>
                c->proc = 0;
    80001ac2:	00093023          	sd	zero,0(s2)
    80001ac6:	bf75                	j	80001a82 <rr_scheduler+0x8a>

0000000080001ac8 <proc_mapstacks>:
{
    80001ac8:	7139                	addi	sp,sp,-64
    80001aca:	fc06                	sd	ra,56(sp)
    80001acc:	f822                	sd	s0,48(sp)
    80001ace:	f426                	sd	s1,40(sp)
    80001ad0:	f04a                	sd	s2,32(sp)
    80001ad2:	ec4e                	sd	s3,24(sp)
    80001ad4:	e852                	sd	s4,16(sp)
    80001ad6:	e456                	sd	s5,8(sp)
    80001ad8:	e05a                	sd	s6,0(sp)
    80001ada:	0080                	addi	s0,sp,64
    80001adc:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001ade:	0022f497          	auipc	s1,0x22f
    80001ae2:	61248493          	addi	s1,s1,1554 # 802310f0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001ae6:	8b26                	mv	s6,s1
    80001ae8:	00006a97          	auipc	s5,0x6
    80001aec:	518a8a93          	addi	s5,s5,1304 # 80008000 <etext>
    80001af0:	04000937          	lui	s2,0x4000
    80001af4:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001af6:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001af8:	00235a17          	auipc	s4,0x235
    80001afc:	ff8a0a13          	addi	s4,s4,-8 # 80236af0 <tickslock>
        char *pa = kalloc();
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	08e080e7          	jalr	142(ra) # 80000b8e <kalloc>
    80001b08:	862a                	mv	a2,a0
        if (pa == 0)
    80001b0a:	c131                	beqz	a0,80001b4e <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001b0c:	416485b3          	sub	a1,s1,s6
    80001b10:	858d                	srai	a1,a1,0x3
    80001b12:	000ab783          	ld	a5,0(s5)
    80001b16:	02f585b3          	mul	a1,a1,a5
    80001b1a:	2585                	addiw	a1,a1,1
    80001b1c:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b20:	4719                	li	a4,6
    80001b22:	6685                	lui	a3,0x1
    80001b24:	40b905b3          	sub	a1,s2,a1
    80001b28:	854e                	mv	a0,s3
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	76c080e7          	jalr	1900(ra) # 80001296 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b32:	16848493          	addi	s1,s1,360
    80001b36:	fd4495e3          	bne	s1,s4,80001b00 <proc_mapstacks+0x38>
}
    80001b3a:	70e2                	ld	ra,56(sp)
    80001b3c:	7442                	ld	s0,48(sp)
    80001b3e:	74a2                	ld	s1,40(sp)
    80001b40:	7902                	ld	s2,32(sp)
    80001b42:	69e2                	ld	s3,24(sp)
    80001b44:	6a42                	ld	s4,16(sp)
    80001b46:	6aa2                	ld	s5,8(sp)
    80001b48:	6b02                	ld	s6,0(sp)
    80001b4a:	6121                	addi	sp,sp,64
    80001b4c:	8082                	ret
            panic("kalloc");
    80001b4e:	00006517          	auipc	a0,0x6
    80001b52:	6c250513          	addi	a0,a0,1730 # 80008210 <digits+0x1d0>
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	9ea080e7          	jalr	-1558(ra) # 80000540 <panic>

0000000080001b5e <procinit>:
{
    80001b5e:	7139                	addi	sp,sp,-64
    80001b60:	fc06                	sd	ra,56(sp)
    80001b62:	f822                	sd	s0,48(sp)
    80001b64:	f426                	sd	s1,40(sp)
    80001b66:	f04a                	sd	s2,32(sp)
    80001b68:	ec4e                	sd	s3,24(sp)
    80001b6a:	e852                	sd	s4,16(sp)
    80001b6c:	e456                	sd	s5,8(sp)
    80001b6e:	e05a                	sd	s6,0(sp)
    80001b70:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001b72:	00006597          	auipc	a1,0x6
    80001b76:	6a658593          	addi	a1,a1,1702 # 80008218 <digits+0x1d8>
    80001b7a:	0022f517          	auipc	a0,0x22f
    80001b7e:	54650513          	addi	a0,a0,1350 # 802310c0 <pid_lock>
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	11c080e7          	jalr	284(ra) # 80000c9e <initlock>
    initlock(&wait_lock, "wait_lock");
    80001b8a:	00006597          	auipc	a1,0x6
    80001b8e:	69658593          	addi	a1,a1,1686 # 80008220 <digits+0x1e0>
    80001b92:	0022f517          	auipc	a0,0x22f
    80001b96:	54650513          	addi	a0,a0,1350 # 802310d8 <wait_lock>
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	104080e7          	jalr	260(ra) # 80000c9e <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001ba2:	0022f497          	auipc	s1,0x22f
    80001ba6:	54e48493          	addi	s1,s1,1358 # 802310f0 <proc>
        initlock(&p->lock, "proc");
    80001baa:	00006b17          	auipc	s6,0x6
    80001bae:	686b0b13          	addi	s6,s6,1670 # 80008230 <digits+0x1f0>
        p->kstack = KSTACK((int)(p - proc));
    80001bb2:	8aa6                	mv	s5,s1
    80001bb4:	00006a17          	auipc	s4,0x6
    80001bb8:	44ca0a13          	addi	s4,s4,1100 # 80008000 <etext>
    80001bbc:	04000937          	lui	s2,0x4000
    80001bc0:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001bc2:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001bc4:	00235997          	auipc	s3,0x235
    80001bc8:	f2c98993          	addi	s3,s3,-212 # 80236af0 <tickslock>
        initlock(&p->lock, "proc");
    80001bcc:	85da                	mv	a1,s6
    80001bce:	8526                	mv	a0,s1
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	0ce080e7          	jalr	206(ra) # 80000c9e <initlock>
        p->state = UNUSED;
    80001bd8:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001bdc:	415487b3          	sub	a5,s1,s5
    80001be0:	878d                	srai	a5,a5,0x3
    80001be2:	000a3703          	ld	a4,0(s4)
    80001be6:	02e787b3          	mul	a5,a5,a4
    80001bea:	2785                	addiw	a5,a5,1
    80001bec:	00d7979b          	slliw	a5,a5,0xd
    80001bf0:	40f907b3          	sub	a5,s2,a5
    80001bf4:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001bf6:	16848493          	addi	s1,s1,360
    80001bfa:	fd3499e3          	bne	s1,s3,80001bcc <procinit+0x6e>
}
    80001bfe:	70e2                	ld	ra,56(sp)
    80001c00:	7442                	ld	s0,48(sp)
    80001c02:	74a2                	ld	s1,40(sp)
    80001c04:	7902                	ld	s2,32(sp)
    80001c06:	69e2                	ld	s3,24(sp)
    80001c08:	6a42                	ld	s4,16(sp)
    80001c0a:	6aa2                	ld	s5,8(sp)
    80001c0c:	6b02                	ld	s6,0(sp)
    80001c0e:	6121                	addi	sp,sp,64
    80001c10:	8082                	ret

0000000080001c12 <copy_array>:
{
    80001c12:	1141                	addi	sp,sp,-16
    80001c14:	e422                	sd	s0,8(sp)
    80001c16:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001c18:	02c05163          	blez	a2,80001c3a <copy_array+0x28>
    80001c1c:	87aa                	mv	a5,a0
    80001c1e:	0505                	addi	a0,a0,1
    80001c20:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    80001c22:	1602                	slli	a2,a2,0x20
    80001c24:	9201                	srli	a2,a2,0x20
    80001c26:	00c506b3          	add	a3,a0,a2
        dst[i] = src[i];
    80001c2a:	0007c703          	lbu	a4,0(a5)
    80001c2e:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001c32:	0785                	addi	a5,a5,1
    80001c34:	0585                	addi	a1,a1,1
    80001c36:	fed79ae3          	bne	a5,a3,80001c2a <copy_array+0x18>
}
    80001c3a:	6422                	ld	s0,8(sp)
    80001c3c:	0141                	addi	sp,sp,16
    80001c3e:	8082                	ret

0000000080001c40 <cpuid>:
{
    80001c40:	1141                	addi	sp,sp,-16
    80001c42:	e422                	sd	s0,8(sp)
    80001c44:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c46:	8512                	mv	a0,tp
}
    80001c48:	2501                	sext.w	a0,a0
    80001c4a:	6422                	ld	s0,8(sp)
    80001c4c:	0141                	addi	sp,sp,16
    80001c4e:	8082                	ret

0000000080001c50 <mycpu>:
{
    80001c50:	1141                	addi	sp,sp,-16
    80001c52:	e422                	sd	s0,8(sp)
    80001c54:	0800                	addi	s0,sp,16
    80001c56:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001c58:	2781                	sext.w	a5,a5
    80001c5a:	079e                	slli	a5,a5,0x7
}
    80001c5c:	0022f517          	auipc	a0,0x22f
    80001c60:	06450513          	addi	a0,a0,100 # 80230cc0 <cpus>
    80001c64:	953e                	add	a0,a0,a5
    80001c66:	6422                	ld	s0,8(sp)
    80001c68:	0141                	addi	sp,sp,16
    80001c6a:	8082                	ret

0000000080001c6c <myproc>:
{
    80001c6c:	1101                	addi	sp,sp,-32
    80001c6e:	ec06                	sd	ra,24(sp)
    80001c70:	e822                	sd	s0,16(sp)
    80001c72:	e426                	sd	s1,8(sp)
    80001c74:	1000                	addi	s0,sp,32
    push_off();
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	06c080e7          	jalr	108(ra) # 80000ce2 <push_off>
    80001c7e:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001c80:	2781                	sext.w	a5,a5
    80001c82:	079e                	slli	a5,a5,0x7
    80001c84:	0022f717          	auipc	a4,0x22f
    80001c88:	03c70713          	addi	a4,a4,60 # 80230cc0 <cpus>
    80001c8c:	97ba                	add	a5,a5,a4
    80001c8e:	6384                	ld	s1,0(a5)
    pop_off();
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	0f2080e7          	jalr	242(ra) # 80000d82 <pop_off>
}
    80001c98:	8526                	mv	a0,s1
    80001c9a:	60e2                	ld	ra,24(sp)
    80001c9c:	6442                	ld	s0,16(sp)
    80001c9e:	64a2                	ld	s1,8(sp)
    80001ca0:	6105                	addi	sp,sp,32
    80001ca2:	8082                	ret

0000000080001ca4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001ca4:	1141                	addi	sp,sp,-16
    80001ca6:	e406                	sd	ra,8(sp)
    80001ca8:	e022                	sd	s0,0(sp)
    80001caa:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001cac:	00000097          	auipc	ra,0x0
    80001cb0:	fc0080e7          	jalr	-64(ra) # 80001c6c <myproc>
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	12e080e7          	jalr	302(ra) # 80000de2 <release>

    if (first)
    80001cbc:	00007797          	auipc	a5,0x7
    80001cc0:	cb47a783          	lw	a5,-844(a5) # 80008970 <first.1>
    80001cc4:	eb89                	bnez	a5,80001cd6 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001cc6:	00001097          	auipc	ra,0x1
    80001cca:	e5e080e7          	jalr	-418(ra) # 80002b24 <usertrapret>
}
    80001cce:	60a2                	ld	ra,8(sp)
    80001cd0:	6402                	ld	s0,0(sp)
    80001cd2:	0141                	addi	sp,sp,16
    80001cd4:	8082                	ret
        first = 0;
    80001cd6:	00007797          	auipc	a5,0x7
    80001cda:	c807ad23          	sw	zero,-870(a5) # 80008970 <first.1>
        fsinit(ROOTDEV);
    80001cde:	4505                	li	a0,1
    80001ce0:	00002097          	auipc	ra,0x2
    80001ce4:	cf2080e7          	jalr	-782(ra) # 800039d2 <fsinit>
    80001ce8:	bff9                	j	80001cc6 <forkret+0x22>

0000000080001cea <allocpid>:
{
    80001cea:	1101                	addi	sp,sp,-32
    80001cec:	ec06                	sd	ra,24(sp)
    80001cee:	e822                	sd	s0,16(sp)
    80001cf0:	e426                	sd	s1,8(sp)
    80001cf2:	e04a                	sd	s2,0(sp)
    80001cf4:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001cf6:	0022f917          	auipc	s2,0x22f
    80001cfa:	3ca90913          	addi	s2,s2,970 # 802310c0 <pid_lock>
    80001cfe:	854a                	mv	a0,s2
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	02e080e7          	jalr	46(ra) # 80000d2e <acquire>
    pid = nextpid;
    80001d08:	00007797          	auipc	a5,0x7
    80001d0c:	c7878793          	addi	a5,a5,-904 # 80008980 <nextpid>
    80001d10:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001d12:	0014871b          	addiw	a4,s1,1
    80001d16:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001d18:	854a                	mv	a0,s2
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	0c8080e7          	jalr	200(ra) # 80000de2 <release>
}
    80001d22:	8526                	mv	a0,s1
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6902                	ld	s2,0(sp)
    80001d2c:	6105                	addi	sp,sp,32
    80001d2e:	8082                	ret

0000000080001d30 <proc_pagetable>:
{
    80001d30:	1101                	addi	sp,sp,-32
    80001d32:	ec06                	sd	ra,24(sp)
    80001d34:	e822                	sd	s0,16(sp)
    80001d36:	e426                	sd	s1,8(sp)
    80001d38:	e04a                	sd	s2,0(sp)
    80001d3a:	1000                	addi	s0,sp,32
    80001d3c:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	742080e7          	jalr	1858(ra) # 80001480 <uvmcreate>
    80001d46:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001d48:	c121                	beqz	a0,80001d88 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d4a:	4729                	li	a4,10
    80001d4c:	00005697          	auipc	a3,0x5
    80001d50:	2b468693          	addi	a3,a3,692 # 80007000 <_trampoline>
    80001d54:	6605                	lui	a2,0x1
    80001d56:	040005b7          	lui	a1,0x4000
    80001d5a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d5c:	05b2                	slli	a1,a1,0xc
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	498080e7          	jalr	1176(ra) # 800011f6 <mappages>
    80001d66:	02054863          	bltz	a0,80001d96 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d6a:	4719                	li	a4,6
    80001d6c:	05893683          	ld	a3,88(s2)
    80001d70:	6605                	lui	a2,0x1
    80001d72:	020005b7          	lui	a1,0x2000
    80001d76:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d78:	05b6                	slli	a1,a1,0xd
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	47a080e7          	jalr	1146(ra) # 800011f6 <mappages>
    80001d84:	02054163          	bltz	a0,80001da6 <proc_pagetable+0x76>
}
    80001d88:	8526                	mv	a0,s1
    80001d8a:	60e2                	ld	ra,24(sp)
    80001d8c:	6442                	ld	s0,16(sp)
    80001d8e:	64a2                	ld	s1,8(sp)
    80001d90:	6902                	ld	s2,0(sp)
    80001d92:	6105                	addi	sp,sp,32
    80001d94:	8082                	ret
        uvmfree(pagetable, 0);
    80001d96:	4581                	li	a1,0
    80001d98:	8526                	mv	a0,s1
    80001d9a:	00000097          	auipc	ra,0x0
    80001d9e:	8ec080e7          	jalr	-1812(ra) # 80001686 <uvmfree>
        return 0;
    80001da2:	4481                	li	s1,0
    80001da4:	b7d5                	j	80001d88 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001da6:	4681                	li	a3,0
    80001da8:	4605                	li	a2,1
    80001daa:	040005b7          	lui	a1,0x4000
    80001dae:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001db0:	05b2                	slli	a1,a1,0xc
    80001db2:	8526                	mv	a0,s1
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	608080e7          	jalr	1544(ra) # 800013bc <uvmunmap>
        uvmfree(pagetable, 0);
    80001dbc:	4581                	li	a1,0
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	8c6080e7          	jalr	-1850(ra) # 80001686 <uvmfree>
        return 0;
    80001dc8:	4481                	li	s1,0
    80001dca:	bf7d                	j	80001d88 <proc_pagetable+0x58>

0000000080001dcc <proc_freepagetable>:
{
    80001dcc:	1101                	addi	sp,sp,-32
    80001dce:	ec06                	sd	ra,24(sp)
    80001dd0:	e822                	sd	s0,16(sp)
    80001dd2:	e426                	sd	s1,8(sp)
    80001dd4:	e04a                	sd	s2,0(sp)
    80001dd6:	1000                	addi	s0,sp,32
    80001dd8:	84aa                	mv	s1,a0
    80001dda:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ddc:	4681                	li	a3,0
    80001dde:	4605                	li	a2,1
    80001de0:	040005b7          	lui	a1,0x4000
    80001de4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001de6:	05b2                	slli	a1,a1,0xc
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	5d4080e7          	jalr	1492(ra) # 800013bc <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001df0:	4681                	li	a3,0
    80001df2:	4605                	li	a2,1
    80001df4:	020005b7          	lui	a1,0x2000
    80001df8:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001dfa:	05b6                	slli	a1,a1,0xd
    80001dfc:	8526                	mv	a0,s1
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	5be080e7          	jalr	1470(ra) # 800013bc <uvmunmap>
    uvmfree(pagetable, sz);
    80001e06:	85ca                	mv	a1,s2
    80001e08:	8526                	mv	a0,s1
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	87c080e7          	jalr	-1924(ra) # 80001686 <uvmfree>
}
    80001e12:	60e2                	ld	ra,24(sp)
    80001e14:	6442                	ld	s0,16(sp)
    80001e16:	64a2                	ld	s1,8(sp)
    80001e18:	6902                	ld	s2,0(sp)
    80001e1a:	6105                	addi	sp,sp,32
    80001e1c:	8082                	ret

0000000080001e1e <freeproc>:
{
    80001e1e:	1101                	addi	sp,sp,-32
    80001e20:	ec06                	sd	ra,24(sp)
    80001e22:	e822                	sd	s0,16(sp)
    80001e24:	e426                	sd	s1,8(sp)
    80001e26:	1000                	addi	s0,sp,32
    80001e28:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001e2a:	6d28                	ld	a0,88(a0)
    80001e2c:	c509                	beqz	a0,80001e36 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	bcc080e7          	jalr	-1076(ra) # 800009fa <kfree>
    p->trapframe = 0;
    80001e36:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001e3a:	68a8                	ld	a0,80(s1)
    80001e3c:	c511                	beqz	a0,80001e48 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001e3e:	64ac                	ld	a1,72(s1)
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	f8c080e7          	jalr	-116(ra) # 80001dcc <proc_freepagetable>
    p->pagetable = 0;
    80001e48:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001e4c:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001e50:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001e54:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001e58:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001e5c:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001e60:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001e64:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001e68:	0004ac23          	sw	zero,24(s1)
}
    80001e6c:	60e2                	ld	ra,24(sp)
    80001e6e:	6442                	ld	s0,16(sp)
    80001e70:	64a2                	ld	s1,8(sp)
    80001e72:	6105                	addi	sp,sp,32
    80001e74:	8082                	ret

0000000080001e76 <allocproc>:
{
    80001e76:	1101                	addi	sp,sp,-32
    80001e78:	ec06                	sd	ra,24(sp)
    80001e7a:	e822                	sd	s0,16(sp)
    80001e7c:	e426                	sd	s1,8(sp)
    80001e7e:	e04a                	sd	s2,0(sp)
    80001e80:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001e82:	0022f497          	auipc	s1,0x22f
    80001e86:	26e48493          	addi	s1,s1,622 # 802310f0 <proc>
    80001e8a:	00235917          	auipc	s2,0x235
    80001e8e:	c6690913          	addi	s2,s2,-922 # 80236af0 <tickslock>
        acquire(&p->lock);
    80001e92:	8526                	mv	a0,s1
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	e9a080e7          	jalr	-358(ra) # 80000d2e <acquire>
        if (p->state == UNUSED)
    80001e9c:	4c9c                	lw	a5,24(s1)
    80001e9e:	cf81                	beqz	a5,80001eb6 <allocproc+0x40>
            release(&p->lock);
    80001ea0:	8526                	mv	a0,s1
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	f40080e7          	jalr	-192(ra) # 80000de2 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001eaa:	16848493          	addi	s1,s1,360
    80001eae:	ff2492e3          	bne	s1,s2,80001e92 <allocproc+0x1c>
    return 0;
    80001eb2:	4481                	li	s1,0
    80001eb4:	a889                	j	80001f06 <allocproc+0x90>
    p->pid = allocpid();
    80001eb6:	00000097          	auipc	ra,0x0
    80001eba:	e34080e7          	jalr	-460(ra) # 80001cea <allocpid>
    80001ebe:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001ec0:	4785                	li	a5,1
    80001ec2:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	cca080e7          	jalr	-822(ra) # 80000b8e <kalloc>
    80001ecc:	892a                	mv	s2,a0
    80001ece:	eca8                	sd	a0,88(s1)
    80001ed0:	c131                	beqz	a0,80001f14 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001ed2:	8526                	mv	a0,s1
    80001ed4:	00000097          	auipc	ra,0x0
    80001ed8:	e5c080e7          	jalr	-420(ra) # 80001d30 <proc_pagetable>
    80001edc:	892a                	mv	s2,a0
    80001ede:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001ee0:	c531                	beqz	a0,80001f2c <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001ee2:	07000613          	li	a2,112
    80001ee6:	4581                	li	a1,0
    80001ee8:	06048513          	addi	a0,s1,96
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	f3e080e7          	jalr	-194(ra) # 80000e2a <memset>
    p->context.ra = (uint64)forkret;
    80001ef4:	00000797          	auipc	a5,0x0
    80001ef8:	db078793          	addi	a5,a5,-592 # 80001ca4 <forkret>
    80001efc:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001efe:	60bc                	ld	a5,64(s1)
    80001f00:	6705                	lui	a4,0x1
    80001f02:	97ba                	add	a5,a5,a4
    80001f04:	f4bc                	sd	a5,104(s1)
}
    80001f06:	8526                	mv	a0,s1
    80001f08:	60e2                	ld	ra,24(sp)
    80001f0a:	6442                	ld	s0,16(sp)
    80001f0c:	64a2                	ld	s1,8(sp)
    80001f0e:	6902                	ld	s2,0(sp)
    80001f10:	6105                	addi	sp,sp,32
    80001f12:	8082                	ret
        freeproc(p);
    80001f14:	8526                	mv	a0,s1
    80001f16:	00000097          	auipc	ra,0x0
    80001f1a:	f08080e7          	jalr	-248(ra) # 80001e1e <freeproc>
        release(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	ec2080e7          	jalr	-318(ra) # 80000de2 <release>
        return 0;
    80001f28:	84ca                	mv	s1,s2
    80001f2a:	bff1                	j	80001f06 <allocproc+0x90>
        freeproc(p);
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	00000097          	auipc	ra,0x0
    80001f32:	ef0080e7          	jalr	-272(ra) # 80001e1e <freeproc>
        release(&p->lock);
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	eaa080e7          	jalr	-342(ra) # 80000de2 <release>
        return 0;
    80001f40:	84ca                	mv	s1,s2
    80001f42:	b7d1                	j	80001f06 <allocproc+0x90>

0000000080001f44 <userinit>:
{
    80001f44:	1101                	addi	sp,sp,-32
    80001f46:	ec06                	sd	ra,24(sp)
    80001f48:	e822                	sd	s0,16(sp)
    80001f4a:	e426                	sd	s1,8(sp)
    80001f4c:	1000                	addi	s0,sp,32
    p = allocproc();
    80001f4e:	00000097          	auipc	ra,0x0
    80001f52:	f28080e7          	jalr	-216(ra) # 80001e76 <allocproc>
    80001f56:	84aa                	mv	s1,a0
    initproc = p;
    80001f58:	00007797          	auipc	a5,0x7
    80001f5c:	aea7b823          	sd	a0,-1296(a5) # 80008a48 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001f60:	03400613          	li	a2,52
    80001f64:	00007597          	auipc	a1,0x7
    80001f68:	a2c58593          	addi	a1,a1,-1492 # 80008990 <initcode>
    80001f6c:	6928                	ld	a0,80(a0)
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	540080e7          	jalr	1344(ra) # 800014ae <uvmfirst>
    p->sz = PGSIZE;
    80001f76:	6785                	lui	a5,0x1
    80001f78:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001f7a:	6cb8                	ld	a4,88(s1)
    80001f7c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001f80:	6cb8                	ld	a4,88(s1)
    80001f82:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f84:	4641                	li	a2,16
    80001f86:	00006597          	auipc	a1,0x6
    80001f8a:	2b258593          	addi	a1,a1,690 # 80008238 <digits+0x1f8>
    80001f8e:	15848513          	addi	a0,s1,344
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	fe2080e7          	jalr	-30(ra) # 80000f74 <safestrcpy>
    p->cwd = namei("/");
    80001f9a:	00006517          	auipc	a0,0x6
    80001f9e:	2ae50513          	addi	a0,a0,686 # 80008248 <digits+0x208>
    80001fa2:	00002097          	auipc	ra,0x2
    80001fa6:	45a080e7          	jalr	1114(ra) # 800043fc <namei>
    80001faa:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001fae:	478d                	li	a5,3
    80001fb0:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	e2e080e7          	jalr	-466(ra) # 80000de2 <release>
}
    80001fbc:	60e2                	ld	ra,24(sp)
    80001fbe:	6442                	ld	s0,16(sp)
    80001fc0:	64a2                	ld	s1,8(sp)
    80001fc2:	6105                	addi	sp,sp,32
    80001fc4:	8082                	ret

0000000080001fc6 <growproc>:
{
    80001fc6:	1101                	addi	sp,sp,-32
    80001fc8:	ec06                	sd	ra,24(sp)
    80001fca:	e822                	sd	s0,16(sp)
    80001fcc:	e426                	sd	s1,8(sp)
    80001fce:	e04a                	sd	s2,0(sp)
    80001fd0:	1000                	addi	s0,sp,32
    80001fd2:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	c98080e7          	jalr	-872(ra) # 80001c6c <myproc>
    80001fdc:	84aa                	mv	s1,a0
    sz = p->sz;
    80001fde:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001fe0:	01204c63          	bgtz	s2,80001ff8 <growproc+0x32>
    else if (n < 0)
    80001fe4:	02094663          	bltz	s2,80002010 <growproc+0x4a>
    p->sz = sz;
    80001fe8:	e4ac                	sd	a1,72(s1)
    return 0;
    80001fea:	4501                	li	a0,0
}
    80001fec:	60e2                	ld	ra,24(sp)
    80001fee:	6442                	ld	s0,16(sp)
    80001ff0:	64a2                	ld	s1,8(sp)
    80001ff2:	6902                	ld	s2,0(sp)
    80001ff4:	6105                	addi	sp,sp,32
    80001ff6:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001ff8:	4691                	li	a3,4
    80001ffa:	00b90633          	add	a2,s2,a1
    80001ffe:	6928                	ld	a0,80(a0)
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	568080e7          	jalr	1384(ra) # 80001568 <uvmalloc>
    80002008:	85aa                	mv	a1,a0
    8000200a:	fd79                	bnez	a0,80001fe8 <growproc+0x22>
            return -1;
    8000200c:	557d                	li	a0,-1
    8000200e:	bff9                	j	80001fec <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002010:	00b90633          	add	a2,s2,a1
    80002014:	6928                	ld	a0,80(a0)
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	50a080e7          	jalr	1290(ra) # 80001520 <uvmdealloc>
    8000201e:	85aa                	mv	a1,a0
    80002020:	b7e1                	j	80001fe8 <growproc+0x22>

0000000080002022 <ps>:
{
    80002022:	715d                	addi	sp,sp,-80
    80002024:	e486                	sd	ra,72(sp)
    80002026:	e0a2                	sd	s0,64(sp)
    80002028:	fc26                	sd	s1,56(sp)
    8000202a:	f84a                	sd	s2,48(sp)
    8000202c:	f44e                	sd	s3,40(sp)
    8000202e:	f052                	sd	s4,32(sp)
    80002030:	ec56                	sd	s5,24(sp)
    80002032:	e85a                	sd	s6,16(sp)
    80002034:	e45e                	sd	s7,8(sp)
    80002036:	e062                	sd	s8,0(sp)
    80002038:	0880                	addi	s0,sp,80
    8000203a:	84aa                	mv	s1,a0
    8000203c:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    8000203e:	00000097          	auipc	ra,0x0
    80002042:	c2e080e7          	jalr	-978(ra) # 80001c6c <myproc>
    if (count == 0)
    80002046:	120b8063          	beqz	s7,80002166 <ps+0x144>
    void *result = (void *)myproc()->sz;
    8000204a:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    8000204e:	003b951b          	slliw	a0,s7,0x3
    80002052:	0175053b          	addw	a0,a0,s7
    80002056:	0025151b          	slliw	a0,a0,0x2
    8000205a:	00000097          	auipc	ra,0x0
    8000205e:	f6c080e7          	jalr	-148(ra) # 80001fc6 <growproc>
    80002062:	10054463          	bltz	a0,8000216a <ps+0x148>
    struct user_proc loc_result[count];
    80002066:	003b9a13          	slli	s4,s7,0x3
    8000206a:	9a5e                	add	s4,s4,s7
    8000206c:	0a0a                	slli	s4,s4,0x2
    8000206e:	00fa0793          	addi	a5,s4,15
    80002072:	8391                	srli	a5,a5,0x4
    80002074:	0792                	slli	a5,a5,0x4
    80002076:	40f10133          	sub	sp,sp,a5
    8000207a:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    8000207c:	007e97b7          	lui	a5,0x7e9
    80002080:	02f484b3          	mul	s1,s1,a5
    80002084:	0022f797          	auipc	a5,0x22f
    80002088:	06c78793          	addi	a5,a5,108 # 802310f0 <proc>
    8000208c:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    8000208e:	00235797          	auipc	a5,0x235
    80002092:	a6278793          	addi	a5,a5,-1438 # 80236af0 <tickslock>
    80002096:	0cf4fc63          	bgeu	s1,a5,8000216e <ps+0x14c>
    8000209a:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    8000209e:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    800020a0:	8c3e                	mv	s8,a5
    800020a2:	a069                	j	8000212c <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    800020a4:	00399793          	slli	a5,s3,0x3
    800020a8:	97ce                	add	a5,a5,s3
    800020aa:	078a                	slli	a5,a5,0x2
    800020ac:	97d6                	add	a5,a5,s5
    800020ae:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    800020b2:	8526                	mv	a0,s1
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	d2e080e7          	jalr	-722(ra) # 80000de2 <release>
    if (localCount < count)
    800020bc:	0179f963          	bgeu	s3,s7,800020ce <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    800020c0:	00399793          	slli	a5,s3,0x3
    800020c4:	97ce                	add	a5,a5,s3
    800020c6:	078a                	slli	a5,a5,0x2
    800020c8:	97d6                	add	a5,a5,s5
    800020ca:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    800020ce:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	b9c080e7          	jalr	-1124(ra) # 80001c6c <myproc>
    800020d8:	86d2                	mv	a3,s4
    800020da:	8656                	mv	a2,s5
    800020dc:	85da                	mv	a1,s6
    800020de:	6928                	ld	a0,80(a0)
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	6ca080e7          	jalr	1738(ra) # 800017aa <copyout>
}
    800020e8:	8526                	mv	a0,s1
    800020ea:	fb040113          	addi	sp,s0,-80
    800020ee:	60a6                	ld	ra,72(sp)
    800020f0:	6406                	ld	s0,64(sp)
    800020f2:	74e2                	ld	s1,56(sp)
    800020f4:	7942                	ld	s2,48(sp)
    800020f6:	79a2                	ld	s3,40(sp)
    800020f8:	7a02                	ld	s4,32(sp)
    800020fa:	6ae2                	ld	s5,24(sp)
    800020fc:	6b42                	ld	s6,16(sp)
    800020fe:	6ba2                	ld	s7,8(sp)
    80002100:	6c02                	ld	s8,0(sp)
    80002102:	6161                	addi	sp,sp,80
    80002104:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80002106:	5b9c                	lw	a5,48(a5)
    80002108:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	cd4080e7          	jalr	-812(ra) # 80000de2 <release>
        localCount++;
    80002116:	2985                	addiw	s3,s3,1
    80002118:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    8000211c:	16848493          	addi	s1,s1,360
    80002120:	f984fee3          	bgeu	s1,s8,800020bc <ps+0x9a>
        if (localCount == count)
    80002124:	02490913          	addi	s2,s2,36
    80002128:	fb3b83e3          	beq	s7,s3,800020ce <ps+0xac>
        acquire(&p->lock);
    8000212c:	8526                	mv	a0,s1
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	c00080e7          	jalr	-1024(ra) # 80000d2e <acquire>
        if (p->state == UNUSED)
    80002136:	4c9c                	lw	a5,24(s1)
    80002138:	d7b5                	beqz	a5,800020a4 <ps+0x82>
        loc_result[localCount].state = p->state;
    8000213a:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    8000213e:	549c                	lw	a5,40(s1)
    80002140:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80002144:	54dc                	lw	a5,44(s1)
    80002146:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    8000214a:	589c                	lw	a5,48(s1)
    8000214c:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80002150:	4641                	li	a2,16
    80002152:	85ca                	mv	a1,s2
    80002154:	15848513          	addi	a0,s1,344
    80002158:	00000097          	auipc	ra,0x0
    8000215c:	aba080e7          	jalr	-1350(ra) # 80001c12 <copy_array>
        if (p->parent != 0) // init
    80002160:	7c9c                	ld	a5,56(s1)
    80002162:	f3d5                	bnez	a5,80002106 <ps+0xe4>
    80002164:	b765                	j	8000210c <ps+0xea>
        return result;
    80002166:	4481                	li	s1,0
    80002168:	b741                	j	800020e8 <ps+0xc6>
        return result;
    8000216a:	4481                	li	s1,0
    8000216c:	bfb5                	j	800020e8 <ps+0xc6>
        return result;
    8000216e:	4481                	li	s1,0
    80002170:	bfa5                	j	800020e8 <ps+0xc6>

0000000080002172 <fork>:
{
    80002172:	7139                	addi	sp,sp,-64
    80002174:	fc06                	sd	ra,56(sp)
    80002176:	f822                	sd	s0,48(sp)
    80002178:	f426                	sd	s1,40(sp)
    8000217a:	f04a                	sd	s2,32(sp)
    8000217c:	ec4e                	sd	s3,24(sp)
    8000217e:	e852                	sd	s4,16(sp)
    80002180:	e456                	sd	s5,8(sp)
    80002182:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80002184:	00000097          	auipc	ra,0x0
    80002188:	ae8080e7          	jalr	-1304(ra) # 80001c6c <myproc>
    8000218c:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	ce8080e7          	jalr	-792(ra) # 80001e76 <allocproc>
    80002196:	10050c63          	beqz	a0,800022ae <fork+0x13c>
    8000219a:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    8000219c:	048ab603          	ld	a2,72(s5)
    800021a0:	692c                	ld	a1,80(a0)
    800021a2:	050ab503          	ld	a0,80(s5)
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	51a080e7          	jalr	1306(ra) # 800016c0 <uvmcopy>
    800021ae:	04054863          	bltz	a0,800021fe <fork+0x8c>
    np->sz = p->sz;
    800021b2:	048ab783          	ld	a5,72(s5)
    800021b6:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    800021ba:	058ab683          	ld	a3,88(s5)
    800021be:	87b6                	mv	a5,a3
    800021c0:	058a3703          	ld	a4,88(s4)
    800021c4:	12068693          	addi	a3,a3,288
    800021c8:	0007b803          	ld	a6,0(a5)
    800021cc:	6788                	ld	a0,8(a5)
    800021ce:	6b8c                	ld	a1,16(a5)
    800021d0:	6f90                	ld	a2,24(a5)
    800021d2:	01073023          	sd	a6,0(a4)
    800021d6:	e708                	sd	a0,8(a4)
    800021d8:	eb0c                	sd	a1,16(a4)
    800021da:	ef10                	sd	a2,24(a4)
    800021dc:	02078793          	addi	a5,a5,32
    800021e0:	02070713          	addi	a4,a4,32
    800021e4:	fed792e3          	bne	a5,a3,800021c8 <fork+0x56>
    np->trapframe->a0 = 0;
    800021e8:	058a3783          	ld	a5,88(s4)
    800021ec:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    800021f0:	0d0a8493          	addi	s1,s5,208
    800021f4:	0d0a0913          	addi	s2,s4,208
    800021f8:	150a8993          	addi	s3,s5,336
    800021fc:	a00d                	j	8000221e <fork+0xac>
        freeproc(np);
    800021fe:	8552                	mv	a0,s4
    80002200:	00000097          	auipc	ra,0x0
    80002204:	c1e080e7          	jalr	-994(ra) # 80001e1e <freeproc>
        release(&np->lock);
    80002208:	8552                	mv	a0,s4
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	bd8080e7          	jalr	-1064(ra) # 80000de2 <release>
        return -1;
    80002212:	597d                	li	s2,-1
    80002214:	a059                	j	8000229a <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002216:	04a1                	addi	s1,s1,8
    80002218:	0921                	addi	s2,s2,8
    8000221a:	01348b63          	beq	s1,s3,80002230 <fork+0xbe>
        if (p->ofile[i])
    8000221e:	6088                	ld	a0,0(s1)
    80002220:	d97d                	beqz	a0,80002216 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002222:	00003097          	auipc	ra,0x3
    80002226:	870080e7          	jalr	-1936(ra) # 80004a92 <filedup>
    8000222a:	00a93023          	sd	a0,0(s2)
    8000222e:	b7e5                	j	80002216 <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002230:	150ab503          	ld	a0,336(s5)
    80002234:	00002097          	auipc	ra,0x2
    80002238:	9de080e7          	jalr	-1570(ra) # 80003c12 <idup>
    8000223c:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002240:	4641                	li	a2,16
    80002242:	158a8593          	addi	a1,s5,344
    80002246:	158a0513          	addi	a0,s4,344
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	d2a080e7          	jalr	-726(ra) # 80000f74 <safestrcpy>
    pid = np->pid;
    80002252:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80002256:	8552                	mv	a0,s4
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	b8a080e7          	jalr	-1142(ra) # 80000de2 <release>
    acquire(&wait_lock);
    80002260:	0022f497          	auipc	s1,0x22f
    80002264:	e7848493          	addi	s1,s1,-392 # 802310d8 <wait_lock>
    80002268:	8526                	mv	a0,s1
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	ac4080e7          	jalr	-1340(ra) # 80000d2e <acquire>
    np->parent = p;
    80002272:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    80002276:	8526                	mv	a0,s1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	b6a080e7          	jalr	-1174(ra) # 80000de2 <release>
    acquire(&np->lock);
    80002280:	8552                	mv	a0,s4
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	aac080e7          	jalr	-1364(ra) # 80000d2e <acquire>
    np->state = RUNNABLE;
    8000228a:	478d                	li	a5,3
    8000228c:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80002290:	8552                	mv	a0,s4
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	b50080e7          	jalr	-1200(ra) # 80000de2 <release>
}
    8000229a:	854a                	mv	a0,s2
    8000229c:	70e2                	ld	ra,56(sp)
    8000229e:	7442                	ld	s0,48(sp)
    800022a0:	74a2                	ld	s1,40(sp)
    800022a2:	7902                	ld	s2,32(sp)
    800022a4:	69e2                	ld	s3,24(sp)
    800022a6:	6a42                	ld	s4,16(sp)
    800022a8:	6aa2                	ld	s5,8(sp)
    800022aa:	6121                	addi	sp,sp,64
    800022ac:	8082                	ret
        return -1;
    800022ae:	597d                	li	s2,-1
    800022b0:	b7ed                	j	8000229a <fork+0x128>

00000000800022b2 <scheduler>:
{
    800022b2:	1101                	addi	sp,sp,-32
    800022b4:	ec06                	sd	ra,24(sp)
    800022b6:	e822                	sd	s0,16(sp)
    800022b8:	e426                	sd	s1,8(sp)
    800022ba:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800022bc:	00006497          	auipc	s1,0x6
    800022c0:	6bc48493          	addi	s1,s1,1724 # 80008978 <sched_pointer>
    800022c4:	609c                	ld	a5,0(s1)
    800022c6:	9782                	jalr	a5
    while (1)
    800022c8:	bff5                	j	800022c4 <scheduler+0x12>

00000000800022ca <sched>:
{
    800022ca:	7179                	addi	sp,sp,-48
    800022cc:	f406                	sd	ra,40(sp)
    800022ce:	f022                	sd	s0,32(sp)
    800022d0:	ec26                	sd	s1,24(sp)
    800022d2:	e84a                	sd	s2,16(sp)
    800022d4:	e44e                	sd	s3,8(sp)
    800022d6:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800022d8:	00000097          	auipc	ra,0x0
    800022dc:	994080e7          	jalr	-1644(ra) # 80001c6c <myproc>
    800022e0:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9d2080e7          	jalr	-1582(ra) # 80000cb4 <holding>
    800022ea:	c53d                	beqz	a0,80002358 <sched+0x8e>
    800022ec:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800022ee:	2781                	sext.w	a5,a5
    800022f0:	079e                	slli	a5,a5,0x7
    800022f2:	0022f717          	auipc	a4,0x22f
    800022f6:	9ce70713          	addi	a4,a4,-1586 # 80230cc0 <cpus>
    800022fa:	97ba                	add	a5,a5,a4
    800022fc:	5fb8                	lw	a4,120(a5)
    800022fe:	4785                	li	a5,1
    80002300:	06f71463          	bne	a4,a5,80002368 <sched+0x9e>
    if (p->state == RUNNING)
    80002304:	4c98                	lw	a4,24(s1)
    80002306:	4791                	li	a5,4
    80002308:	06f70863          	beq	a4,a5,80002378 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000230c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002310:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002312:	ebbd                	bnez	a5,80002388 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002314:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002316:	0022f917          	auipc	s2,0x22f
    8000231a:	9aa90913          	addi	s2,s2,-1622 # 80230cc0 <cpus>
    8000231e:	2781                	sext.w	a5,a5
    80002320:	079e                	slli	a5,a5,0x7
    80002322:	97ca                	add	a5,a5,s2
    80002324:	07c7a983          	lw	s3,124(a5)
    80002328:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    8000232a:	2581                	sext.w	a1,a1
    8000232c:	059e                	slli	a1,a1,0x7
    8000232e:	05a1                	addi	a1,a1,8
    80002330:	95ca                	add	a1,a1,s2
    80002332:	06048513          	addi	a0,s1,96
    80002336:	00000097          	auipc	ra,0x0
    8000233a:	744080e7          	jalr	1860(ra) # 80002a7a <swtch>
    8000233e:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002340:	2781                	sext.w	a5,a5
    80002342:	079e                	slli	a5,a5,0x7
    80002344:	993e                	add	s2,s2,a5
    80002346:	07392e23          	sw	s3,124(s2)
}
    8000234a:	70a2                	ld	ra,40(sp)
    8000234c:	7402                	ld	s0,32(sp)
    8000234e:	64e2                	ld	s1,24(sp)
    80002350:	6942                	ld	s2,16(sp)
    80002352:	69a2                	ld	s3,8(sp)
    80002354:	6145                	addi	sp,sp,48
    80002356:	8082                	ret
        panic("sched p->lock");
    80002358:	00006517          	auipc	a0,0x6
    8000235c:	ef850513          	addi	a0,a0,-264 # 80008250 <digits+0x210>
    80002360:	ffffe097          	auipc	ra,0xffffe
    80002364:	1e0080e7          	jalr	480(ra) # 80000540 <panic>
        panic("sched locks");
    80002368:	00006517          	auipc	a0,0x6
    8000236c:	ef850513          	addi	a0,a0,-264 # 80008260 <digits+0x220>
    80002370:	ffffe097          	auipc	ra,0xffffe
    80002374:	1d0080e7          	jalr	464(ra) # 80000540 <panic>
        panic("sched running");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	ef850513          	addi	a0,a0,-264 # 80008270 <digits+0x230>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1c0080e7          	jalr	448(ra) # 80000540 <panic>
        panic("sched interruptible");
    80002388:	00006517          	auipc	a0,0x6
    8000238c:	ef850513          	addi	a0,a0,-264 # 80008280 <digits+0x240>
    80002390:	ffffe097          	auipc	ra,0xffffe
    80002394:	1b0080e7          	jalr	432(ra) # 80000540 <panic>

0000000080002398 <yield>:
{
    80002398:	1101                	addi	sp,sp,-32
    8000239a:	ec06                	sd	ra,24(sp)
    8000239c:	e822                	sd	s0,16(sp)
    8000239e:	e426                	sd	s1,8(sp)
    800023a0:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800023a2:	00000097          	auipc	ra,0x0
    800023a6:	8ca080e7          	jalr	-1846(ra) # 80001c6c <myproc>
    800023aa:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	982080e7          	jalr	-1662(ra) # 80000d2e <acquire>
    p->state = RUNNABLE;
    800023b4:	478d                	li	a5,3
    800023b6:	cc9c                	sw	a5,24(s1)
    sched();
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	f12080e7          	jalr	-238(ra) # 800022ca <sched>
    release(&p->lock);
    800023c0:	8526                	mv	a0,s1
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	a20080e7          	jalr	-1504(ra) # 80000de2 <release>
}
    800023ca:	60e2                	ld	ra,24(sp)
    800023cc:	6442                	ld	s0,16(sp)
    800023ce:	64a2                	ld	s1,8(sp)
    800023d0:	6105                	addi	sp,sp,32
    800023d2:	8082                	ret

00000000800023d4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800023d4:	7179                	addi	sp,sp,-48
    800023d6:	f406                	sd	ra,40(sp)
    800023d8:	f022                	sd	s0,32(sp)
    800023da:	ec26                	sd	s1,24(sp)
    800023dc:	e84a                	sd	s2,16(sp)
    800023de:	e44e                	sd	s3,8(sp)
    800023e0:	1800                	addi	s0,sp,48
    800023e2:	89aa                	mv	s3,a0
    800023e4:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800023e6:	00000097          	auipc	ra,0x0
    800023ea:	886080e7          	jalr	-1914(ra) # 80001c6c <myproc>
    800023ee:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	93e080e7          	jalr	-1730(ra) # 80000d2e <acquire>
    release(lk);
    800023f8:	854a                	mv	a0,s2
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	9e8080e7          	jalr	-1560(ra) # 80000de2 <release>

    // Go to sleep.
    p->chan = chan;
    80002402:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002406:	4789                	li	a5,2
    80002408:	cc9c                	sw	a5,24(s1)

    sched();
    8000240a:	00000097          	auipc	ra,0x0
    8000240e:	ec0080e7          	jalr	-320(ra) # 800022ca <sched>

    // Tidy up.
    p->chan = 0;
    80002412:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	9ca080e7          	jalr	-1590(ra) # 80000de2 <release>
    acquire(lk);
    80002420:	854a                	mv	a0,s2
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	90c080e7          	jalr	-1780(ra) # 80000d2e <acquire>
}
    8000242a:	70a2                	ld	ra,40(sp)
    8000242c:	7402                	ld	s0,32(sp)
    8000242e:	64e2                	ld	s1,24(sp)
    80002430:	6942                	ld	s2,16(sp)
    80002432:	69a2                	ld	s3,8(sp)
    80002434:	6145                	addi	sp,sp,48
    80002436:	8082                	ret

0000000080002438 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002438:	7139                	addi	sp,sp,-64
    8000243a:	fc06                	sd	ra,56(sp)
    8000243c:	f822                	sd	s0,48(sp)
    8000243e:	f426                	sd	s1,40(sp)
    80002440:	f04a                	sd	s2,32(sp)
    80002442:	ec4e                	sd	s3,24(sp)
    80002444:	e852                	sd	s4,16(sp)
    80002446:	e456                	sd	s5,8(sp)
    80002448:	0080                	addi	s0,sp,64
    8000244a:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000244c:	0022f497          	auipc	s1,0x22f
    80002450:	ca448493          	addi	s1,s1,-860 # 802310f0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002454:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    80002456:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002458:	00234917          	auipc	s2,0x234
    8000245c:	69890913          	addi	s2,s2,1688 # 80236af0 <tickslock>
    80002460:	a811                	j	80002474 <wakeup+0x3c>
            }
            release(&p->lock);
    80002462:	8526                	mv	a0,s1
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	97e080e7          	jalr	-1666(ra) # 80000de2 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000246c:	16848493          	addi	s1,s1,360
    80002470:	03248663          	beq	s1,s2,8000249c <wakeup+0x64>
        if (p != myproc())
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	7f8080e7          	jalr	2040(ra) # 80001c6c <myproc>
    8000247c:	fea488e3          	beq	s1,a0,8000246c <wakeup+0x34>
            acquire(&p->lock);
    80002480:	8526                	mv	a0,s1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	8ac080e7          	jalr	-1876(ra) # 80000d2e <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    8000248a:	4c9c                	lw	a5,24(s1)
    8000248c:	fd379be3          	bne	a5,s3,80002462 <wakeup+0x2a>
    80002490:	709c                	ld	a5,32(s1)
    80002492:	fd4798e3          	bne	a5,s4,80002462 <wakeup+0x2a>
                p->state = RUNNABLE;
    80002496:	0154ac23          	sw	s5,24(s1)
    8000249a:	b7e1                	j	80002462 <wakeup+0x2a>
        }
    }
}
    8000249c:	70e2                	ld	ra,56(sp)
    8000249e:	7442                	ld	s0,48(sp)
    800024a0:	74a2                	ld	s1,40(sp)
    800024a2:	7902                	ld	s2,32(sp)
    800024a4:	69e2                	ld	s3,24(sp)
    800024a6:	6a42                	ld	s4,16(sp)
    800024a8:	6aa2                	ld	s5,8(sp)
    800024aa:	6121                	addi	sp,sp,64
    800024ac:	8082                	ret

00000000800024ae <reparent>:
{
    800024ae:	7179                	addi	sp,sp,-48
    800024b0:	f406                	sd	ra,40(sp)
    800024b2:	f022                	sd	s0,32(sp)
    800024b4:	ec26                	sd	s1,24(sp)
    800024b6:	e84a                	sd	s2,16(sp)
    800024b8:	e44e                	sd	s3,8(sp)
    800024ba:	e052                	sd	s4,0(sp)
    800024bc:	1800                	addi	s0,sp,48
    800024be:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024c0:	0022f497          	auipc	s1,0x22f
    800024c4:	c3048493          	addi	s1,s1,-976 # 802310f0 <proc>
            pp->parent = initproc;
    800024c8:	00006a17          	auipc	s4,0x6
    800024cc:	580a0a13          	addi	s4,s4,1408 # 80008a48 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024d0:	00234997          	auipc	s3,0x234
    800024d4:	62098993          	addi	s3,s3,1568 # 80236af0 <tickslock>
    800024d8:	a029                	j	800024e2 <reparent+0x34>
    800024da:	16848493          	addi	s1,s1,360
    800024de:	01348d63          	beq	s1,s3,800024f8 <reparent+0x4a>
        if (pp->parent == p)
    800024e2:	7c9c                	ld	a5,56(s1)
    800024e4:	ff279be3          	bne	a5,s2,800024da <reparent+0x2c>
            pp->parent = initproc;
    800024e8:	000a3503          	ld	a0,0(s4)
    800024ec:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	f4a080e7          	jalr	-182(ra) # 80002438 <wakeup>
    800024f6:	b7d5                	j	800024da <reparent+0x2c>
}
    800024f8:	70a2                	ld	ra,40(sp)
    800024fa:	7402                	ld	s0,32(sp)
    800024fc:	64e2                	ld	s1,24(sp)
    800024fe:	6942                	ld	s2,16(sp)
    80002500:	69a2                	ld	s3,8(sp)
    80002502:	6a02                	ld	s4,0(sp)
    80002504:	6145                	addi	sp,sp,48
    80002506:	8082                	ret

0000000080002508 <exit>:
{
    80002508:	7179                	addi	sp,sp,-48
    8000250a:	f406                	sd	ra,40(sp)
    8000250c:	f022                	sd	s0,32(sp)
    8000250e:	ec26                	sd	s1,24(sp)
    80002510:	e84a                	sd	s2,16(sp)
    80002512:	e44e                	sd	s3,8(sp)
    80002514:	e052                	sd	s4,0(sp)
    80002516:	1800                	addi	s0,sp,48
    80002518:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	752080e7          	jalr	1874(ra) # 80001c6c <myproc>
    80002522:	89aa                	mv	s3,a0
    if (p == initproc)
    80002524:	00006797          	auipc	a5,0x6
    80002528:	5247b783          	ld	a5,1316(a5) # 80008a48 <initproc>
    8000252c:	0d050493          	addi	s1,a0,208
    80002530:	15050913          	addi	s2,a0,336
    80002534:	02a79363          	bne	a5,a0,8000255a <exit+0x52>
        panic("init exiting");
    80002538:	00006517          	auipc	a0,0x6
    8000253c:	d6050513          	addi	a0,a0,-672 # 80008298 <digits+0x258>
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	000080e7          	jalr	ra # 80000540 <panic>
            fileclose(f);
    80002548:	00002097          	auipc	ra,0x2
    8000254c:	59c080e7          	jalr	1436(ra) # 80004ae4 <fileclose>
            p->ofile[fd] = 0;
    80002550:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002554:	04a1                	addi	s1,s1,8
    80002556:	01248563          	beq	s1,s2,80002560 <exit+0x58>
        if (p->ofile[fd])
    8000255a:	6088                	ld	a0,0(s1)
    8000255c:	f575                	bnez	a0,80002548 <exit+0x40>
    8000255e:	bfdd                	j	80002554 <exit+0x4c>
    begin_op();
    80002560:	00002097          	auipc	ra,0x2
    80002564:	0bc080e7          	jalr	188(ra) # 8000461c <begin_op>
    iput(p->cwd);
    80002568:	1509b503          	ld	a0,336(s3)
    8000256c:	00002097          	auipc	ra,0x2
    80002570:	89e080e7          	jalr	-1890(ra) # 80003e0a <iput>
    end_op();
    80002574:	00002097          	auipc	ra,0x2
    80002578:	126080e7          	jalr	294(ra) # 8000469a <end_op>
    p->cwd = 0;
    8000257c:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002580:	0022f497          	auipc	s1,0x22f
    80002584:	b5848493          	addi	s1,s1,-1192 # 802310d8 <wait_lock>
    80002588:	8526                	mv	a0,s1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	7a4080e7          	jalr	1956(ra) # 80000d2e <acquire>
    reparent(p);
    80002592:	854e                	mv	a0,s3
    80002594:	00000097          	auipc	ra,0x0
    80002598:	f1a080e7          	jalr	-230(ra) # 800024ae <reparent>
    wakeup(p->parent);
    8000259c:	0389b503          	ld	a0,56(s3)
    800025a0:	00000097          	auipc	ra,0x0
    800025a4:	e98080e7          	jalr	-360(ra) # 80002438 <wakeup>
    acquire(&p->lock);
    800025a8:	854e                	mv	a0,s3
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	784080e7          	jalr	1924(ra) # 80000d2e <acquire>
    p->xstate = status;
    800025b2:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800025b6:	4795                	li	a5,5
    800025b8:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800025bc:	8526                	mv	a0,s1
    800025be:	fffff097          	auipc	ra,0xfffff
    800025c2:	824080e7          	jalr	-2012(ra) # 80000de2 <release>
    sched();
    800025c6:	00000097          	auipc	ra,0x0
    800025ca:	d04080e7          	jalr	-764(ra) # 800022ca <sched>
    panic("zombie exit");
    800025ce:	00006517          	auipc	a0,0x6
    800025d2:	cda50513          	addi	a0,a0,-806 # 800082a8 <digits+0x268>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	f6a080e7          	jalr	-150(ra) # 80000540 <panic>

00000000800025de <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025de:	7179                	addi	sp,sp,-48
    800025e0:	f406                	sd	ra,40(sp)
    800025e2:	f022                	sd	s0,32(sp)
    800025e4:	ec26                	sd	s1,24(sp)
    800025e6:	e84a                	sd	s2,16(sp)
    800025e8:	e44e                	sd	s3,8(sp)
    800025ea:	1800                	addi	s0,sp,48
    800025ec:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800025ee:	0022f497          	auipc	s1,0x22f
    800025f2:	b0248493          	addi	s1,s1,-1278 # 802310f0 <proc>
    800025f6:	00234997          	auipc	s3,0x234
    800025fa:	4fa98993          	addi	s3,s3,1274 # 80236af0 <tickslock>
    {
        acquire(&p->lock);
    800025fe:	8526                	mv	a0,s1
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	72e080e7          	jalr	1838(ra) # 80000d2e <acquire>
        if (p->pid == pid)
    80002608:	589c                	lw	a5,48(s1)
    8000260a:	01278d63          	beq	a5,s2,80002624 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    8000260e:	8526                	mv	a0,s1
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	7d2080e7          	jalr	2002(ra) # 80000de2 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002618:	16848493          	addi	s1,s1,360
    8000261c:	ff3491e3          	bne	s1,s3,800025fe <kill+0x20>
    }
    return -1;
    80002620:	557d                	li	a0,-1
    80002622:	a829                	j	8000263c <kill+0x5e>
            p->killed = 1;
    80002624:	4785                	li	a5,1
    80002626:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002628:	4c98                	lw	a4,24(s1)
    8000262a:	4789                	li	a5,2
    8000262c:	00f70f63          	beq	a4,a5,8000264a <kill+0x6c>
            release(&p->lock);
    80002630:	8526                	mv	a0,s1
    80002632:	ffffe097          	auipc	ra,0xffffe
    80002636:	7b0080e7          	jalr	1968(ra) # 80000de2 <release>
            return 0;
    8000263a:	4501                	li	a0,0
}
    8000263c:	70a2                	ld	ra,40(sp)
    8000263e:	7402                	ld	s0,32(sp)
    80002640:	64e2                	ld	s1,24(sp)
    80002642:	6942                	ld	s2,16(sp)
    80002644:	69a2                	ld	s3,8(sp)
    80002646:	6145                	addi	sp,sp,48
    80002648:	8082                	ret
                p->state = RUNNABLE;
    8000264a:	478d                	li	a5,3
    8000264c:	cc9c                	sw	a5,24(s1)
    8000264e:	b7cd                	j	80002630 <kill+0x52>

0000000080002650 <setkilled>:

void setkilled(struct proc *p)
{
    80002650:	1101                	addi	sp,sp,-32
    80002652:	ec06                	sd	ra,24(sp)
    80002654:	e822                	sd	s0,16(sp)
    80002656:	e426                	sd	s1,8(sp)
    80002658:	1000                	addi	s0,sp,32
    8000265a:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	6d2080e7          	jalr	1746(ra) # 80000d2e <acquire>
    p->killed = 1;
    80002664:	4785                	li	a5,1
    80002666:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	778080e7          	jalr	1912(ra) # 80000de2 <release>
}
    80002672:	60e2                	ld	ra,24(sp)
    80002674:	6442                	ld	s0,16(sp)
    80002676:	64a2                	ld	s1,8(sp)
    80002678:	6105                	addi	sp,sp,32
    8000267a:	8082                	ret

000000008000267c <killed>:

int killed(struct proc *p)
{
    8000267c:	1101                	addi	sp,sp,-32
    8000267e:	ec06                	sd	ra,24(sp)
    80002680:	e822                	sd	s0,16(sp)
    80002682:	e426                	sd	s1,8(sp)
    80002684:	e04a                	sd	s2,0(sp)
    80002686:	1000                	addi	s0,sp,32
    80002688:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	6a4080e7          	jalr	1700(ra) # 80000d2e <acquire>
    k = p->killed;
    80002692:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    80002696:	8526                	mv	a0,s1
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	74a080e7          	jalr	1866(ra) # 80000de2 <release>
    return k;
}
    800026a0:	854a                	mv	a0,s2
    800026a2:	60e2                	ld	ra,24(sp)
    800026a4:	6442                	ld	s0,16(sp)
    800026a6:	64a2                	ld	s1,8(sp)
    800026a8:	6902                	ld	s2,0(sp)
    800026aa:	6105                	addi	sp,sp,32
    800026ac:	8082                	ret

00000000800026ae <wait>:
{
    800026ae:	715d                	addi	sp,sp,-80
    800026b0:	e486                	sd	ra,72(sp)
    800026b2:	e0a2                	sd	s0,64(sp)
    800026b4:	fc26                	sd	s1,56(sp)
    800026b6:	f84a                	sd	s2,48(sp)
    800026b8:	f44e                	sd	s3,40(sp)
    800026ba:	f052                	sd	s4,32(sp)
    800026bc:	ec56                	sd	s5,24(sp)
    800026be:	e85a                	sd	s6,16(sp)
    800026c0:	e45e                	sd	s7,8(sp)
    800026c2:	e062                	sd	s8,0(sp)
    800026c4:	0880                	addi	s0,sp,80
    800026c6:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800026c8:	fffff097          	auipc	ra,0xfffff
    800026cc:	5a4080e7          	jalr	1444(ra) # 80001c6c <myproc>
    800026d0:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800026d2:	0022f517          	auipc	a0,0x22f
    800026d6:	a0650513          	addi	a0,a0,-1530 # 802310d8 <wait_lock>
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	654080e7          	jalr	1620(ra) # 80000d2e <acquire>
        havekids = 0;
    800026e2:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    800026e4:	4a15                	li	s4,5
                havekids = 1;
    800026e6:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026e8:	00234997          	auipc	s3,0x234
    800026ec:	40898993          	addi	s3,s3,1032 # 80236af0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800026f0:	0022fc17          	auipc	s8,0x22f
    800026f4:	9e8c0c13          	addi	s8,s8,-1560 # 802310d8 <wait_lock>
        havekids = 0;
    800026f8:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800026fa:	0022f497          	auipc	s1,0x22f
    800026fe:	9f648493          	addi	s1,s1,-1546 # 802310f0 <proc>
    80002702:	a0bd                	j	80002770 <wait+0xc2>
                    pid = pp->pid;
    80002704:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002708:	000b0e63          	beqz	s6,80002724 <wait+0x76>
    8000270c:	4691                	li	a3,4
    8000270e:	02c48613          	addi	a2,s1,44
    80002712:	85da                	mv	a1,s6
    80002714:	05093503          	ld	a0,80(s2)
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	092080e7          	jalr	146(ra) # 800017aa <copyout>
    80002720:	02054563          	bltz	a0,8000274a <wait+0x9c>
                    freeproc(pp);
    80002724:	8526                	mv	a0,s1
    80002726:	fffff097          	auipc	ra,0xfffff
    8000272a:	6f8080e7          	jalr	1784(ra) # 80001e1e <freeproc>
                    release(&pp->lock);
    8000272e:	8526                	mv	a0,s1
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	6b2080e7          	jalr	1714(ra) # 80000de2 <release>
                    release(&wait_lock);
    80002738:	0022f517          	auipc	a0,0x22f
    8000273c:	9a050513          	addi	a0,a0,-1632 # 802310d8 <wait_lock>
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	6a2080e7          	jalr	1698(ra) # 80000de2 <release>
                    return pid;
    80002748:	a0b5                	j	800027b4 <wait+0x106>
                        release(&pp->lock);
    8000274a:	8526                	mv	a0,s1
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	696080e7          	jalr	1686(ra) # 80000de2 <release>
                        release(&wait_lock);
    80002754:	0022f517          	auipc	a0,0x22f
    80002758:	98450513          	addi	a0,a0,-1660 # 802310d8 <wait_lock>
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	686080e7          	jalr	1670(ra) # 80000de2 <release>
                        return -1;
    80002764:	59fd                	li	s3,-1
    80002766:	a0b9                	j	800027b4 <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002768:	16848493          	addi	s1,s1,360
    8000276c:	03348463          	beq	s1,s3,80002794 <wait+0xe6>
            if (pp->parent == p)
    80002770:	7c9c                	ld	a5,56(s1)
    80002772:	ff279be3          	bne	a5,s2,80002768 <wait+0xba>
                acquire(&pp->lock);
    80002776:	8526                	mv	a0,s1
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	5b6080e7          	jalr	1462(ra) # 80000d2e <acquire>
                if (pp->state == ZOMBIE)
    80002780:	4c9c                	lw	a5,24(s1)
    80002782:	f94781e3          	beq	a5,s4,80002704 <wait+0x56>
                release(&pp->lock);
    80002786:	8526                	mv	a0,s1
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	65a080e7          	jalr	1626(ra) # 80000de2 <release>
                havekids = 1;
    80002790:	8756                	mv	a4,s5
    80002792:	bfd9                	j	80002768 <wait+0xba>
        if (!havekids || killed(p))
    80002794:	c719                	beqz	a4,800027a2 <wait+0xf4>
    80002796:	854a                	mv	a0,s2
    80002798:	00000097          	auipc	ra,0x0
    8000279c:	ee4080e7          	jalr	-284(ra) # 8000267c <killed>
    800027a0:	c51d                	beqz	a0,800027ce <wait+0x120>
            release(&wait_lock);
    800027a2:	0022f517          	auipc	a0,0x22f
    800027a6:	93650513          	addi	a0,a0,-1738 # 802310d8 <wait_lock>
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	638080e7          	jalr	1592(ra) # 80000de2 <release>
            return -1;
    800027b2:	59fd                	li	s3,-1
}
    800027b4:	854e                	mv	a0,s3
    800027b6:	60a6                	ld	ra,72(sp)
    800027b8:	6406                	ld	s0,64(sp)
    800027ba:	74e2                	ld	s1,56(sp)
    800027bc:	7942                	ld	s2,48(sp)
    800027be:	79a2                	ld	s3,40(sp)
    800027c0:	7a02                	ld	s4,32(sp)
    800027c2:	6ae2                	ld	s5,24(sp)
    800027c4:	6b42                	ld	s6,16(sp)
    800027c6:	6ba2                	ld	s7,8(sp)
    800027c8:	6c02                	ld	s8,0(sp)
    800027ca:	6161                	addi	sp,sp,80
    800027cc:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    800027ce:	85e2                	mv	a1,s8
    800027d0:	854a                	mv	a0,s2
    800027d2:	00000097          	auipc	ra,0x0
    800027d6:	c02080e7          	jalr	-1022(ra) # 800023d4 <sleep>
        havekids = 0;
    800027da:	bf39                	j	800026f8 <wait+0x4a>

00000000800027dc <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027dc:	7179                	addi	sp,sp,-48
    800027de:	f406                	sd	ra,40(sp)
    800027e0:	f022                	sd	s0,32(sp)
    800027e2:	ec26                	sd	s1,24(sp)
    800027e4:	e84a                	sd	s2,16(sp)
    800027e6:	e44e                	sd	s3,8(sp)
    800027e8:	e052                	sd	s4,0(sp)
    800027ea:	1800                	addi	s0,sp,48
    800027ec:	84aa                	mv	s1,a0
    800027ee:	892e                	mv	s2,a1
    800027f0:	89b2                	mv	s3,a2
    800027f2:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800027f4:	fffff097          	auipc	ra,0xfffff
    800027f8:	478080e7          	jalr	1144(ra) # 80001c6c <myproc>
    if (user_dst)
    800027fc:	c08d                	beqz	s1,8000281e <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    800027fe:	86d2                	mv	a3,s4
    80002800:	864e                	mv	a2,s3
    80002802:	85ca                	mv	a1,s2
    80002804:	6928                	ld	a0,80(a0)
    80002806:	fffff097          	auipc	ra,0xfffff
    8000280a:	fa4080e7          	jalr	-92(ra) # 800017aa <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    8000280e:	70a2                	ld	ra,40(sp)
    80002810:	7402                	ld	s0,32(sp)
    80002812:	64e2                	ld	s1,24(sp)
    80002814:	6942                	ld	s2,16(sp)
    80002816:	69a2                	ld	s3,8(sp)
    80002818:	6a02                	ld	s4,0(sp)
    8000281a:	6145                	addi	sp,sp,48
    8000281c:	8082                	ret
        memmove((char *)dst, src, len);
    8000281e:	000a061b          	sext.w	a2,s4
    80002822:	85ce                	mv	a1,s3
    80002824:	854a                	mv	a0,s2
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	660080e7          	jalr	1632(ra) # 80000e86 <memmove>
        return 0;
    8000282e:	8526                	mv	a0,s1
    80002830:	bff9                	j	8000280e <either_copyout+0x32>

0000000080002832 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002832:	7179                	addi	sp,sp,-48
    80002834:	f406                	sd	ra,40(sp)
    80002836:	f022                	sd	s0,32(sp)
    80002838:	ec26                	sd	s1,24(sp)
    8000283a:	e84a                	sd	s2,16(sp)
    8000283c:	e44e                	sd	s3,8(sp)
    8000283e:	e052                	sd	s4,0(sp)
    80002840:	1800                	addi	s0,sp,48
    80002842:	892a                	mv	s2,a0
    80002844:	84ae                	mv	s1,a1
    80002846:	89b2                	mv	s3,a2
    80002848:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000284a:	fffff097          	auipc	ra,0xfffff
    8000284e:	422080e7          	jalr	1058(ra) # 80001c6c <myproc>
    if (user_src)
    80002852:	c08d                	beqz	s1,80002874 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    80002854:	86d2                	mv	a3,s4
    80002856:	864e                	mv	a2,s3
    80002858:	85ca                	mv	a1,s2
    8000285a:	6928                	ld	a0,80(a0)
    8000285c:	fffff097          	auipc	ra,0xfffff
    80002860:	fda080e7          	jalr	-38(ra) # 80001836 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002864:	70a2                	ld	ra,40(sp)
    80002866:	7402                	ld	s0,32(sp)
    80002868:	64e2                	ld	s1,24(sp)
    8000286a:	6942                	ld	s2,16(sp)
    8000286c:	69a2                	ld	s3,8(sp)
    8000286e:	6a02                	ld	s4,0(sp)
    80002870:	6145                	addi	sp,sp,48
    80002872:	8082                	ret
        memmove(dst, (char *)src, len);
    80002874:	000a061b          	sext.w	a2,s4
    80002878:	85ce                	mv	a1,s3
    8000287a:	854a                	mv	a0,s2
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	60a080e7          	jalr	1546(ra) # 80000e86 <memmove>
        return 0;
    80002884:	8526                	mv	a0,s1
    80002886:	bff9                	j	80002864 <either_copyin+0x32>

0000000080002888 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002888:	715d                	addi	sp,sp,-80
    8000288a:	e486                	sd	ra,72(sp)
    8000288c:	e0a2                	sd	s0,64(sp)
    8000288e:	fc26                	sd	s1,56(sp)
    80002890:	f84a                	sd	s2,48(sp)
    80002892:	f44e                	sd	s3,40(sp)
    80002894:	f052                	sd	s4,32(sp)
    80002896:	ec56                	sd	s5,24(sp)
    80002898:	e85a                	sd	s6,16(sp)
    8000289a:	e45e                	sd	s7,8(sp)
    8000289c:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    8000289e:	00006517          	auipc	a0,0x6
    800028a2:	86250513          	addi	a0,a0,-1950 # 80008100 <digits+0xc0>
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	cf6080e7          	jalr	-778(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800028ae:	0022f497          	auipc	s1,0x22f
    800028b2:	99a48493          	addi	s1,s1,-1638 # 80231248 <proc+0x158>
    800028b6:	00234917          	auipc	s2,0x234
    800028ba:	39290913          	addi	s2,s2,914 # 80236c48 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028be:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800028c0:	00006997          	auipc	s3,0x6
    800028c4:	9f898993          	addi	s3,s3,-1544 # 800082b8 <digits+0x278>
        printf("%d <%s %s", p->pid, state, p->name);
    800028c8:	00006a97          	auipc	s5,0x6
    800028cc:	9f8a8a93          	addi	s5,s5,-1544 # 800082c0 <digits+0x280>
        printf("\n");
    800028d0:	00006a17          	auipc	s4,0x6
    800028d4:	830a0a13          	addi	s4,s4,-2000 # 80008100 <digits+0xc0>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028d8:	00006b97          	auipc	s7,0x6
    800028dc:	af8b8b93          	addi	s7,s7,-1288 # 800083d0 <states.0>
    800028e0:	a00d                	j	80002902 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    800028e2:	ed86a583          	lw	a1,-296(a3)
    800028e6:	8556                	mv	a0,s5
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	cb4080e7          	jalr	-844(ra) # 8000059c <printf>
        printf("\n");
    800028f0:	8552                	mv	a0,s4
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	caa080e7          	jalr	-854(ra) # 8000059c <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800028fa:	16848493          	addi	s1,s1,360
    800028fe:	03248263          	beq	s1,s2,80002922 <procdump+0x9a>
        if (p->state == UNUSED)
    80002902:	86a6                	mv	a3,s1
    80002904:	ec04a783          	lw	a5,-320(s1)
    80002908:	dbed                	beqz	a5,800028fa <procdump+0x72>
            state = "???";
    8000290a:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000290c:	fcfb6be3          	bltu	s6,a5,800028e2 <procdump+0x5a>
    80002910:	02079713          	slli	a4,a5,0x20
    80002914:	01d75793          	srli	a5,a4,0x1d
    80002918:	97de                	add	a5,a5,s7
    8000291a:	6390                	ld	a2,0(a5)
    8000291c:	f279                	bnez	a2,800028e2 <procdump+0x5a>
            state = "???";
    8000291e:	864e                	mv	a2,s3
    80002920:	b7c9                	j	800028e2 <procdump+0x5a>
    }
}
    80002922:	60a6                	ld	ra,72(sp)
    80002924:	6406                	ld	s0,64(sp)
    80002926:	74e2                	ld	s1,56(sp)
    80002928:	7942                	ld	s2,48(sp)
    8000292a:	79a2                	ld	s3,40(sp)
    8000292c:	7a02                	ld	s4,32(sp)
    8000292e:	6ae2                	ld	s5,24(sp)
    80002930:	6b42                	ld	s6,16(sp)
    80002932:	6ba2                	ld	s7,8(sp)
    80002934:	6161                	addi	sp,sp,80
    80002936:	8082                	ret

0000000080002938 <schedls>:

void schedls()
{
    80002938:	1141                	addi	sp,sp,-16
    8000293a:	e406                	sd	ra,8(sp)
    8000293c:	e022                	sd	s0,0(sp)
    8000293e:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002940:	00006517          	auipc	a0,0x6
    80002944:	99050513          	addi	a0,a0,-1648 # 800082d0 <digits+0x290>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	c54080e7          	jalr	-940(ra) # 8000059c <printf>
    printf("====================================\n");
    80002950:	00006517          	auipc	a0,0x6
    80002954:	9a850513          	addi	a0,a0,-1624 # 800082f8 <digits+0x2b8>
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	c44080e7          	jalr	-956(ra) # 8000059c <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002960:	00006717          	auipc	a4,0x6
    80002964:	07873703          	ld	a4,120(a4) # 800089d8 <available_schedulers+0x10>
    80002968:	00006797          	auipc	a5,0x6
    8000296c:	0107b783          	ld	a5,16(a5) # 80008978 <sched_pointer>
    80002970:	04f70663          	beq	a4,a5,800029bc <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002974:	00006517          	auipc	a0,0x6
    80002978:	9b450513          	addi	a0,a0,-1612 # 80008328 <digits+0x2e8>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	c20080e7          	jalr	-992(ra) # 8000059c <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002984:	00006617          	auipc	a2,0x6
    80002988:	05c62603          	lw	a2,92(a2) # 800089e0 <available_schedulers+0x18>
    8000298c:	00006597          	auipc	a1,0x6
    80002990:	03c58593          	addi	a1,a1,60 # 800089c8 <available_schedulers>
    80002994:	00006517          	auipc	a0,0x6
    80002998:	99c50513          	addi	a0,a0,-1636 # 80008330 <digits+0x2f0>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	c00080e7          	jalr	-1024(ra) # 8000059c <printf>
    }
    printf("\n*: current scheduler\n\n");
    800029a4:	00006517          	auipc	a0,0x6
    800029a8:	99450513          	addi	a0,a0,-1644 # 80008338 <digits+0x2f8>
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	bf0080e7          	jalr	-1040(ra) # 8000059c <printf>
}
    800029b4:	60a2                	ld	ra,8(sp)
    800029b6:	6402                	ld	s0,0(sp)
    800029b8:	0141                	addi	sp,sp,16
    800029ba:	8082                	ret
            printf("[*]\t");
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	96450513          	addi	a0,a0,-1692 # 80008320 <digits+0x2e0>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	bd8080e7          	jalr	-1064(ra) # 8000059c <printf>
    800029cc:	bf65                	j	80002984 <schedls+0x4c>

00000000800029ce <schedset>:

void schedset(int id)
{
    800029ce:	1141                	addi	sp,sp,-16
    800029d0:	e406                	sd	ra,8(sp)
    800029d2:	e022                	sd	s0,0(sp)
    800029d4:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    800029d6:	e90d                	bnez	a0,80002a08 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    800029d8:	00006797          	auipc	a5,0x6
    800029dc:	0007b783          	ld	a5,0(a5) # 800089d8 <available_schedulers+0x10>
    800029e0:	00006717          	auipc	a4,0x6
    800029e4:	f8f73c23          	sd	a5,-104(a4) # 80008978 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    800029e8:	00006597          	auipc	a1,0x6
    800029ec:	fe058593          	addi	a1,a1,-32 # 800089c8 <available_schedulers>
    800029f0:	00006517          	auipc	a0,0x6
    800029f4:	98850513          	addi	a0,a0,-1656 # 80008378 <digits+0x338>
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	ba4080e7          	jalr	-1116(ra) # 8000059c <printf>
}
    80002a00:	60a2                	ld	ra,8(sp)
    80002a02:	6402                	ld	s0,0(sp)
    80002a04:	0141                	addi	sp,sp,16
    80002a06:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002a08:	00006517          	auipc	a0,0x6
    80002a0c:	94850513          	addi	a0,a0,-1720 # 80008350 <digits+0x310>
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	b8c080e7          	jalr	-1140(ra) # 8000059c <printf>
        return;
    80002a18:	b7e5                	j	80002a00 <schedset+0x32>

0000000080002a1a <get_proc_by_pid>:

struct proc *get_proc_by_pid(int pid)
{
    80002a1a:	7179                	addi	sp,sp,-48
    80002a1c:	f406                	sd	ra,40(sp)
    80002a1e:	f022                	sd	s0,32(sp)
    80002a20:	ec26                	sd	s1,24(sp)
    80002a22:	e84a                	sd	s2,16(sp)
    80002a24:	e44e                	sd	s3,8(sp)
    80002a26:	1800                	addi	s0,sp,48
    80002a28:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002a2a:	0022e497          	auipc	s1,0x22e
    80002a2e:	6c648493          	addi	s1,s1,1734 # 802310f0 <proc>
    80002a32:	00234997          	auipc	s3,0x234
    80002a36:	0be98993          	addi	s3,s3,190 # 80236af0 <tickslock>
    {
        acquire(&p->lock);
    80002a3a:	8526                	mv	a0,s1
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	2f2080e7          	jalr	754(ra) # 80000d2e <acquire>
        if (p->pid == pid)
    80002a44:	589c                	lw	a5,48(s1)
    80002a46:	01278d63          	beq	a5,s2,80002a60 <get_proc_by_pid+0x46>
        {
            release(&p->lock);
            return p;
        }
        release(&p->lock);
    80002a4a:	8526                	mv	a0,s1
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	396080e7          	jalr	918(ra) # 80000de2 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002a54:	16848493          	addi	s1,s1,360
    80002a58:	ff3491e3          	bne	s1,s3,80002a3a <get_proc_by_pid+0x20>
    }
    return 0;
    80002a5c:	4481                	li	s1,0
    80002a5e:	a031                	j	80002a6a <get_proc_by_pid+0x50>
            release(&p->lock);
    80002a60:	8526                	mv	a0,s1
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	380080e7          	jalr	896(ra) # 80000de2 <release>
    80002a6a:	8526                	mv	a0,s1
    80002a6c:	70a2                	ld	ra,40(sp)
    80002a6e:	7402                	ld	s0,32(sp)
    80002a70:	64e2                	ld	s1,24(sp)
    80002a72:	6942                	ld	s2,16(sp)
    80002a74:	69a2                	ld	s3,8(sp)
    80002a76:	6145                	addi	sp,sp,48
    80002a78:	8082                	ret

0000000080002a7a <swtch>:
    80002a7a:	00153023          	sd	ra,0(a0)
    80002a7e:	00253423          	sd	sp,8(a0)
    80002a82:	e900                	sd	s0,16(a0)
    80002a84:	ed04                	sd	s1,24(a0)
    80002a86:	03253023          	sd	s2,32(a0)
    80002a8a:	03353423          	sd	s3,40(a0)
    80002a8e:	03453823          	sd	s4,48(a0)
    80002a92:	03553c23          	sd	s5,56(a0)
    80002a96:	05653023          	sd	s6,64(a0)
    80002a9a:	05753423          	sd	s7,72(a0)
    80002a9e:	05853823          	sd	s8,80(a0)
    80002aa2:	05953c23          	sd	s9,88(a0)
    80002aa6:	07a53023          	sd	s10,96(a0)
    80002aaa:	07b53423          	sd	s11,104(a0)
    80002aae:	0005b083          	ld	ra,0(a1)
    80002ab2:	0085b103          	ld	sp,8(a1)
    80002ab6:	6980                	ld	s0,16(a1)
    80002ab8:	6d84                	ld	s1,24(a1)
    80002aba:	0205b903          	ld	s2,32(a1)
    80002abe:	0285b983          	ld	s3,40(a1)
    80002ac2:	0305ba03          	ld	s4,48(a1)
    80002ac6:	0385ba83          	ld	s5,56(a1)
    80002aca:	0405bb03          	ld	s6,64(a1)
    80002ace:	0485bb83          	ld	s7,72(a1)
    80002ad2:	0505bc03          	ld	s8,80(a1)
    80002ad6:	0585bc83          	ld	s9,88(a1)
    80002ada:	0605bd03          	ld	s10,96(a1)
    80002ade:	0685bd83          	ld	s11,104(a1)
    80002ae2:	8082                	ret

0000000080002ae4 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002ae4:	1141                	addi	sp,sp,-16
    80002ae6:	e406                	sd	ra,8(sp)
    80002ae8:	e022                	sd	s0,0(sp)
    80002aea:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002aec:	00006597          	auipc	a1,0x6
    80002af0:	91458593          	addi	a1,a1,-1772 # 80008400 <states.0+0x30>
    80002af4:	00234517          	auipc	a0,0x234
    80002af8:	ffc50513          	addi	a0,a0,-4 # 80236af0 <tickslock>
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	1a2080e7          	jalr	418(ra) # 80000c9e <initlock>
}
    80002b04:	60a2                	ld	ra,8(sp)
    80002b06:	6402                	ld	s0,0(sp)
    80002b08:	0141                	addi	sp,sp,16
    80002b0a:	8082                	ret

0000000080002b0c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002b0c:	1141                	addi	sp,sp,-16
    80002b0e:	e422                	sd	s0,8(sp)
    80002b10:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b12:	00003797          	auipc	a5,0x3
    80002b16:	61e78793          	addi	a5,a5,1566 # 80006130 <kernelvec>
    80002b1a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b1e:	6422                	ld	s0,8(sp)
    80002b20:	0141                	addi	sp,sp,16
    80002b22:	8082                	ret

0000000080002b24 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002b24:	1141                	addi	sp,sp,-16
    80002b26:	e406                	sd	ra,8(sp)
    80002b28:	e022                	sd	s0,0(sp)
    80002b2a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	140080e7          	jalr	320(ra) # 80001c6c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b34:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b38:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b3a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b3e:	00004697          	auipc	a3,0x4
    80002b42:	4c268693          	addi	a3,a3,1218 # 80007000 <_trampoline>
    80002b46:	00004717          	auipc	a4,0x4
    80002b4a:	4ba70713          	addi	a4,a4,1210 # 80007000 <_trampoline>
    80002b4e:	8f15                	sub	a4,a4,a3
    80002b50:	040007b7          	lui	a5,0x4000
    80002b54:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002b56:	07b2                	slli	a5,a5,0xc
    80002b58:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b5a:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b5e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b60:	18002673          	csrr	a2,satp
    80002b64:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b66:	6d30                	ld	a2,88(a0)
    80002b68:	6138                	ld	a4,64(a0)
    80002b6a:	6585                	lui	a1,0x1
    80002b6c:	972e                	add	a4,a4,a1
    80002b6e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b70:	6d38                	ld	a4,88(a0)
    80002b72:	00000617          	auipc	a2,0x0
    80002b76:	13060613          	addi	a2,a2,304 # 80002ca2 <usertrap>
    80002b7a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002b7c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b7e:	8612                	mv	a2,tp
    80002b80:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b82:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b86:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b8a:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b8e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b92:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b94:	6f18                	ld	a4,24(a4)
    80002b96:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b9a:	6928                	ld	a0,80(a0)
    80002b9c:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b9e:	00004717          	auipc	a4,0x4
    80002ba2:	4fe70713          	addi	a4,a4,1278 # 8000709c <userret>
    80002ba6:	8f15                	sub	a4,a4,a3
    80002ba8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002baa:	577d                	li	a4,-1
    80002bac:	177e                	slli	a4,a4,0x3f
    80002bae:	8d59                	or	a0,a0,a4
    80002bb0:	9782                	jalr	a5
}
    80002bb2:	60a2                	ld	ra,8(sp)
    80002bb4:	6402                	ld	s0,0(sp)
    80002bb6:	0141                	addi	sp,sp,16
    80002bb8:	8082                	ret

0000000080002bba <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002bba:	1101                	addi	sp,sp,-32
    80002bbc:	ec06                	sd	ra,24(sp)
    80002bbe:	e822                	sd	s0,16(sp)
    80002bc0:	e426                	sd	s1,8(sp)
    80002bc2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002bc4:	00234497          	auipc	s1,0x234
    80002bc8:	f2c48493          	addi	s1,s1,-212 # 80236af0 <tickslock>
    80002bcc:	8526                	mv	a0,s1
    80002bce:	ffffe097          	auipc	ra,0xffffe
    80002bd2:	160080e7          	jalr	352(ra) # 80000d2e <acquire>
  ticks++;
    80002bd6:	00006517          	auipc	a0,0x6
    80002bda:	e7a50513          	addi	a0,a0,-390 # 80008a50 <ticks>
    80002bde:	411c                	lw	a5,0(a0)
    80002be0:	2785                	addiw	a5,a5,1
    80002be2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	854080e7          	jalr	-1964(ra) # 80002438 <wakeup>
  release(&tickslock);
    80002bec:	8526                	mv	a0,s1
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	1f4080e7          	jalr	500(ra) # 80000de2 <release>
}
    80002bf6:	60e2                	ld	ra,24(sp)
    80002bf8:	6442                	ld	s0,16(sp)
    80002bfa:	64a2                	ld	s1,8(sp)
    80002bfc:	6105                	addi	sp,sp,32
    80002bfe:	8082                	ret

0000000080002c00 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002c00:	1101                	addi	sp,sp,-32
    80002c02:	ec06                	sd	ra,24(sp)
    80002c04:	e822                	sd	s0,16(sp)
    80002c06:	e426                	sd	s1,8(sp)
    80002c08:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c0a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002c0e:	00074d63          	bltz	a4,80002c28 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002c12:	57fd                	li	a5,-1
    80002c14:	17fe                	slli	a5,a5,0x3f
    80002c16:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002c18:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002c1a:	06f70363          	beq	a4,a5,80002c80 <devintr+0x80>
  }
}
    80002c1e:	60e2                	ld	ra,24(sp)
    80002c20:	6442                	ld	s0,16(sp)
    80002c22:	64a2                	ld	s1,8(sp)
    80002c24:	6105                	addi	sp,sp,32
    80002c26:	8082                	ret
      (scause & 0xff) == 9)
    80002c28:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002c2c:	46a5                	li	a3,9
    80002c2e:	fed792e3          	bne	a5,a3,80002c12 <devintr+0x12>
    int irq = plic_claim();
    80002c32:	00003097          	auipc	ra,0x3
    80002c36:	606080e7          	jalr	1542(ra) # 80006238 <plic_claim>
    80002c3a:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002c3c:	47a9                	li	a5,10
    80002c3e:	02f50763          	beq	a0,a5,80002c6c <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002c42:	4785                	li	a5,1
    80002c44:	02f50963          	beq	a0,a5,80002c76 <devintr+0x76>
    return 1;
    80002c48:	4505                	li	a0,1
    else if (irq)
    80002c4a:	d8f1                	beqz	s1,80002c1e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c4c:	85a6                	mv	a1,s1
    80002c4e:	00005517          	auipc	a0,0x5
    80002c52:	7ba50513          	addi	a0,a0,1978 # 80008408 <states.0+0x38>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	946080e7          	jalr	-1722(ra) # 8000059c <printf>
      plic_complete(irq);
    80002c5e:	8526                	mv	a0,s1
    80002c60:	00003097          	auipc	ra,0x3
    80002c64:	5fc080e7          	jalr	1532(ra) # 8000625c <plic_complete>
    return 1;
    80002c68:	4505                	li	a0,1
    80002c6a:	bf55                	j	80002c1e <devintr+0x1e>
      uartintr();
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	d3e080e7          	jalr	-706(ra) # 800009aa <uartintr>
    80002c74:	b7ed                	j	80002c5e <devintr+0x5e>
      virtio_disk_intr();
    80002c76:	00004097          	auipc	ra,0x4
    80002c7a:	aae080e7          	jalr	-1362(ra) # 80006724 <virtio_disk_intr>
    80002c7e:	b7c5                	j	80002c5e <devintr+0x5e>
    if (cpuid() == 0)
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	fc0080e7          	jalr	-64(ra) # 80001c40 <cpuid>
    80002c88:	c901                	beqz	a0,80002c98 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c8a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c8e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c90:	14479073          	csrw	sip,a5
    return 2;
    80002c94:	4509                	li	a0,2
    80002c96:	b761                	j	80002c1e <devintr+0x1e>
      clockintr();
    80002c98:	00000097          	auipc	ra,0x0
    80002c9c:	f22080e7          	jalr	-222(ra) # 80002bba <clockintr>
    80002ca0:	b7ed                	j	80002c8a <devintr+0x8a>

0000000080002ca2 <usertrap>:
{
    80002ca2:	1101                	addi	sp,sp,-32
    80002ca4:	ec06                	sd	ra,24(sp)
    80002ca6:	e822                	sd	s0,16(sp)
    80002ca8:	e426                	sd	s1,8(sp)
    80002caa:	e04a                	sd	s2,0(sp)
    80002cac:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cae:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002cb2:	1007f793          	andi	a5,a5,256
    80002cb6:	e7b9                	bnez	a5,80002d04 <usertrap+0x62>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cb8:	00003797          	auipc	a5,0x3
    80002cbc:	47878793          	addi	a5,a5,1144 # 80006130 <kernelvec>
    80002cc0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	fa8080e7          	jalr	-88(ra) # 80001c6c <myproc>
    80002ccc:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002cce:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cd0:	14102773          	csrr	a4,sepc
    80002cd4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cd6:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002cda:	47a1                	li	a5,8
    80002cdc:	02f70c63          	beq	a4,a5,80002d14 <usertrap+0x72>
    80002ce0:	14202773          	csrr	a4,scause
  else if (r_scause() == 15)
    80002ce4:	47bd                	li	a5,15
    80002ce6:	08f70063          	beq	a4,a5,80002d66 <usertrap+0xc4>
  else if ((which_dev = devintr()) != 0)
    80002cea:	00000097          	auipc	ra,0x0
    80002cee:	f16080e7          	jalr	-234(ra) # 80002c00 <devintr>
    80002cf2:	892a                	mv	s2,a0
    80002cf4:	c549                	beqz	a0,80002d7e <usertrap+0xdc>
  if (killed(p))
    80002cf6:	8526                	mv	a0,s1
    80002cf8:	00000097          	auipc	ra,0x0
    80002cfc:	984080e7          	jalr	-1660(ra) # 8000267c <killed>
    80002d00:	c171                	beqz	a0,80002dc4 <usertrap+0x122>
    80002d02:	a865                	j	80002dba <usertrap+0x118>
    panic("usertrap: not from user mode");
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	72450513          	addi	a0,a0,1828 # 80008428 <states.0+0x58>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	834080e7          	jalr	-1996(ra) # 80000540 <panic>
    if (killed(p))
    80002d14:	00000097          	auipc	ra,0x0
    80002d18:	968080e7          	jalr	-1688(ra) # 8000267c <killed>
    80002d1c:	ed1d                	bnez	a0,80002d5a <usertrap+0xb8>
    p->trapframe->epc += 4;
    80002d1e:	6cb8                	ld	a4,88(s1)
    80002d20:	6f1c                	ld	a5,24(a4)
    80002d22:	0791                	addi	a5,a5,4
    80002d24:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d26:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d2a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d2e:	10079073          	csrw	sstatus,a5
    syscall();
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	2ec080e7          	jalr	748(ra) # 8000301e <syscall>
  if (killed(p))
    80002d3a:	8526                	mv	a0,s1
    80002d3c:	00000097          	auipc	ra,0x0
    80002d40:	940080e7          	jalr	-1728(ra) # 8000267c <killed>
    80002d44:	e935                	bnez	a0,80002db8 <usertrap+0x116>
  usertrapret();
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	dde080e7          	jalr	-546(ra) # 80002b24 <usertrapret>
}
    80002d4e:	60e2                	ld	ra,24(sp)
    80002d50:	6442                	ld	s0,16(sp)
    80002d52:	64a2                	ld	s1,8(sp)
    80002d54:	6902                	ld	s2,0(sp)
    80002d56:	6105                	addi	sp,sp,32
    80002d58:	8082                	ret
      exit(-1);
    80002d5a:	557d                	li	a0,-1
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	7ac080e7          	jalr	1964(ra) # 80002508 <exit>
    80002d64:	bf6d                	j	80002d1e <usertrap+0x7c>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d66:	143025f3          	csrr	a1,stval
    if ((cowfault(p->pagetable, r_stval())) < 0)
    80002d6a:	6928                	ld	a0,80(a0)
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	c08080e7          	jalr	-1016(ra) # 80001974 <cowfault>
    80002d74:	fc0553e3          	bgez	a0,80002d3a <usertrap+0x98>
      p->killed = 1;
    80002d78:	4785                	li	a5,1
    80002d7a:	d49c                	sw	a5,40(s1)
    80002d7c:	bf7d                	j	80002d3a <usertrap+0x98>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d7e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d82:	5890                	lw	a2,48(s1)
    80002d84:	00005517          	auipc	a0,0x5
    80002d88:	6c450513          	addi	a0,a0,1732 # 80008448 <states.0+0x78>
    80002d8c:	ffffe097          	auipc	ra,0xffffe
    80002d90:	810080e7          	jalr	-2032(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d94:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d98:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d9c:	00005517          	auipc	a0,0x5
    80002da0:	6dc50513          	addi	a0,a0,1756 # 80008478 <states.0+0xa8>
    80002da4:	ffffd097          	auipc	ra,0xffffd
    80002da8:	7f8080e7          	jalr	2040(ra) # 8000059c <printf>
    setkilled(p);
    80002dac:	8526                	mv	a0,s1
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	8a2080e7          	jalr	-1886(ra) # 80002650 <setkilled>
    80002db6:	b751                	j	80002d3a <usertrap+0x98>
  if (killed(p))
    80002db8:	4901                	li	s2,0
    exit(-1);
    80002dba:	557d                	li	a0,-1
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	74c080e7          	jalr	1868(ra) # 80002508 <exit>
  if (which_dev == 2)
    80002dc4:	4789                	li	a5,2
    80002dc6:	f8f910e3          	bne	s2,a5,80002d46 <usertrap+0xa4>
    yield();
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	5ce080e7          	jalr	1486(ra) # 80002398 <yield>
    80002dd2:	bf95                	j	80002d46 <usertrap+0xa4>

0000000080002dd4 <kerneltrap>:
{
    80002dd4:	7179                	addi	sp,sp,-48
    80002dd6:	f406                	sd	ra,40(sp)
    80002dd8:	f022                	sd	s0,32(sp)
    80002dda:	ec26                	sd	s1,24(sp)
    80002ddc:	e84a                	sd	s2,16(sp)
    80002dde:	e44e                	sd	s3,8(sp)
    80002de0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002de2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002de6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dea:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002dee:	1004f793          	andi	a5,s1,256
    80002df2:	cb85                	beqz	a5,80002e22 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002df4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002df8:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002dfa:	ef85                	bnez	a5,80002e32 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	e04080e7          	jalr	-508(ra) # 80002c00 <devintr>
    80002e04:	cd1d                	beqz	a0,80002e42 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e06:	4789                	li	a5,2
    80002e08:	06f50a63          	beq	a0,a5,80002e7c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e0c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e10:	10049073          	csrw	sstatus,s1
}
    80002e14:	70a2                	ld	ra,40(sp)
    80002e16:	7402                	ld	s0,32(sp)
    80002e18:	64e2                	ld	s1,24(sp)
    80002e1a:	6942                	ld	s2,16(sp)
    80002e1c:	69a2                	ld	s3,8(sp)
    80002e1e:	6145                	addi	sp,sp,48
    80002e20:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e22:	00005517          	auipc	a0,0x5
    80002e26:	67650513          	addi	a0,a0,1654 # 80008498 <states.0+0xc8>
    80002e2a:	ffffd097          	auipc	ra,0xffffd
    80002e2e:	716080e7          	jalr	1814(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002e32:	00005517          	auipc	a0,0x5
    80002e36:	68e50513          	addi	a0,a0,1678 # 800084c0 <states.0+0xf0>
    80002e3a:	ffffd097          	auipc	ra,0xffffd
    80002e3e:	706080e7          	jalr	1798(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002e42:	85ce                	mv	a1,s3
    80002e44:	00005517          	auipc	a0,0x5
    80002e48:	69c50513          	addi	a0,a0,1692 # 800084e0 <states.0+0x110>
    80002e4c:	ffffd097          	auipc	ra,0xffffd
    80002e50:	750080e7          	jalr	1872(ra) # 8000059c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e54:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e58:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e5c:	00005517          	auipc	a0,0x5
    80002e60:	69450513          	addi	a0,a0,1684 # 800084f0 <states.0+0x120>
    80002e64:	ffffd097          	auipc	ra,0xffffd
    80002e68:	738080e7          	jalr	1848(ra) # 8000059c <printf>
    panic("kerneltrap");
    80002e6c:	00005517          	auipc	a0,0x5
    80002e70:	69c50513          	addi	a0,a0,1692 # 80008508 <states.0+0x138>
    80002e74:	ffffd097          	auipc	ra,0xffffd
    80002e78:	6cc080e7          	jalr	1740(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	df0080e7          	jalr	-528(ra) # 80001c6c <myproc>
    80002e84:	d541                	beqz	a0,80002e0c <kerneltrap+0x38>
    80002e86:	fffff097          	auipc	ra,0xfffff
    80002e8a:	de6080e7          	jalr	-538(ra) # 80001c6c <myproc>
    80002e8e:	4d18                	lw	a4,24(a0)
    80002e90:	4791                	li	a5,4
    80002e92:	f6f71de3          	bne	a4,a5,80002e0c <kerneltrap+0x38>
    yield();
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	502080e7          	jalr	1282(ra) # 80002398 <yield>
    80002e9e:	b7bd                	j	80002e0c <kerneltrap+0x38>

0000000080002ea0 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ea0:	1101                	addi	sp,sp,-32
    80002ea2:	ec06                	sd	ra,24(sp)
    80002ea4:	e822                	sd	s0,16(sp)
    80002ea6:	e426                	sd	s1,8(sp)
    80002ea8:	1000                	addi	s0,sp,32
    80002eaa:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	dc0080e7          	jalr	-576(ra) # 80001c6c <myproc>
    switch (n)
    80002eb4:	4795                	li	a5,5
    80002eb6:	0497e163          	bltu	a5,s1,80002ef8 <argraw+0x58>
    80002eba:	048a                	slli	s1,s1,0x2
    80002ebc:	00005717          	auipc	a4,0x5
    80002ec0:	68470713          	addi	a4,a4,1668 # 80008540 <states.0+0x170>
    80002ec4:	94ba                	add	s1,s1,a4
    80002ec6:	409c                	lw	a5,0(s1)
    80002ec8:	97ba                	add	a5,a5,a4
    80002eca:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002ecc:	6d3c                	ld	a5,88(a0)
    80002ece:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002ed0:	60e2                	ld	ra,24(sp)
    80002ed2:	6442                	ld	s0,16(sp)
    80002ed4:	64a2                	ld	s1,8(sp)
    80002ed6:	6105                	addi	sp,sp,32
    80002ed8:	8082                	ret
        return p->trapframe->a1;
    80002eda:	6d3c                	ld	a5,88(a0)
    80002edc:	7fa8                	ld	a0,120(a5)
    80002ede:	bfcd                	j	80002ed0 <argraw+0x30>
        return p->trapframe->a2;
    80002ee0:	6d3c                	ld	a5,88(a0)
    80002ee2:	63c8                	ld	a0,128(a5)
    80002ee4:	b7f5                	j	80002ed0 <argraw+0x30>
        return p->trapframe->a3;
    80002ee6:	6d3c                	ld	a5,88(a0)
    80002ee8:	67c8                	ld	a0,136(a5)
    80002eea:	b7dd                	j	80002ed0 <argraw+0x30>
        return p->trapframe->a4;
    80002eec:	6d3c                	ld	a5,88(a0)
    80002eee:	6bc8                	ld	a0,144(a5)
    80002ef0:	b7c5                	j	80002ed0 <argraw+0x30>
        return p->trapframe->a5;
    80002ef2:	6d3c                	ld	a5,88(a0)
    80002ef4:	6fc8                	ld	a0,152(a5)
    80002ef6:	bfe9                	j	80002ed0 <argraw+0x30>
    panic("argraw");
    80002ef8:	00005517          	auipc	a0,0x5
    80002efc:	62050513          	addi	a0,a0,1568 # 80008518 <states.0+0x148>
    80002f00:	ffffd097          	auipc	ra,0xffffd
    80002f04:	640080e7          	jalr	1600(ra) # 80000540 <panic>

0000000080002f08 <fetchaddr>:
{
    80002f08:	1101                	addi	sp,sp,-32
    80002f0a:	ec06                	sd	ra,24(sp)
    80002f0c:	e822                	sd	s0,16(sp)
    80002f0e:	e426                	sd	s1,8(sp)
    80002f10:	e04a                	sd	s2,0(sp)
    80002f12:	1000                	addi	s0,sp,32
    80002f14:	84aa                	mv	s1,a0
    80002f16:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	d54080e7          	jalr	-684(ra) # 80001c6c <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f20:	653c                	ld	a5,72(a0)
    80002f22:	02f4f863          	bgeu	s1,a5,80002f52 <fetchaddr+0x4a>
    80002f26:	00848713          	addi	a4,s1,8
    80002f2a:	02e7e663          	bltu	a5,a4,80002f56 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f2e:	46a1                	li	a3,8
    80002f30:	8626                	mv	a2,s1
    80002f32:	85ca                	mv	a1,s2
    80002f34:	6928                	ld	a0,80(a0)
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	900080e7          	jalr	-1792(ra) # 80001836 <copyin>
    80002f3e:	00a03533          	snez	a0,a0
    80002f42:	40a00533          	neg	a0,a0
}
    80002f46:	60e2                	ld	ra,24(sp)
    80002f48:	6442                	ld	s0,16(sp)
    80002f4a:	64a2                	ld	s1,8(sp)
    80002f4c:	6902                	ld	s2,0(sp)
    80002f4e:	6105                	addi	sp,sp,32
    80002f50:	8082                	ret
        return -1;
    80002f52:	557d                	li	a0,-1
    80002f54:	bfcd                	j	80002f46 <fetchaddr+0x3e>
    80002f56:	557d                	li	a0,-1
    80002f58:	b7fd                	j	80002f46 <fetchaddr+0x3e>

0000000080002f5a <fetchstr>:
{
    80002f5a:	7179                	addi	sp,sp,-48
    80002f5c:	f406                	sd	ra,40(sp)
    80002f5e:	f022                	sd	s0,32(sp)
    80002f60:	ec26                	sd	s1,24(sp)
    80002f62:	e84a                	sd	s2,16(sp)
    80002f64:	e44e                	sd	s3,8(sp)
    80002f66:	1800                	addi	s0,sp,48
    80002f68:	892a                	mv	s2,a0
    80002f6a:	84ae                	mv	s1,a1
    80002f6c:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	cfe080e7          	jalr	-770(ra) # 80001c6c <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002f76:	86ce                	mv	a3,s3
    80002f78:	864a                	mv	a2,s2
    80002f7a:	85a6                	mv	a1,s1
    80002f7c:	6928                	ld	a0,80(a0)
    80002f7e:	fffff097          	auipc	ra,0xfffff
    80002f82:	946080e7          	jalr	-1722(ra) # 800018c4 <copyinstr>
    80002f86:	00054e63          	bltz	a0,80002fa2 <fetchstr+0x48>
    return strlen(buf);
    80002f8a:	8526                	mv	a0,s1
    80002f8c:	ffffe097          	auipc	ra,0xffffe
    80002f90:	01a080e7          	jalr	26(ra) # 80000fa6 <strlen>
}
    80002f94:	70a2                	ld	ra,40(sp)
    80002f96:	7402                	ld	s0,32(sp)
    80002f98:	64e2                	ld	s1,24(sp)
    80002f9a:	6942                	ld	s2,16(sp)
    80002f9c:	69a2                	ld	s3,8(sp)
    80002f9e:	6145                	addi	sp,sp,48
    80002fa0:	8082                	ret
        return -1;
    80002fa2:	557d                	li	a0,-1
    80002fa4:	bfc5                	j	80002f94 <fetchstr+0x3a>

0000000080002fa6 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002fa6:	1101                	addi	sp,sp,-32
    80002fa8:	ec06                	sd	ra,24(sp)
    80002faa:	e822                	sd	s0,16(sp)
    80002fac:	e426                	sd	s1,8(sp)
    80002fae:	1000                	addi	s0,sp,32
    80002fb0:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002fb2:	00000097          	auipc	ra,0x0
    80002fb6:	eee080e7          	jalr	-274(ra) # 80002ea0 <argraw>
    80002fba:	c088                	sw	a0,0(s1)
}
    80002fbc:	60e2                	ld	ra,24(sp)
    80002fbe:	6442                	ld	s0,16(sp)
    80002fc0:	64a2                	ld	s1,8(sp)
    80002fc2:	6105                	addi	sp,sp,32
    80002fc4:	8082                	ret

0000000080002fc6 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002fc6:	1101                	addi	sp,sp,-32
    80002fc8:	ec06                	sd	ra,24(sp)
    80002fca:	e822                	sd	s0,16(sp)
    80002fcc:	e426                	sd	s1,8(sp)
    80002fce:	1000                	addi	s0,sp,32
    80002fd0:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002fd2:	00000097          	auipc	ra,0x0
    80002fd6:	ece080e7          	jalr	-306(ra) # 80002ea0 <argraw>
    80002fda:	e088                	sd	a0,0(s1)
}
    80002fdc:	60e2                	ld	ra,24(sp)
    80002fde:	6442                	ld	s0,16(sp)
    80002fe0:	64a2                	ld	s1,8(sp)
    80002fe2:	6105                	addi	sp,sp,32
    80002fe4:	8082                	ret

0000000080002fe6 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002fe6:	7179                	addi	sp,sp,-48
    80002fe8:	f406                	sd	ra,40(sp)
    80002fea:	f022                	sd	s0,32(sp)
    80002fec:	ec26                	sd	s1,24(sp)
    80002fee:	e84a                	sd	s2,16(sp)
    80002ff0:	1800                	addi	s0,sp,48
    80002ff2:	84ae                	mv	s1,a1
    80002ff4:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80002ff6:	fd840593          	addi	a1,s0,-40
    80002ffa:	00000097          	auipc	ra,0x0
    80002ffe:	fcc080e7          	jalr	-52(ra) # 80002fc6 <argaddr>
    return fetchstr(addr, buf, max);
    80003002:	864a                	mv	a2,s2
    80003004:	85a6                	mv	a1,s1
    80003006:	fd843503          	ld	a0,-40(s0)
    8000300a:	00000097          	auipc	ra,0x0
    8000300e:	f50080e7          	jalr	-176(ra) # 80002f5a <fetchstr>
}
    80003012:	70a2                	ld	ra,40(sp)
    80003014:	7402                	ld	s0,32(sp)
    80003016:	64e2                	ld	s1,24(sp)
    80003018:	6942                	ld	s2,16(sp)
    8000301a:	6145                	addi	sp,sp,48
    8000301c:	8082                	ret

000000008000301e <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    8000301e:	1101                	addi	sp,sp,-32
    80003020:	ec06                	sd	ra,24(sp)
    80003022:	e822                	sd	s0,16(sp)
    80003024:	e426                	sd	s1,8(sp)
    80003026:	e04a                	sd	s2,0(sp)
    80003028:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    8000302a:	fffff097          	auipc	ra,0xfffff
    8000302e:	c42080e7          	jalr	-958(ra) # 80001c6c <myproc>
    80003032:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80003034:	05853903          	ld	s2,88(a0)
    80003038:	0a893783          	ld	a5,168(s2)
    8000303c:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003040:	37fd                	addiw	a5,a5,-1
    80003042:	4765                	li	a4,25
    80003044:	00f76f63          	bltu	a4,a5,80003062 <syscall+0x44>
    80003048:	00369713          	slli	a4,a3,0x3
    8000304c:	00005797          	auipc	a5,0x5
    80003050:	50c78793          	addi	a5,a5,1292 # 80008558 <syscalls>
    80003054:	97ba                	add	a5,a5,a4
    80003056:	639c                	ld	a5,0(a5)
    80003058:	c789                	beqz	a5,80003062 <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    8000305a:	9782                	jalr	a5
    8000305c:	06a93823          	sd	a0,112(s2)
    80003060:	a839                	j	8000307e <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    80003062:	15848613          	addi	a2,s1,344
    80003066:	588c                	lw	a1,48(s1)
    80003068:	00005517          	auipc	a0,0x5
    8000306c:	4b850513          	addi	a0,a0,1208 # 80008520 <states.0+0x150>
    80003070:	ffffd097          	auipc	ra,0xffffd
    80003074:	52c080e7          	jalr	1324(ra) # 8000059c <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    80003078:	6cbc                	ld	a5,88(s1)
    8000307a:	577d                	li	a4,-1
    8000307c:	fbb8                	sd	a4,112(a5)
    }
}
    8000307e:	60e2                	ld	ra,24(sp)
    80003080:	6442                	ld	s0,16(sp)
    80003082:	64a2                	ld	s1,8(sp)
    80003084:	6902                	ld	s2,0(sp)
    80003086:	6105                	addi	sp,sp,32
    80003088:	8082                	ret

000000008000308a <sys_exit>:
extern uint64 FREE_PAGES; // kalloc.c keeps track of those
extern struct proc proc[];

uint64
sys_exit(void)
{
    8000308a:	1101                	addi	sp,sp,-32
    8000308c:	ec06                	sd	ra,24(sp)
    8000308e:	e822                	sd	s0,16(sp)
    80003090:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    80003092:	fec40593          	addi	a1,s0,-20
    80003096:	4501                	li	a0,0
    80003098:	00000097          	auipc	ra,0x0
    8000309c:	f0e080e7          	jalr	-242(ra) # 80002fa6 <argint>
    exit(n);
    800030a0:	fec42503          	lw	a0,-20(s0)
    800030a4:	fffff097          	auipc	ra,0xfffff
    800030a8:	464080e7          	jalr	1124(ra) # 80002508 <exit>
    return 0; // not reached
}
    800030ac:	4501                	li	a0,0
    800030ae:	60e2                	ld	ra,24(sp)
    800030b0:	6442                	ld	s0,16(sp)
    800030b2:	6105                	addi	sp,sp,32
    800030b4:	8082                	ret

00000000800030b6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800030b6:	1141                	addi	sp,sp,-16
    800030b8:	e406                	sd	ra,8(sp)
    800030ba:	e022                	sd	s0,0(sp)
    800030bc:	0800                	addi	s0,sp,16
    return myproc()->pid;
    800030be:	fffff097          	auipc	ra,0xfffff
    800030c2:	bae080e7          	jalr	-1106(ra) # 80001c6c <myproc>
}
    800030c6:	5908                	lw	a0,48(a0)
    800030c8:	60a2                	ld	ra,8(sp)
    800030ca:	6402                	ld	s0,0(sp)
    800030cc:	0141                	addi	sp,sp,16
    800030ce:	8082                	ret

00000000800030d0 <sys_fork>:

uint64
sys_fork(void)
{
    800030d0:	1141                	addi	sp,sp,-16
    800030d2:	e406                	sd	ra,8(sp)
    800030d4:	e022                	sd	s0,0(sp)
    800030d6:	0800                	addi	s0,sp,16
    return fork();
    800030d8:	fffff097          	auipc	ra,0xfffff
    800030dc:	09a080e7          	jalr	154(ra) # 80002172 <fork>
}
    800030e0:	60a2                	ld	ra,8(sp)
    800030e2:	6402                	ld	s0,0(sp)
    800030e4:	0141                	addi	sp,sp,16
    800030e6:	8082                	ret

00000000800030e8 <sys_wait>:

uint64
sys_wait(void)
{
    800030e8:	1101                	addi	sp,sp,-32
    800030ea:	ec06                	sd	ra,24(sp)
    800030ec:	e822                	sd	s0,16(sp)
    800030ee:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    800030f0:	fe840593          	addi	a1,s0,-24
    800030f4:	4501                	li	a0,0
    800030f6:	00000097          	auipc	ra,0x0
    800030fa:	ed0080e7          	jalr	-304(ra) # 80002fc6 <argaddr>
    return wait(p);
    800030fe:	fe843503          	ld	a0,-24(s0)
    80003102:	fffff097          	auipc	ra,0xfffff
    80003106:	5ac080e7          	jalr	1452(ra) # 800026ae <wait>
}
    8000310a:	60e2                	ld	ra,24(sp)
    8000310c:	6442                	ld	s0,16(sp)
    8000310e:	6105                	addi	sp,sp,32
    80003110:	8082                	ret

0000000080003112 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003112:	7179                	addi	sp,sp,-48
    80003114:	f406                	sd	ra,40(sp)
    80003116:	f022                	sd	s0,32(sp)
    80003118:	ec26                	sd	s1,24(sp)
    8000311a:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    8000311c:	fdc40593          	addi	a1,s0,-36
    80003120:	4501                	li	a0,0
    80003122:	00000097          	auipc	ra,0x0
    80003126:	e84080e7          	jalr	-380(ra) # 80002fa6 <argint>
    addr = myproc()->sz;
    8000312a:	fffff097          	auipc	ra,0xfffff
    8000312e:	b42080e7          	jalr	-1214(ra) # 80001c6c <myproc>
    80003132:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80003134:	fdc42503          	lw	a0,-36(s0)
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	e8e080e7          	jalr	-370(ra) # 80001fc6 <growproc>
    80003140:	00054863          	bltz	a0,80003150 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80003144:	8526                	mv	a0,s1
    80003146:	70a2                	ld	ra,40(sp)
    80003148:	7402                	ld	s0,32(sp)
    8000314a:	64e2                	ld	s1,24(sp)
    8000314c:	6145                	addi	sp,sp,48
    8000314e:	8082                	ret
        return -1;
    80003150:	54fd                	li	s1,-1
    80003152:	bfcd                	j	80003144 <sys_sbrk+0x32>

0000000080003154 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003154:	7139                	addi	sp,sp,-64
    80003156:	fc06                	sd	ra,56(sp)
    80003158:	f822                	sd	s0,48(sp)
    8000315a:	f426                	sd	s1,40(sp)
    8000315c:	f04a                	sd	s2,32(sp)
    8000315e:	ec4e                	sd	s3,24(sp)
    80003160:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    80003162:	fcc40593          	addi	a1,s0,-52
    80003166:	4501                	li	a0,0
    80003168:	00000097          	auipc	ra,0x0
    8000316c:	e3e080e7          	jalr	-450(ra) # 80002fa6 <argint>
    acquire(&tickslock);
    80003170:	00234517          	auipc	a0,0x234
    80003174:	98050513          	addi	a0,a0,-1664 # 80236af0 <tickslock>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	bb6080e7          	jalr	-1098(ra) # 80000d2e <acquire>
    ticks0 = ticks;
    80003180:	00006917          	auipc	s2,0x6
    80003184:	8d092903          	lw	s2,-1840(s2) # 80008a50 <ticks>
    while (ticks - ticks0 < n)
    80003188:	fcc42783          	lw	a5,-52(s0)
    8000318c:	cf9d                	beqz	a5,800031ca <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    8000318e:	00234997          	auipc	s3,0x234
    80003192:	96298993          	addi	s3,s3,-1694 # 80236af0 <tickslock>
    80003196:	00006497          	auipc	s1,0x6
    8000319a:	8ba48493          	addi	s1,s1,-1862 # 80008a50 <ticks>
        if (killed(myproc()))
    8000319e:	fffff097          	auipc	ra,0xfffff
    800031a2:	ace080e7          	jalr	-1330(ra) # 80001c6c <myproc>
    800031a6:	fffff097          	auipc	ra,0xfffff
    800031aa:	4d6080e7          	jalr	1238(ra) # 8000267c <killed>
    800031ae:	ed15                	bnez	a0,800031ea <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    800031b0:	85ce                	mv	a1,s3
    800031b2:	8526                	mv	a0,s1
    800031b4:	fffff097          	auipc	ra,0xfffff
    800031b8:	220080e7          	jalr	544(ra) # 800023d4 <sleep>
    while (ticks - ticks0 < n)
    800031bc:	409c                	lw	a5,0(s1)
    800031be:	412787bb          	subw	a5,a5,s2
    800031c2:	fcc42703          	lw	a4,-52(s0)
    800031c6:	fce7ece3          	bltu	a5,a4,8000319e <sys_sleep+0x4a>
    }
    release(&tickslock);
    800031ca:	00234517          	auipc	a0,0x234
    800031ce:	92650513          	addi	a0,a0,-1754 # 80236af0 <tickslock>
    800031d2:	ffffe097          	auipc	ra,0xffffe
    800031d6:	c10080e7          	jalr	-1008(ra) # 80000de2 <release>
    return 0;
    800031da:	4501                	li	a0,0
}
    800031dc:	70e2                	ld	ra,56(sp)
    800031de:	7442                	ld	s0,48(sp)
    800031e0:	74a2                	ld	s1,40(sp)
    800031e2:	7902                	ld	s2,32(sp)
    800031e4:	69e2                	ld	s3,24(sp)
    800031e6:	6121                	addi	sp,sp,64
    800031e8:	8082                	ret
            release(&tickslock);
    800031ea:	00234517          	auipc	a0,0x234
    800031ee:	90650513          	addi	a0,a0,-1786 # 80236af0 <tickslock>
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	bf0080e7          	jalr	-1040(ra) # 80000de2 <release>
            return -1;
    800031fa:	557d                	li	a0,-1
    800031fc:	b7c5                	j	800031dc <sys_sleep+0x88>

00000000800031fe <sys_kill>:

uint64
sys_kill(void)
{
    800031fe:	1101                	addi	sp,sp,-32
    80003200:	ec06                	sd	ra,24(sp)
    80003202:	e822                	sd	s0,16(sp)
    80003204:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80003206:	fec40593          	addi	a1,s0,-20
    8000320a:	4501                	li	a0,0
    8000320c:	00000097          	auipc	ra,0x0
    80003210:	d9a080e7          	jalr	-614(ra) # 80002fa6 <argint>
    return kill(pid);
    80003214:	fec42503          	lw	a0,-20(s0)
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	3c6080e7          	jalr	966(ra) # 800025de <kill>
}
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	6105                	addi	sp,sp,32
    80003226:	8082                	ret

0000000080003228 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003228:	1101                	addi	sp,sp,-32
    8000322a:	ec06                	sd	ra,24(sp)
    8000322c:	e822                	sd	s0,16(sp)
    8000322e:	e426                	sd	s1,8(sp)
    80003230:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    80003232:	00234517          	auipc	a0,0x234
    80003236:	8be50513          	addi	a0,a0,-1858 # 80236af0 <tickslock>
    8000323a:	ffffe097          	auipc	ra,0xffffe
    8000323e:	af4080e7          	jalr	-1292(ra) # 80000d2e <acquire>
    xticks = ticks;
    80003242:	00006497          	auipc	s1,0x6
    80003246:	80e4a483          	lw	s1,-2034(s1) # 80008a50 <ticks>
    release(&tickslock);
    8000324a:	00234517          	auipc	a0,0x234
    8000324e:	8a650513          	addi	a0,a0,-1882 # 80236af0 <tickslock>
    80003252:	ffffe097          	auipc	ra,0xffffe
    80003256:	b90080e7          	jalr	-1136(ra) # 80000de2 <release>
    return xticks;
}
    8000325a:	02049513          	slli	a0,s1,0x20
    8000325e:	9101                	srli	a0,a0,0x20
    80003260:	60e2                	ld	ra,24(sp)
    80003262:	6442                	ld	s0,16(sp)
    80003264:	64a2                	ld	s1,8(sp)
    80003266:	6105                	addi	sp,sp,32
    80003268:	8082                	ret

000000008000326a <sys_ps>:

void *
sys_ps(void)
{
    8000326a:	1101                	addi	sp,sp,-32
    8000326c:	ec06                	sd	ra,24(sp)
    8000326e:	e822                	sd	s0,16(sp)
    80003270:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    80003272:	fe042623          	sw	zero,-20(s0)
    80003276:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    8000327a:	fec40593          	addi	a1,s0,-20
    8000327e:	4501                	li	a0,0
    80003280:	00000097          	auipc	ra,0x0
    80003284:	d26080e7          	jalr	-730(ra) # 80002fa6 <argint>
    argint(1, &count);
    80003288:	fe840593          	addi	a1,s0,-24
    8000328c:	4505                	li	a0,1
    8000328e:	00000097          	auipc	ra,0x0
    80003292:	d18080e7          	jalr	-744(ra) # 80002fa6 <argint>
    return ps((uint8)start, (uint8)count);
    80003296:	fe844583          	lbu	a1,-24(s0)
    8000329a:	fec44503          	lbu	a0,-20(s0)
    8000329e:	fffff097          	auipc	ra,0xfffff
    800032a2:	d84080e7          	jalr	-636(ra) # 80002022 <ps>
}
    800032a6:	60e2                	ld	ra,24(sp)
    800032a8:	6442                	ld	s0,16(sp)
    800032aa:	6105                	addi	sp,sp,32
    800032ac:	8082                	ret

00000000800032ae <sys_schedls>:

uint64 sys_schedls(void)
{
    800032ae:	1141                	addi	sp,sp,-16
    800032b0:	e406                	sd	ra,8(sp)
    800032b2:	e022                	sd	s0,0(sp)
    800032b4:	0800                	addi	s0,sp,16
    schedls();
    800032b6:	fffff097          	auipc	ra,0xfffff
    800032ba:	682080e7          	jalr	1666(ra) # 80002938 <schedls>
    return 0;
}
    800032be:	4501                	li	a0,0
    800032c0:	60a2                	ld	ra,8(sp)
    800032c2:	6402                	ld	s0,0(sp)
    800032c4:	0141                	addi	sp,sp,16
    800032c6:	8082                	ret

00000000800032c8 <sys_schedset>:

uint64 sys_schedset(void)
{
    800032c8:	1101                	addi	sp,sp,-32
    800032ca:	ec06                	sd	ra,24(sp)
    800032cc:	e822                	sd	s0,16(sp)
    800032ce:	1000                	addi	s0,sp,32
    int id = 0;
    800032d0:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    800032d4:	fec40593          	addi	a1,s0,-20
    800032d8:	4501                	li	a0,0
    800032da:	00000097          	auipc	ra,0x0
    800032de:	ccc080e7          	jalr	-820(ra) # 80002fa6 <argint>
    schedset(id - 1);
    800032e2:	fec42503          	lw	a0,-20(s0)
    800032e6:	357d                	addiw	a0,a0,-1
    800032e8:	fffff097          	auipc	ra,0xfffff
    800032ec:	6e6080e7          	jalr	1766(ra) # 800029ce <schedset>
    return 0;
}
    800032f0:	4501                	li	a0,0
    800032f2:	60e2                	ld	ra,24(sp)
    800032f4:	6442                	ld	s0,16(sp)
    800032f6:	6105                	addi	sp,sp,32
    800032f8:	8082                	ret

00000000800032fa <sys_va2pa>:

uint64 sys_va2pa(uint64 addr, int pid)
{
    800032fa:	1101                	addi	sp,sp,-32
    800032fc:	ec06                	sd	ra,24(sp)
    800032fe:	e822                	sd	s0,16(sp)
    80003300:	1000                	addi	s0,sp,32
    80003302:	fea43423          	sd	a0,-24(s0)
    80003306:	feb42223          	sw	a1,-28(s0)
    struct proc *p1;
    // Retrieve virtual address argument
    argaddr(0, &addr);
    8000330a:	fe840593          	addi	a1,s0,-24
    8000330e:	4501                	li	a0,0
    80003310:	00000097          	auipc	ra,0x0
    80003314:	cb6080e7          	jalr	-842(ra) # 80002fc6 <argaddr>

    // Retrieve optional process ID argument
    argint(1, &pid);
    80003318:	fe440593          	addi	a1,s0,-28
    8000331c:	4505                	li	a0,1
    8000331e:	00000097          	auipc	ra,0x0
    80003322:	c88080e7          	jalr	-888(ra) # 80002fa6 <argint>

    if (pid == 0)
    80003326:	fe442783          	lw	a5,-28(s0)
    8000332a:	c785                	beqz	a5,80003352 <sys_va2pa+0x58>

    int pidIsValid = 0;
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    {
        if (p->pid == pid)
    8000332c:	fe442503          	lw	a0,-28(s0)
    for (p = proc; p < &proc[NPROC]; p++)
    80003330:	0022e797          	auipc	a5,0x22e
    80003334:	dc078793          	addi	a5,a5,-576 # 802310f0 <proc>
    80003338:	00233697          	auipc	a3,0x233
    8000333c:	7b868693          	addi	a3,a3,1976 # 80236af0 <tickslock>
        if (p->pid == pid)
    80003340:	5b98                	lw	a4,48(a5)
    80003342:	02a70063          	beq	a4,a0,80003362 <sys_va2pa+0x68>
    for (p = proc; p < &proc[NPROC]; p++)
    80003346:	16878793          	addi	a5,a5,360
    8000334a:	fed79be3          	bne	a5,a3,80003340 <sys_va2pa+0x46>
            break;
        }
    }
    if (pidIsValid == 0)
    {
        return 0;
    8000334e:	4501                	li	a0,0
    80003350:	a025                	j	80003378 <sys_va2pa+0x7e>
        pid = myproc()->pid;
    80003352:	fffff097          	auipc	ra,0xfffff
    80003356:	91a080e7          	jalr	-1766(ra) # 80001c6c <myproc>
    8000335a:	591c                	lw	a5,48(a0)
    8000335c:	fef42223          	sw	a5,-28(s0)
    80003360:	b7f1                	j	8000332c <sys_va2pa+0x32>
    }
    p1 = get_proc_by_pid(pid);
    80003362:	fffff097          	auipc	ra,0xfffff
    80003366:	6b8080e7          	jalr	1720(ra) # 80002a1a <get_proc_by_pid>
    uint64 pa = walkaddr(p1->pagetable, addr);
    8000336a:	fe843583          	ld	a1,-24(s0)
    8000336e:	6928                	ld	a0,80(a0)
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	e44080e7          	jalr	-444(ra) # 800011b4 <walkaddr>
    if (pa == 0)
    {
        return 0;
    }
    return pa;
}
    80003378:	60e2                	ld	ra,24(sp)
    8000337a:	6442                	ld	s0,16(sp)
    8000337c:	6105                	addi	sp,sp,32
    8000337e:	8082                	ret

0000000080003380 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    80003380:	1141                	addi	sp,sp,-16
    80003382:	e406                	sd	ra,8(sp)
    80003384:	e022                	sd	s0,0(sp)
    80003386:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    80003388:	00005597          	auipc	a1,0x5
    8000338c:	6a05b583          	ld	a1,1696(a1) # 80008a28 <FREE_PAGES>
    80003390:	00005517          	auipc	a0,0x5
    80003394:	1a850513          	addi	a0,a0,424 # 80008538 <states.0+0x168>
    80003398:	ffffd097          	auipc	ra,0xffffd
    8000339c:	204080e7          	jalr	516(ra) # 8000059c <printf>
    return 0;
    800033a0:	4501                	li	a0,0
    800033a2:	60a2                	ld	ra,8(sp)
    800033a4:	6402                	ld	s0,0(sp)
    800033a6:	0141                	addi	sp,sp,16
    800033a8:	8082                	ret

00000000800033aa <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033aa:	7179                	addi	sp,sp,-48
    800033ac:	f406                	sd	ra,40(sp)
    800033ae:	f022                	sd	s0,32(sp)
    800033b0:	ec26                	sd	s1,24(sp)
    800033b2:	e84a                	sd	s2,16(sp)
    800033b4:	e44e                	sd	s3,8(sp)
    800033b6:	e052                	sd	s4,0(sp)
    800033b8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800033ba:	00005597          	auipc	a1,0x5
    800033be:	27658593          	addi	a1,a1,630 # 80008630 <syscalls+0xd8>
    800033c2:	00233517          	auipc	a0,0x233
    800033c6:	74650513          	addi	a0,a0,1862 # 80236b08 <bcache>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	8d4080e7          	jalr	-1836(ra) # 80000c9e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033d2:	0023b797          	auipc	a5,0x23b
    800033d6:	73678793          	addi	a5,a5,1846 # 8023eb08 <bcache+0x8000>
    800033da:	0023c717          	auipc	a4,0x23c
    800033de:	99670713          	addi	a4,a4,-1642 # 8023ed70 <bcache+0x8268>
    800033e2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033e6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033ea:	00233497          	auipc	s1,0x233
    800033ee:	73648493          	addi	s1,s1,1846 # 80236b20 <bcache+0x18>
    b->next = bcache.head.next;
    800033f2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033f4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033f6:	00005a17          	auipc	s4,0x5
    800033fa:	242a0a13          	addi	s4,s4,578 # 80008638 <syscalls+0xe0>
    b->next = bcache.head.next;
    800033fe:	2b893783          	ld	a5,696(s2)
    80003402:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003404:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003408:	85d2                	mv	a1,s4
    8000340a:	01048513          	addi	a0,s1,16
    8000340e:	00001097          	auipc	ra,0x1
    80003412:	4c8080e7          	jalr	1224(ra) # 800048d6 <initsleeplock>
    bcache.head.next->prev = b;
    80003416:	2b893783          	ld	a5,696(s2)
    8000341a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000341c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003420:	45848493          	addi	s1,s1,1112
    80003424:	fd349de3          	bne	s1,s3,800033fe <binit+0x54>
  }
}
    80003428:	70a2                	ld	ra,40(sp)
    8000342a:	7402                	ld	s0,32(sp)
    8000342c:	64e2                	ld	s1,24(sp)
    8000342e:	6942                	ld	s2,16(sp)
    80003430:	69a2                	ld	s3,8(sp)
    80003432:	6a02                	ld	s4,0(sp)
    80003434:	6145                	addi	sp,sp,48
    80003436:	8082                	ret

0000000080003438 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003438:	7179                	addi	sp,sp,-48
    8000343a:	f406                	sd	ra,40(sp)
    8000343c:	f022                	sd	s0,32(sp)
    8000343e:	ec26                	sd	s1,24(sp)
    80003440:	e84a                	sd	s2,16(sp)
    80003442:	e44e                	sd	s3,8(sp)
    80003444:	1800                	addi	s0,sp,48
    80003446:	892a                	mv	s2,a0
    80003448:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000344a:	00233517          	auipc	a0,0x233
    8000344e:	6be50513          	addi	a0,a0,1726 # 80236b08 <bcache>
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	8dc080e7          	jalr	-1828(ra) # 80000d2e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000345a:	0023c497          	auipc	s1,0x23c
    8000345e:	9664b483          	ld	s1,-1690(s1) # 8023edc0 <bcache+0x82b8>
    80003462:	0023c797          	auipc	a5,0x23c
    80003466:	90e78793          	addi	a5,a5,-1778 # 8023ed70 <bcache+0x8268>
    8000346a:	02f48f63          	beq	s1,a5,800034a8 <bread+0x70>
    8000346e:	873e                	mv	a4,a5
    80003470:	a021                	j	80003478 <bread+0x40>
    80003472:	68a4                	ld	s1,80(s1)
    80003474:	02e48a63          	beq	s1,a4,800034a8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003478:	449c                	lw	a5,8(s1)
    8000347a:	ff279ce3          	bne	a5,s2,80003472 <bread+0x3a>
    8000347e:	44dc                	lw	a5,12(s1)
    80003480:	ff3799e3          	bne	a5,s3,80003472 <bread+0x3a>
      b->refcnt++;
    80003484:	40bc                	lw	a5,64(s1)
    80003486:	2785                	addiw	a5,a5,1
    80003488:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000348a:	00233517          	auipc	a0,0x233
    8000348e:	67e50513          	addi	a0,a0,1662 # 80236b08 <bcache>
    80003492:	ffffe097          	auipc	ra,0xffffe
    80003496:	950080e7          	jalr	-1712(ra) # 80000de2 <release>
      acquiresleep(&b->lock);
    8000349a:	01048513          	addi	a0,s1,16
    8000349e:	00001097          	auipc	ra,0x1
    800034a2:	472080e7          	jalr	1138(ra) # 80004910 <acquiresleep>
      return b;
    800034a6:	a8b9                	j	80003504 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034a8:	0023c497          	auipc	s1,0x23c
    800034ac:	9104b483          	ld	s1,-1776(s1) # 8023edb8 <bcache+0x82b0>
    800034b0:	0023c797          	auipc	a5,0x23c
    800034b4:	8c078793          	addi	a5,a5,-1856 # 8023ed70 <bcache+0x8268>
    800034b8:	00f48863          	beq	s1,a5,800034c8 <bread+0x90>
    800034bc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800034be:	40bc                	lw	a5,64(s1)
    800034c0:	cf81                	beqz	a5,800034d8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034c2:	64a4                	ld	s1,72(s1)
    800034c4:	fee49de3          	bne	s1,a4,800034be <bread+0x86>
  panic("bget: no buffers");
    800034c8:	00005517          	auipc	a0,0x5
    800034cc:	17850513          	addi	a0,a0,376 # 80008640 <syscalls+0xe8>
    800034d0:	ffffd097          	auipc	ra,0xffffd
    800034d4:	070080e7          	jalr	112(ra) # 80000540 <panic>
      b->dev = dev;
    800034d8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034dc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034e0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034e4:	4785                	li	a5,1
    800034e6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034e8:	00233517          	auipc	a0,0x233
    800034ec:	62050513          	addi	a0,a0,1568 # 80236b08 <bcache>
    800034f0:	ffffe097          	auipc	ra,0xffffe
    800034f4:	8f2080e7          	jalr	-1806(ra) # 80000de2 <release>
      acquiresleep(&b->lock);
    800034f8:	01048513          	addi	a0,s1,16
    800034fc:	00001097          	auipc	ra,0x1
    80003500:	414080e7          	jalr	1044(ra) # 80004910 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003504:	409c                	lw	a5,0(s1)
    80003506:	cb89                	beqz	a5,80003518 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003508:	8526                	mv	a0,s1
    8000350a:	70a2                	ld	ra,40(sp)
    8000350c:	7402                	ld	s0,32(sp)
    8000350e:	64e2                	ld	s1,24(sp)
    80003510:	6942                	ld	s2,16(sp)
    80003512:	69a2                	ld	s3,8(sp)
    80003514:	6145                	addi	sp,sp,48
    80003516:	8082                	ret
    virtio_disk_rw(b, 0);
    80003518:	4581                	li	a1,0
    8000351a:	8526                	mv	a0,s1
    8000351c:	00003097          	auipc	ra,0x3
    80003520:	fd6080e7          	jalr	-42(ra) # 800064f2 <virtio_disk_rw>
    b->valid = 1;
    80003524:	4785                	li	a5,1
    80003526:	c09c                	sw	a5,0(s1)
  return b;
    80003528:	b7c5                	j	80003508 <bread+0xd0>

000000008000352a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000352a:	1101                	addi	sp,sp,-32
    8000352c:	ec06                	sd	ra,24(sp)
    8000352e:	e822                	sd	s0,16(sp)
    80003530:	e426                	sd	s1,8(sp)
    80003532:	1000                	addi	s0,sp,32
    80003534:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003536:	0541                	addi	a0,a0,16
    80003538:	00001097          	auipc	ra,0x1
    8000353c:	472080e7          	jalr	1138(ra) # 800049aa <holdingsleep>
    80003540:	cd01                	beqz	a0,80003558 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003542:	4585                	li	a1,1
    80003544:	8526                	mv	a0,s1
    80003546:	00003097          	auipc	ra,0x3
    8000354a:	fac080e7          	jalr	-84(ra) # 800064f2 <virtio_disk_rw>
}
    8000354e:	60e2                	ld	ra,24(sp)
    80003550:	6442                	ld	s0,16(sp)
    80003552:	64a2                	ld	s1,8(sp)
    80003554:	6105                	addi	sp,sp,32
    80003556:	8082                	ret
    panic("bwrite");
    80003558:	00005517          	auipc	a0,0x5
    8000355c:	10050513          	addi	a0,a0,256 # 80008658 <syscalls+0x100>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	fe0080e7          	jalr	-32(ra) # 80000540 <panic>

0000000080003568 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003568:	1101                	addi	sp,sp,-32
    8000356a:	ec06                	sd	ra,24(sp)
    8000356c:	e822                	sd	s0,16(sp)
    8000356e:	e426                	sd	s1,8(sp)
    80003570:	e04a                	sd	s2,0(sp)
    80003572:	1000                	addi	s0,sp,32
    80003574:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003576:	01050913          	addi	s2,a0,16
    8000357a:	854a                	mv	a0,s2
    8000357c:	00001097          	auipc	ra,0x1
    80003580:	42e080e7          	jalr	1070(ra) # 800049aa <holdingsleep>
    80003584:	c92d                	beqz	a0,800035f6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003586:	854a                	mv	a0,s2
    80003588:	00001097          	auipc	ra,0x1
    8000358c:	3de080e7          	jalr	990(ra) # 80004966 <releasesleep>

  acquire(&bcache.lock);
    80003590:	00233517          	auipc	a0,0x233
    80003594:	57850513          	addi	a0,a0,1400 # 80236b08 <bcache>
    80003598:	ffffd097          	auipc	ra,0xffffd
    8000359c:	796080e7          	jalr	1942(ra) # 80000d2e <acquire>
  b->refcnt--;
    800035a0:	40bc                	lw	a5,64(s1)
    800035a2:	37fd                	addiw	a5,a5,-1
    800035a4:	0007871b          	sext.w	a4,a5
    800035a8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035aa:	eb05                	bnez	a4,800035da <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035ac:	68bc                	ld	a5,80(s1)
    800035ae:	64b8                	ld	a4,72(s1)
    800035b0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800035b2:	64bc                	ld	a5,72(s1)
    800035b4:	68b8                	ld	a4,80(s1)
    800035b6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800035b8:	0023b797          	auipc	a5,0x23b
    800035bc:	55078793          	addi	a5,a5,1360 # 8023eb08 <bcache+0x8000>
    800035c0:	2b87b703          	ld	a4,696(a5)
    800035c4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035c6:	0023b717          	auipc	a4,0x23b
    800035ca:	7aa70713          	addi	a4,a4,1962 # 8023ed70 <bcache+0x8268>
    800035ce:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035d0:	2b87b703          	ld	a4,696(a5)
    800035d4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035d6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035da:	00233517          	auipc	a0,0x233
    800035de:	52e50513          	addi	a0,a0,1326 # 80236b08 <bcache>
    800035e2:	ffffe097          	auipc	ra,0xffffe
    800035e6:	800080e7          	jalr	-2048(ra) # 80000de2 <release>
}
    800035ea:	60e2                	ld	ra,24(sp)
    800035ec:	6442                	ld	s0,16(sp)
    800035ee:	64a2                	ld	s1,8(sp)
    800035f0:	6902                	ld	s2,0(sp)
    800035f2:	6105                	addi	sp,sp,32
    800035f4:	8082                	ret
    panic("brelse");
    800035f6:	00005517          	auipc	a0,0x5
    800035fa:	06a50513          	addi	a0,a0,106 # 80008660 <syscalls+0x108>
    800035fe:	ffffd097          	auipc	ra,0xffffd
    80003602:	f42080e7          	jalr	-190(ra) # 80000540 <panic>

0000000080003606 <bpin>:

void
bpin(struct buf *b) {
    80003606:	1101                	addi	sp,sp,-32
    80003608:	ec06                	sd	ra,24(sp)
    8000360a:	e822                	sd	s0,16(sp)
    8000360c:	e426                	sd	s1,8(sp)
    8000360e:	1000                	addi	s0,sp,32
    80003610:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003612:	00233517          	auipc	a0,0x233
    80003616:	4f650513          	addi	a0,a0,1270 # 80236b08 <bcache>
    8000361a:	ffffd097          	auipc	ra,0xffffd
    8000361e:	714080e7          	jalr	1812(ra) # 80000d2e <acquire>
  b->refcnt++;
    80003622:	40bc                	lw	a5,64(s1)
    80003624:	2785                	addiw	a5,a5,1
    80003626:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003628:	00233517          	auipc	a0,0x233
    8000362c:	4e050513          	addi	a0,a0,1248 # 80236b08 <bcache>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	7b2080e7          	jalr	1970(ra) # 80000de2 <release>
}
    80003638:	60e2                	ld	ra,24(sp)
    8000363a:	6442                	ld	s0,16(sp)
    8000363c:	64a2                	ld	s1,8(sp)
    8000363e:	6105                	addi	sp,sp,32
    80003640:	8082                	ret

0000000080003642 <bunpin>:

void
bunpin(struct buf *b) {
    80003642:	1101                	addi	sp,sp,-32
    80003644:	ec06                	sd	ra,24(sp)
    80003646:	e822                	sd	s0,16(sp)
    80003648:	e426                	sd	s1,8(sp)
    8000364a:	1000                	addi	s0,sp,32
    8000364c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000364e:	00233517          	auipc	a0,0x233
    80003652:	4ba50513          	addi	a0,a0,1210 # 80236b08 <bcache>
    80003656:	ffffd097          	auipc	ra,0xffffd
    8000365a:	6d8080e7          	jalr	1752(ra) # 80000d2e <acquire>
  b->refcnt--;
    8000365e:	40bc                	lw	a5,64(s1)
    80003660:	37fd                	addiw	a5,a5,-1
    80003662:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003664:	00233517          	auipc	a0,0x233
    80003668:	4a450513          	addi	a0,a0,1188 # 80236b08 <bcache>
    8000366c:	ffffd097          	auipc	ra,0xffffd
    80003670:	776080e7          	jalr	1910(ra) # 80000de2 <release>
}
    80003674:	60e2                	ld	ra,24(sp)
    80003676:	6442                	ld	s0,16(sp)
    80003678:	64a2                	ld	s1,8(sp)
    8000367a:	6105                	addi	sp,sp,32
    8000367c:	8082                	ret

000000008000367e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000367e:	1101                	addi	sp,sp,-32
    80003680:	ec06                	sd	ra,24(sp)
    80003682:	e822                	sd	s0,16(sp)
    80003684:	e426                	sd	s1,8(sp)
    80003686:	e04a                	sd	s2,0(sp)
    80003688:	1000                	addi	s0,sp,32
    8000368a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000368c:	00d5d59b          	srliw	a1,a1,0xd
    80003690:	0023c797          	auipc	a5,0x23c
    80003694:	b547a783          	lw	a5,-1196(a5) # 8023f1e4 <sb+0x1c>
    80003698:	9dbd                	addw	a1,a1,a5
    8000369a:	00000097          	auipc	ra,0x0
    8000369e:	d9e080e7          	jalr	-610(ra) # 80003438 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036a2:	0074f713          	andi	a4,s1,7
    800036a6:	4785                	li	a5,1
    800036a8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036ac:	14ce                	slli	s1,s1,0x33
    800036ae:	90d9                	srli	s1,s1,0x36
    800036b0:	00950733          	add	a4,a0,s1
    800036b4:	05874703          	lbu	a4,88(a4)
    800036b8:	00e7f6b3          	and	a3,a5,a4
    800036bc:	c69d                	beqz	a3,800036ea <bfree+0x6c>
    800036be:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800036c0:	94aa                	add	s1,s1,a0
    800036c2:	fff7c793          	not	a5,a5
    800036c6:	8f7d                	and	a4,a4,a5
    800036c8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800036cc:	00001097          	auipc	ra,0x1
    800036d0:	126080e7          	jalr	294(ra) # 800047f2 <log_write>
  brelse(bp);
    800036d4:	854a                	mv	a0,s2
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	e92080e7          	jalr	-366(ra) # 80003568 <brelse>
}
    800036de:	60e2                	ld	ra,24(sp)
    800036e0:	6442                	ld	s0,16(sp)
    800036e2:	64a2                	ld	s1,8(sp)
    800036e4:	6902                	ld	s2,0(sp)
    800036e6:	6105                	addi	sp,sp,32
    800036e8:	8082                	ret
    panic("freeing free block");
    800036ea:	00005517          	auipc	a0,0x5
    800036ee:	f7e50513          	addi	a0,a0,-130 # 80008668 <syscalls+0x110>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	e4e080e7          	jalr	-434(ra) # 80000540 <panic>

00000000800036fa <balloc>:
{
    800036fa:	711d                	addi	sp,sp,-96
    800036fc:	ec86                	sd	ra,88(sp)
    800036fe:	e8a2                	sd	s0,80(sp)
    80003700:	e4a6                	sd	s1,72(sp)
    80003702:	e0ca                	sd	s2,64(sp)
    80003704:	fc4e                	sd	s3,56(sp)
    80003706:	f852                	sd	s4,48(sp)
    80003708:	f456                	sd	s5,40(sp)
    8000370a:	f05a                	sd	s6,32(sp)
    8000370c:	ec5e                	sd	s7,24(sp)
    8000370e:	e862                	sd	s8,16(sp)
    80003710:	e466                	sd	s9,8(sp)
    80003712:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003714:	0023c797          	auipc	a5,0x23c
    80003718:	ab87a783          	lw	a5,-1352(a5) # 8023f1cc <sb+0x4>
    8000371c:	cff5                	beqz	a5,80003818 <balloc+0x11e>
    8000371e:	8baa                	mv	s7,a0
    80003720:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003722:	0023cb17          	auipc	s6,0x23c
    80003726:	aa6b0b13          	addi	s6,s6,-1370 # 8023f1c8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000372a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000372c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000372e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003730:	6c89                	lui	s9,0x2
    80003732:	a061                	j	800037ba <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003734:	97ca                	add	a5,a5,s2
    80003736:	8e55                	or	a2,a2,a3
    80003738:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000373c:	854a                	mv	a0,s2
    8000373e:	00001097          	auipc	ra,0x1
    80003742:	0b4080e7          	jalr	180(ra) # 800047f2 <log_write>
        brelse(bp);
    80003746:	854a                	mv	a0,s2
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	e20080e7          	jalr	-480(ra) # 80003568 <brelse>
  bp = bread(dev, bno);
    80003750:	85a6                	mv	a1,s1
    80003752:	855e                	mv	a0,s7
    80003754:	00000097          	auipc	ra,0x0
    80003758:	ce4080e7          	jalr	-796(ra) # 80003438 <bread>
    8000375c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000375e:	40000613          	li	a2,1024
    80003762:	4581                	li	a1,0
    80003764:	05850513          	addi	a0,a0,88
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	6c2080e7          	jalr	1730(ra) # 80000e2a <memset>
  log_write(bp);
    80003770:	854a                	mv	a0,s2
    80003772:	00001097          	auipc	ra,0x1
    80003776:	080080e7          	jalr	128(ra) # 800047f2 <log_write>
  brelse(bp);
    8000377a:	854a                	mv	a0,s2
    8000377c:	00000097          	auipc	ra,0x0
    80003780:	dec080e7          	jalr	-532(ra) # 80003568 <brelse>
}
    80003784:	8526                	mv	a0,s1
    80003786:	60e6                	ld	ra,88(sp)
    80003788:	6446                	ld	s0,80(sp)
    8000378a:	64a6                	ld	s1,72(sp)
    8000378c:	6906                	ld	s2,64(sp)
    8000378e:	79e2                	ld	s3,56(sp)
    80003790:	7a42                	ld	s4,48(sp)
    80003792:	7aa2                	ld	s5,40(sp)
    80003794:	7b02                	ld	s6,32(sp)
    80003796:	6be2                	ld	s7,24(sp)
    80003798:	6c42                	ld	s8,16(sp)
    8000379a:	6ca2                	ld	s9,8(sp)
    8000379c:	6125                	addi	sp,sp,96
    8000379e:	8082                	ret
    brelse(bp);
    800037a0:	854a                	mv	a0,s2
    800037a2:	00000097          	auipc	ra,0x0
    800037a6:	dc6080e7          	jalr	-570(ra) # 80003568 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037aa:	015c87bb          	addw	a5,s9,s5
    800037ae:	00078a9b          	sext.w	s5,a5
    800037b2:	004b2703          	lw	a4,4(s6)
    800037b6:	06eaf163          	bgeu	s5,a4,80003818 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800037ba:	41fad79b          	sraiw	a5,s5,0x1f
    800037be:	0137d79b          	srliw	a5,a5,0x13
    800037c2:	015787bb          	addw	a5,a5,s5
    800037c6:	40d7d79b          	sraiw	a5,a5,0xd
    800037ca:	01cb2583          	lw	a1,28(s6)
    800037ce:	9dbd                	addw	a1,a1,a5
    800037d0:	855e                	mv	a0,s7
    800037d2:	00000097          	auipc	ra,0x0
    800037d6:	c66080e7          	jalr	-922(ra) # 80003438 <bread>
    800037da:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037dc:	004b2503          	lw	a0,4(s6)
    800037e0:	000a849b          	sext.w	s1,s5
    800037e4:	8762                	mv	a4,s8
    800037e6:	faa4fde3          	bgeu	s1,a0,800037a0 <balloc+0xa6>
      m = 1 << (bi % 8);
    800037ea:	00777693          	andi	a3,a4,7
    800037ee:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037f2:	41f7579b          	sraiw	a5,a4,0x1f
    800037f6:	01d7d79b          	srliw	a5,a5,0x1d
    800037fa:	9fb9                	addw	a5,a5,a4
    800037fc:	4037d79b          	sraiw	a5,a5,0x3
    80003800:	00f90633          	add	a2,s2,a5
    80003804:	05864603          	lbu	a2,88(a2)
    80003808:	00c6f5b3          	and	a1,a3,a2
    8000380c:	d585                	beqz	a1,80003734 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000380e:	2705                	addiw	a4,a4,1
    80003810:	2485                	addiw	s1,s1,1
    80003812:	fd471ae3          	bne	a4,s4,800037e6 <balloc+0xec>
    80003816:	b769                	j	800037a0 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003818:	00005517          	auipc	a0,0x5
    8000381c:	e6850513          	addi	a0,a0,-408 # 80008680 <syscalls+0x128>
    80003820:	ffffd097          	auipc	ra,0xffffd
    80003824:	d7c080e7          	jalr	-644(ra) # 8000059c <printf>
  return 0;
    80003828:	4481                	li	s1,0
    8000382a:	bfa9                	j	80003784 <balloc+0x8a>

000000008000382c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000382c:	7179                	addi	sp,sp,-48
    8000382e:	f406                	sd	ra,40(sp)
    80003830:	f022                	sd	s0,32(sp)
    80003832:	ec26                	sd	s1,24(sp)
    80003834:	e84a                	sd	s2,16(sp)
    80003836:	e44e                	sd	s3,8(sp)
    80003838:	e052                	sd	s4,0(sp)
    8000383a:	1800                	addi	s0,sp,48
    8000383c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000383e:	47ad                	li	a5,11
    80003840:	02b7e863          	bltu	a5,a1,80003870 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003844:	02059793          	slli	a5,a1,0x20
    80003848:	01e7d593          	srli	a1,a5,0x1e
    8000384c:	00b504b3          	add	s1,a0,a1
    80003850:	0504a903          	lw	s2,80(s1)
    80003854:	06091e63          	bnez	s2,800038d0 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003858:	4108                	lw	a0,0(a0)
    8000385a:	00000097          	auipc	ra,0x0
    8000385e:	ea0080e7          	jalr	-352(ra) # 800036fa <balloc>
    80003862:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003866:	06090563          	beqz	s2,800038d0 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000386a:	0524a823          	sw	s2,80(s1)
    8000386e:	a08d                	j	800038d0 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003870:	ff45849b          	addiw	s1,a1,-12
    80003874:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003878:	0ff00793          	li	a5,255
    8000387c:	08e7e563          	bltu	a5,a4,80003906 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003880:	08052903          	lw	s2,128(a0)
    80003884:	00091d63          	bnez	s2,8000389e <bmap+0x72>
      addr = balloc(ip->dev);
    80003888:	4108                	lw	a0,0(a0)
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	e70080e7          	jalr	-400(ra) # 800036fa <balloc>
    80003892:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003896:	02090d63          	beqz	s2,800038d0 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000389a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000389e:	85ca                	mv	a1,s2
    800038a0:	0009a503          	lw	a0,0(s3)
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	b94080e7          	jalr	-1132(ra) # 80003438 <bread>
    800038ac:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038ae:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038b2:	02049713          	slli	a4,s1,0x20
    800038b6:	01e75593          	srli	a1,a4,0x1e
    800038ba:	00b784b3          	add	s1,a5,a1
    800038be:	0004a903          	lw	s2,0(s1)
    800038c2:	02090063          	beqz	s2,800038e2 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800038c6:	8552                	mv	a0,s4
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	ca0080e7          	jalr	-864(ra) # 80003568 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800038d0:	854a                	mv	a0,s2
    800038d2:	70a2                	ld	ra,40(sp)
    800038d4:	7402                	ld	s0,32(sp)
    800038d6:	64e2                	ld	s1,24(sp)
    800038d8:	6942                	ld	s2,16(sp)
    800038da:	69a2                	ld	s3,8(sp)
    800038dc:	6a02                	ld	s4,0(sp)
    800038de:	6145                	addi	sp,sp,48
    800038e0:	8082                	ret
      addr = balloc(ip->dev);
    800038e2:	0009a503          	lw	a0,0(s3)
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	e14080e7          	jalr	-492(ra) # 800036fa <balloc>
    800038ee:	0005091b          	sext.w	s2,a0
      if(addr){
    800038f2:	fc090ae3          	beqz	s2,800038c6 <bmap+0x9a>
        a[bn] = addr;
    800038f6:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800038fa:	8552                	mv	a0,s4
    800038fc:	00001097          	auipc	ra,0x1
    80003900:	ef6080e7          	jalr	-266(ra) # 800047f2 <log_write>
    80003904:	b7c9                	j	800038c6 <bmap+0x9a>
  panic("bmap: out of range");
    80003906:	00005517          	auipc	a0,0x5
    8000390a:	d9250513          	addi	a0,a0,-622 # 80008698 <syscalls+0x140>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	c32080e7          	jalr	-974(ra) # 80000540 <panic>

0000000080003916 <iget>:
{
    80003916:	7179                	addi	sp,sp,-48
    80003918:	f406                	sd	ra,40(sp)
    8000391a:	f022                	sd	s0,32(sp)
    8000391c:	ec26                	sd	s1,24(sp)
    8000391e:	e84a                	sd	s2,16(sp)
    80003920:	e44e                	sd	s3,8(sp)
    80003922:	e052                	sd	s4,0(sp)
    80003924:	1800                	addi	s0,sp,48
    80003926:	89aa                	mv	s3,a0
    80003928:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000392a:	0023c517          	auipc	a0,0x23c
    8000392e:	8be50513          	addi	a0,a0,-1858 # 8023f1e8 <itable>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	3fc080e7          	jalr	1020(ra) # 80000d2e <acquire>
  empty = 0;
    8000393a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000393c:	0023c497          	auipc	s1,0x23c
    80003940:	8c448493          	addi	s1,s1,-1852 # 8023f200 <itable+0x18>
    80003944:	0023d697          	auipc	a3,0x23d
    80003948:	34c68693          	addi	a3,a3,844 # 80240c90 <log>
    8000394c:	a039                	j	8000395a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000394e:	02090b63          	beqz	s2,80003984 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003952:	08848493          	addi	s1,s1,136
    80003956:	02d48a63          	beq	s1,a3,8000398a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000395a:	449c                	lw	a5,8(s1)
    8000395c:	fef059e3          	blez	a5,8000394e <iget+0x38>
    80003960:	4098                	lw	a4,0(s1)
    80003962:	ff3716e3          	bne	a4,s3,8000394e <iget+0x38>
    80003966:	40d8                	lw	a4,4(s1)
    80003968:	ff4713e3          	bne	a4,s4,8000394e <iget+0x38>
      ip->ref++;
    8000396c:	2785                	addiw	a5,a5,1
    8000396e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003970:	0023c517          	auipc	a0,0x23c
    80003974:	87850513          	addi	a0,a0,-1928 # 8023f1e8 <itable>
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	46a080e7          	jalr	1130(ra) # 80000de2 <release>
      return ip;
    80003980:	8926                	mv	s2,s1
    80003982:	a03d                	j	800039b0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003984:	f7f9                	bnez	a5,80003952 <iget+0x3c>
    80003986:	8926                	mv	s2,s1
    80003988:	b7e9                	j	80003952 <iget+0x3c>
  if(empty == 0)
    8000398a:	02090c63          	beqz	s2,800039c2 <iget+0xac>
  ip->dev = dev;
    8000398e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003992:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003996:	4785                	li	a5,1
    80003998:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000399c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039a0:	0023c517          	auipc	a0,0x23c
    800039a4:	84850513          	addi	a0,a0,-1976 # 8023f1e8 <itable>
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	43a080e7          	jalr	1082(ra) # 80000de2 <release>
}
    800039b0:	854a                	mv	a0,s2
    800039b2:	70a2                	ld	ra,40(sp)
    800039b4:	7402                	ld	s0,32(sp)
    800039b6:	64e2                	ld	s1,24(sp)
    800039b8:	6942                	ld	s2,16(sp)
    800039ba:	69a2                	ld	s3,8(sp)
    800039bc:	6a02                	ld	s4,0(sp)
    800039be:	6145                	addi	sp,sp,48
    800039c0:	8082                	ret
    panic("iget: no inodes");
    800039c2:	00005517          	auipc	a0,0x5
    800039c6:	cee50513          	addi	a0,a0,-786 # 800086b0 <syscalls+0x158>
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	b76080e7          	jalr	-1162(ra) # 80000540 <panic>

00000000800039d2 <fsinit>:
fsinit(int dev) {
    800039d2:	7179                	addi	sp,sp,-48
    800039d4:	f406                	sd	ra,40(sp)
    800039d6:	f022                	sd	s0,32(sp)
    800039d8:	ec26                	sd	s1,24(sp)
    800039da:	e84a                	sd	s2,16(sp)
    800039dc:	e44e                	sd	s3,8(sp)
    800039de:	1800                	addi	s0,sp,48
    800039e0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039e2:	4585                	li	a1,1
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	a54080e7          	jalr	-1452(ra) # 80003438 <bread>
    800039ec:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039ee:	0023b997          	auipc	s3,0x23b
    800039f2:	7da98993          	addi	s3,s3,2010 # 8023f1c8 <sb>
    800039f6:	02000613          	li	a2,32
    800039fa:	05850593          	addi	a1,a0,88
    800039fe:	854e                	mv	a0,s3
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	486080e7          	jalr	1158(ra) # 80000e86 <memmove>
  brelse(bp);
    80003a08:	8526                	mv	a0,s1
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	b5e080e7          	jalr	-1186(ra) # 80003568 <brelse>
  if(sb.magic != FSMAGIC)
    80003a12:	0009a703          	lw	a4,0(s3)
    80003a16:	102037b7          	lui	a5,0x10203
    80003a1a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a1e:	02f71263          	bne	a4,a5,80003a42 <fsinit+0x70>
  initlog(dev, &sb);
    80003a22:	0023b597          	auipc	a1,0x23b
    80003a26:	7a658593          	addi	a1,a1,1958 # 8023f1c8 <sb>
    80003a2a:	854a                	mv	a0,s2
    80003a2c:	00001097          	auipc	ra,0x1
    80003a30:	b4a080e7          	jalr	-1206(ra) # 80004576 <initlog>
}
    80003a34:	70a2                	ld	ra,40(sp)
    80003a36:	7402                	ld	s0,32(sp)
    80003a38:	64e2                	ld	s1,24(sp)
    80003a3a:	6942                	ld	s2,16(sp)
    80003a3c:	69a2                	ld	s3,8(sp)
    80003a3e:	6145                	addi	sp,sp,48
    80003a40:	8082                	ret
    panic("invalid file system");
    80003a42:	00005517          	auipc	a0,0x5
    80003a46:	c7e50513          	addi	a0,a0,-898 # 800086c0 <syscalls+0x168>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	af6080e7          	jalr	-1290(ra) # 80000540 <panic>

0000000080003a52 <iinit>:
{
    80003a52:	7179                	addi	sp,sp,-48
    80003a54:	f406                	sd	ra,40(sp)
    80003a56:	f022                	sd	s0,32(sp)
    80003a58:	ec26                	sd	s1,24(sp)
    80003a5a:	e84a                	sd	s2,16(sp)
    80003a5c:	e44e                	sd	s3,8(sp)
    80003a5e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a60:	00005597          	auipc	a1,0x5
    80003a64:	c7858593          	addi	a1,a1,-904 # 800086d8 <syscalls+0x180>
    80003a68:	0023b517          	auipc	a0,0x23b
    80003a6c:	78050513          	addi	a0,a0,1920 # 8023f1e8 <itable>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	22e080e7          	jalr	558(ra) # 80000c9e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a78:	0023b497          	auipc	s1,0x23b
    80003a7c:	79848493          	addi	s1,s1,1944 # 8023f210 <itable+0x28>
    80003a80:	0023d997          	auipc	s3,0x23d
    80003a84:	22098993          	addi	s3,s3,544 # 80240ca0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a88:	00005917          	auipc	s2,0x5
    80003a8c:	c5890913          	addi	s2,s2,-936 # 800086e0 <syscalls+0x188>
    80003a90:	85ca                	mv	a1,s2
    80003a92:	8526                	mv	a0,s1
    80003a94:	00001097          	auipc	ra,0x1
    80003a98:	e42080e7          	jalr	-446(ra) # 800048d6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a9c:	08848493          	addi	s1,s1,136
    80003aa0:	ff3498e3          	bne	s1,s3,80003a90 <iinit+0x3e>
}
    80003aa4:	70a2                	ld	ra,40(sp)
    80003aa6:	7402                	ld	s0,32(sp)
    80003aa8:	64e2                	ld	s1,24(sp)
    80003aaa:	6942                	ld	s2,16(sp)
    80003aac:	69a2                	ld	s3,8(sp)
    80003aae:	6145                	addi	sp,sp,48
    80003ab0:	8082                	ret

0000000080003ab2 <ialloc>:
{
    80003ab2:	715d                	addi	sp,sp,-80
    80003ab4:	e486                	sd	ra,72(sp)
    80003ab6:	e0a2                	sd	s0,64(sp)
    80003ab8:	fc26                	sd	s1,56(sp)
    80003aba:	f84a                	sd	s2,48(sp)
    80003abc:	f44e                	sd	s3,40(sp)
    80003abe:	f052                	sd	s4,32(sp)
    80003ac0:	ec56                	sd	s5,24(sp)
    80003ac2:	e85a                	sd	s6,16(sp)
    80003ac4:	e45e                	sd	s7,8(sp)
    80003ac6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ac8:	0023b717          	auipc	a4,0x23b
    80003acc:	70c72703          	lw	a4,1804(a4) # 8023f1d4 <sb+0xc>
    80003ad0:	4785                	li	a5,1
    80003ad2:	04e7fa63          	bgeu	a5,a4,80003b26 <ialloc+0x74>
    80003ad6:	8aaa                	mv	s5,a0
    80003ad8:	8bae                	mv	s7,a1
    80003ada:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003adc:	0023ba17          	auipc	s4,0x23b
    80003ae0:	6eca0a13          	addi	s4,s4,1772 # 8023f1c8 <sb>
    80003ae4:	00048b1b          	sext.w	s6,s1
    80003ae8:	0044d593          	srli	a1,s1,0x4
    80003aec:	018a2783          	lw	a5,24(s4)
    80003af0:	9dbd                	addw	a1,a1,a5
    80003af2:	8556                	mv	a0,s5
    80003af4:	00000097          	auipc	ra,0x0
    80003af8:	944080e7          	jalr	-1724(ra) # 80003438 <bread>
    80003afc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003afe:	05850993          	addi	s3,a0,88
    80003b02:	00f4f793          	andi	a5,s1,15
    80003b06:	079a                	slli	a5,a5,0x6
    80003b08:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b0a:	00099783          	lh	a5,0(s3)
    80003b0e:	c3a1                	beqz	a5,80003b4e <ialloc+0x9c>
    brelse(bp);
    80003b10:	00000097          	auipc	ra,0x0
    80003b14:	a58080e7          	jalr	-1448(ra) # 80003568 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b18:	0485                	addi	s1,s1,1
    80003b1a:	00ca2703          	lw	a4,12(s4)
    80003b1e:	0004879b          	sext.w	a5,s1
    80003b22:	fce7e1e3          	bltu	a5,a4,80003ae4 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003b26:	00005517          	auipc	a0,0x5
    80003b2a:	bc250513          	addi	a0,a0,-1086 # 800086e8 <syscalls+0x190>
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	a6e080e7          	jalr	-1426(ra) # 8000059c <printf>
  return 0;
    80003b36:	4501                	li	a0,0
}
    80003b38:	60a6                	ld	ra,72(sp)
    80003b3a:	6406                	ld	s0,64(sp)
    80003b3c:	74e2                	ld	s1,56(sp)
    80003b3e:	7942                	ld	s2,48(sp)
    80003b40:	79a2                	ld	s3,40(sp)
    80003b42:	7a02                	ld	s4,32(sp)
    80003b44:	6ae2                	ld	s5,24(sp)
    80003b46:	6b42                	ld	s6,16(sp)
    80003b48:	6ba2                	ld	s7,8(sp)
    80003b4a:	6161                	addi	sp,sp,80
    80003b4c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b4e:	04000613          	li	a2,64
    80003b52:	4581                	li	a1,0
    80003b54:	854e                	mv	a0,s3
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	2d4080e7          	jalr	724(ra) # 80000e2a <memset>
      dip->type = type;
    80003b5e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b62:	854a                	mv	a0,s2
    80003b64:	00001097          	auipc	ra,0x1
    80003b68:	c8e080e7          	jalr	-882(ra) # 800047f2 <log_write>
      brelse(bp);
    80003b6c:	854a                	mv	a0,s2
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	9fa080e7          	jalr	-1542(ra) # 80003568 <brelse>
      return iget(dev, inum);
    80003b76:	85da                	mv	a1,s6
    80003b78:	8556                	mv	a0,s5
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	d9c080e7          	jalr	-612(ra) # 80003916 <iget>
    80003b82:	bf5d                	j	80003b38 <ialloc+0x86>

0000000080003b84 <iupdate>:
{
    80003b84:	1101                	addi	sp,sp,-32
    80003b86:	ec06                	sd	ra,24(sp)
    80003b88:	e822                	sd	s0,16(sp)
    80003b8a:	e426                	sd	s1,8(sp)
    80003b8c:	e04a                	sd	s2,0(sp)
    80003b8e:	1000                	addi	s0,sp,32
    80003b90:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b92:	415c                	lw	a5,4(a0)
    80003b94:	0047d79b          	srliw	a5,a5,0x4
    80003b98:	0023b597          	auipc	a1,0x23b
    80003b9c:	6485a583          	lw	a1,1608(a1) # 8023f1e0 <sb+0x18>
    80003ba0:	9dbd                	addw	a1,a1,a5
    80003ba2:	4108                	lw	a0,0(a0)
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	894080e7          	jalr	-1900(ra) # 80003438 <bread>
    80003bac:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bae:	05850793          	addi	a5,a0,88
    80003bb2:	40d8                	lw	a4,4(s1)
    80003bb4:	8b3d                	andi	a4,a4,15
    80003bb6:	071a                	slli	a4,a4,0x6
    80003bb8:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003bba:	04449703          	lh	a4,68(s1)
    80003bbe:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003bc2:	04649703          	lh	a4,70(s1)
    80003bc6:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003bca:	04849703          	lh	a4,72(s1)
    80003bce:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003bd2:	04a49703          	lh	a4,74(s1)
    80003bd6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003bda:	44f8                	lw	a4,76(s1)
    80003bdc:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003bde:	03400613          	li	a2,52
    80003be2:	05048593          	addi	a1,s1,80
    80003be6:	00c78513          	addi	a0,a5,12
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	29c080e7          	jalr	668(ra) # 80000e86 <memmove>
  log_write(bp);
    80003bf2:	854a                	mv	a0,s2
    80003bf4:	00001097          	auipc	ra,0x1
    80003bf8:	bfe080e7          	jalr	-1026(ra) # 800047f2 <log_write>
  brelse(bp);
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	96a080e7          	jalr	-1686(ra) # 80003568 <brelse>
}
    80003c06:	60e2                	ld	ra,24(sp)
    80003c08:	6442                	ld	s0,16(sp)
    80003c0a:	64a2                	ld	s1,8(sp)
    80003c0c:	6902                	ld	s2,0(sp)
    80003c0e:	6105                	addi	sp,sp,32
    80003c10:	8082                	ret

0000000080003c12 <idup>:
{
    80003c12:	1101                	addi	sp,sp,-32
    80003c14:	ec06                	sd	ra,24(sp)
    80003c16:	e822                	sd	s0,16(sp)
    80003c18:	e426                	sd	s1,8(sp)
    80003c1a:	1000                	addi	s0,sp,32
    80003c1c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c1e:	0023b517          	auipc	a0,0x23b
    80003c22:	5ca50513          	addi	a0,a0,1482 # 8023f1e8 <itable>
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	108080e7          	jalr	264(ra) # 80000d2e <acquire>
  ip->ref++;
    80003c2e:	449c                	lw	a5,8(s1)
    80003c30:	2785                	addiw	a5,a5,1
    80003c32:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c34:	0023b517          	auipc	a0,0x23b
    80003c38:	5b450513          	addi	a0,a0,1460 # 8023f1e8 <itable>
    80003c3c:	ffffd097          	auipc	ra,0xffffd
    80003c40:	1a6080e7          	jalr	422(ra) # 80000de2 <release>
}
    80003c44:	8526                	mv	a0,s1
    80003c46:	60e2                	ld	ra,24(sp)
    80003c48:	6442                	ld	s0,16(sp)
    80003c4a:	64a2                	ld	s1,8(sp)
    80003c4c:	6105                	addi	sp,sp,32
    80003c4e:	8082                	ret

0000000080003c50 <ilock>:
{
    80003c50:	1101                	addi	sp,sp,-32
    80003c52:	ec06                	sd	ra,24(sp)
    80003c54:	e822                	sd	s0,16(sp)
    80003c56:	e426                	sd	s1,8(sp)
    80003c58:	e04a                	sd	s2,0(sp)
    80003c5a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c5c:	c115                	beqz	a0,80003c80 <ilock+0x30>
    80003c5e:	84aa                	mv	s1,a0
    80003c60:	451c                	lw	a5,8(a0)
    80003c62:	00f05f63          	blez	a5,80003c80 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c66:	0541                	addi	a0,a0,16
    80003c68:	00001097          	auipc	ra,0x1
    80003c6c:	ca8080e7          	jalr	-856(ra) # 80004910 <acquiresleep>
  if(ip->valid == 0){
    80003c70:	40bc                	lw	a5,64(s1)
    80003c72:	cf99                	beqz	a5,80003c90 <ilock+0x40>
}
    80003c74:	60e2                	ld	ra,24(sp)
    80003c76:	6442                	ld	s0,16(sp)
    80003c78:	64a2                	ld	s1,8(sp)
    80003c7a:	6902                	ld	s2,0(sp)
    80003c7c:	6105                	addi	sp,sp,32
    80003c7e:	8082                	ret
    panic("ilock");
    80003c80:	00005517          	auipc	a0,0x5
    80003c84:	a8050513          	addi	a0,a0,-1408 # 80008700 <syscalls+0x1a8>
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	8b8080e7          	jalr	-1864(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c90:	40dc                	lw	a5,4(s1)
    80003c92:	0047d79b          	srliw	a5,a5,0x4
    80003c96:	0023b597          	auipc	a1,0x23b
    80003c9a:	54a5a583          	lw	a1,1354(a1) # 8023f1e0 <sb+0x18>
    80003c9e:	9dbd                	addw	a1,a1,a5
    80003ca0:	4088                	lw	a0,0(s1)
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	796080e7          	jalr	1942(ra) # 80003438 <bread>
    80003caa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cac:	05850593          	addi	a1,a0,88
    80003cb0:	40dc                	lw	a5,4(s1)
    80003cb2:	8bbd                	andi	a5,a5,15
    80003cb4:	079a                	slli	a5,a5,0x6
    80003cb6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003cb8:	00059783          	lh	a5,0(a1)
    80003cbc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003cc0:	00259783          	lh	a5,2(a1)
    80003cc4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003cc8:	00459783          	lh	a5,4(a1)
    80003ccc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003cd0:	00659783          	lh	a5,6(a1)
    80003cd4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003cd8:	459c                	lw	a5,8(a1)
    80003cda:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003cdc:	03400613          	li	a2,52
    80003ce0:	05b1                	addi	a1,a1,12
    80003ce2:	05048513          	addi	a0,s1,80
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	1a0080e7          	jalr	416(ra) # 80000e86 <memmove>
    brelse(bp);
    80003cee:	854a                	mv	a0,s2
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	878080e7          	jalr	-1928(ra) # 80003568 <brelse>
    ip->valid = 1;
    80003cf8:	4785                	li	a5,1
    80003cfa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cfc:	04449783          	lh	a5,68(s1)
    80003d00:	fbb5                	bnez	a5,80003c74 <ilock+0x24>
      panic("ilock: no type");
    80003d02:	00005517          	auipc	a0,0x5
    80003d06:	a0650513          	addi	a0,a0,-1530 # 80008708 <syscalls+0x1b0>
    80003d0a:	ffffd097          	auipc	ra,0xffffd
    80003d0e:	836080e7          	jalr	-1994(ra) # 80000540 <panic>

0000000080003d12 <iunlock>:
{
    80003d12:	1101                	addi	sp,sp,-32
    80003d14:	ec06                	sd	ra,24(sp)
    80003d16:	e822                	sd	s0,16(sp)
    80003d18:	e426                	sd	s1,8(sp)
    80003d1a:	e04a                	sd	s2,0(sp)
    80003d1c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d1e:	c905                	beqz	a0,80003d4e <iunlock+0x3c>
    80003d20:	84aa                	mv	s1,a0
    80003d22:	01050913          	addi	s2,a0,16
    80003d26:	854a                	mv	a0,s2
    80003d28:	00001097          	auipc	ra,0x1
    80003d2c:	c82080e7          	jalr	-894(ra) # 800049aa <holdingsleep>
    80003d30:	cd19                	beqz	a0,80003d4e <iunlock+0x3c>
    80003d32:	449c                	lw	a5,8(s1)
    80003d34:	00f05d63          	blez	a5,80003d4e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d38:	854a                	mv	a0,s2
    80003d3a:	00001097          	auipc	ra,0x1
    80003d3e:	c2c080e7          	jalr	-980(ra) # 80004966 <releasesleep>
}
    80003d42:	60e2                	ld	ra,24(sp)
    80003d44:	6442                	ld	s0,16(sp)
    80003d46:	64a2                	ld	s1,8(sp)
    80003d48:	6902                	ld	s2,0(sp)
    80003d4a:	6105                	addi	sp,sp,32
    80003d4c:	8082                	ret
    panic("iunlock");
    80003d4e:	00005517          	auipc	a0,0x5
    80003d52:	9ca50513          	addi	a0,a0,-1590 # 80008718 <syscalls+0x1c0>
    80003d56:	ffffc097          	auipc	ra,0xffffc
    80003d5a:	7ea080e7          	jalr	2026(ra) # 80000540 <panic>

0000000080003d5e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d5e:	7179                	addi	sp,sp,-48
    80003d60:	f406                	sd	ra,40(sp)
    80003d62:	f022                	sd	s0,32(sp)
    80003d64:	ec26                	sd	s1,24(sp)
    80003d66:	e84a                	sd	s2,16(sp)
    80003d68:	e44e                	sd	s3,8(sp)
    80003d6a:	e052                	sd	s4,0(sp)
    80003d6c:	1800                	addi	s0,sp,48
    80003d6e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d70:	05050493          	addi	s1,a0,80
    80003d74:	08050913          	addi	s2,a0,128
    80003d78:	a021                	j	80003d80 <itrunc+0x22>
    80003d7a:	0491                	addi	s1,s1,4
    80003d7c:	01248d63          	beq	s1,s2,80003d96 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d80:	408c                	lw	a1,0(s1)
    80003d82:	dde5                	beqz	a1,80003d7a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d84:	0009a503          	lw	a0,0(s3)
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	8f6080e7          	jalr	-1802(ra) # 8000367e <bfree>
      ip->addrs[i] = 0;
    80003d90:	0004a023          	sw	zero,0(s1)
    80003d94:	b7dd                	j	80003d7a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d96:	0809a583          	lw	a1,128(s3)
    80003d9a:	e185                	bnez	a1,80003dba <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d9c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003da0:	854e                	mv	a0,s3
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	de2080e7          	jalr	-542(ra) # 80003b84 <iupdate>
}
    80003daa:	70a2                	ld	ra,40(sp)
    80003dac:	7402                	ld	s0,32(sp)
    80003dae:	64e2                	ld	s1,24(sp)
    80003db0:	6942                	ld	s2,16(sp)
    80003db2:	69a2                	ld	s3,8(sp)
    80003db4:	6a02                	ld	s4,0(sp)
    80003db6:	6145                	addi	sp,sp,48
    80003db8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003dba:	0009a503          	lw	a0,0(s3)
    80003dbe:	fffff097          	auipc	ra,0xfffff
    80003dc2:	67a080e7          	jalr	1658(ra) # 80003438 <bread>
    80003dc6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003dc8:	05850493          	addi	s1,a0,88
    80003dcc:	45850913          	addi	s2,a0,1112
    80003dd0:	a021                	j	80003dd8 <itrunc+0x7a>
    80003dd2:	0491                	addi	s1,s1,4
    80003dd4:	01248b63          	beq	s1,s2,80003dea <itrunc+0x8c>
      if(a[j])
    80003dd8:	408c                	lw	a1,0(s1)
    80003dda:	dde5                	beqz	a1,80003dd2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003ddc:	0009a503          	lw	a0,0(s3)
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	89e080e7          	jalr	-1890(ra) # 8000367e <bfree>
    80003de8:	b7ed                	j	80003dd2 <itrunc+0x74>
    brelse(bp);
    80003dea:	8552                	mv	a0,s4
    80003dec:	fffff097          	auipc	ra,0xfffff
    80003df0:	77c080e7          	jalr	1916(ra) # 80003568 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003df4:	0809a583          	lw	a1,128(s3)
    80003df8:	0009a503          	lw	a0,0(s3)
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	882080e7          	jalr	-1918(ra) # 8000367e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e04:	0809a023          	sw	zero,128(s3)
    80003e08:	bf51                	j	80003d9c <itrunc+0x3e>

0000000080003e0a <iput>:
{
    80003e0a:	1101                	addi	sp,sp,-32
    80003e0c:	ec06                	sd	ra,24(sp)
    80003e0e:	e822                	sd	s0,16(sp)
    80003e10:	e426                	sd	s1,8(sp)
    80003e12:	e04a                	sd	s2,0(sp)
    80003e14:	1000                	addi	s0,sp,32
    80003e16:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e18:	0023b517          	auipc	a0,0x23b
    80003e1c:	3d050513          	addi	a0,a0,976 # 8023f1e8 <itable>
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	f0e080e7          	jalr	-242(ra) # 80000d2e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e28:	4498                	lw	a4,8(s1)
    80003e2a:	4785                	li	a5,1
    80003e2c:	02f70363          	beq	a4,a5,80003e52 <iput+0x48>
  ip->ref--;
    80003e30:	449c                	lw	a5,8(s1)
    80003e32:	37fd                	addiw	a5,a5,-1
    80003e34:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e36:	0023b517          	auipc	a0,0x23b
    80003e3a:	3b250513          	addi	a0,a0,946 # 8023f1e8 <itable>
    80003e3e:	ffffd097          	auipc	ra,0xffffd
    80003e42:	fa4080e7          	jalr	-92(ra) # 80000de2 <release>
}
    80003e46:	60e2                	ld	ra,24(sp)
    80003e48:	6442                	ld	s0,16(sp)
    80003e4a:	64a2                	ld	s1,8(sp)
    80003e4c:	6902                	ld	s2,0(sp)
    80003e4e:	6105                	addi	sp,sp,32
    80003e50:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e52:	40bc                	lw	a5,64(s1)
    80003e54:	dff1                	beqz	a5,80003e30 <iput+0x26>
    80003e56:	04a49783          	lh	a5,74(s1)
    80003e5a:	fbf9                	bnez	a5,80003e30 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e5c:	01048913          	addi	s2,s1,16
    80003e60:	854a                	mv	a0,s2
    80003e62:	00001097          	auipc	ra,0x1
    80003e66:	aae080e7          	jalr	-1362(ra) # 80004910 <acquiresleep>
    release(&itable.lock);
    80003e6a:	0023b517          	auipc	a0,0x23b
    80003e6e:	37e50513          	addi	a0,a0,894 # 8023f1e8 <itable>
    80003e72:	ffffd097          	auipc	ra,0xffffd
    80003e76:	f70080e7          	jalr	-144(ra) # 80000de2 <release>
    itrunc(ip);
    80003e7a:	8526                	mv	a0,s1
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	ee2080e7          	jalr	-286(ra) # 80003d5e <itrunc>
    ip->type = 0;
    80003e84:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e88:	8526                	mv	a0,s1
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	cfa080e7          	jalr	-774(ra) # 80003b84 <iupdate>
    ip->valid = 0;
    80003e92:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e96:	854a                	mv	a0,s2
    80003e98:	00001097          	auipc	ra,0x1
    80003e9c:	ace080e7          	jalr	-1330(ra) # 80004966 <releasesleep>
    acquire(&itable.lock);
    80003ea0:	0023b517          	auipc	a0,0x23b
    80003ea4:	34850513          	addi	a0,a0,840 # 8023f1e8 <itable>
    80003ea8:	ffffd097          	auipc	ra,0xffffd
    80003eac:	e86080e7          	jalr	-378(ra) # 80000d2e <acquire>
    80003eb0:	b741                	j	80003e30 <iput+0x26>

0000000080003eb2 <iunlockput>:
{
    80003eb2:	1101                	addi	sp,sp,-32
    80003eb4:	ec06                	sd	ra,24(sp)
    80003eb6:	e822                	sd	s0,16(sp)
    80003eb8:	e426                	sd	s1,8(sp)
    80003eba:	1000                	addi	s0,sp,32
    80003ebc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	e54080e7          	jalr	-428(ra) # 80003d12 <iunlock>
  iput(ip);
    80003ec6:	8526                	mv	a0,s1
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	f42080e7          	jalr	-190(ra) # 80003e0a <iput>
}
    80003ed0:	60e2                	ld	ra,24(sp)
    80003ed2:	6442                	ld	s0,16(sp)
    80003ed4:	64a2                	ld	s1,8(sp)
    80003ed6:	6105                	addi	sp,sp,32
    80003ed8:	8082                	ret

0000000080003eda <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003eda:	1141                	addi	sp,sp,-16
    80003edc:	e422                	sd	s0,8(sp)
    80003ede:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ee0:	411c                	lw	a5,0(a0)
    80003ee2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ee4:	415c                	lw	a5,4(a0)
    80003ee6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ee8:	04451783          	lh	a5,68(a0)
    80003eec:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ef0:	04a51783          	lh	a5,74(a0)
    80003ef4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ef8:	04c56783          	lwu	a5,76(a0)
    80003efc:	e99c                	sd	a5,16(a1)
}
    80003efe:	6422                	ld	s0,8(sp)
    80003f00:	0141                	addi	sp,sp,16
    80003f02:	8082                	ret

0000000080003f04 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f04:	457c                	lw	a5,76(a0)
    80003f06:	0ed7e963          	bltu	a5,a3,80003ff8 <readi+0xf4>
{
    80003f0a:	7159                	addi	sp,sp,-112
    80003f0c:	f486                	sd	ra,104(sp)
    80003f0e:	f0a2                	sd	s0,96(sp)
    80003f10:	eca6                	sd	s1,88(sp)
    80003f12:	e8ca                	sd	s2,80(sp)
    80003f14:	e4ce                	sd	s3,72(sp)
    80003f16:	e0d2                	sd	s4,64(sp)
    80003f18:	fc56                	sd	s5,56(sp)
    80003f1a:	f85a                	sd	s6,48(sp)
    80003f1c:	f45e                	sd	s7,40(sp)
    80003f1e:	f062                	sd	s8,32(sp)
    80003f20:	ec66                	sd	s9,24(sp)
    80003f22:	e86a                	sd	s10,16(sp)
    80003f24:	e46e                	sd	s11,8(sp)
    80003f26:	1880                	addi	s0,sp,112
    80003f28:	8b2a                	mv	s6,a0
    80003f2a:	8bae                	mv	s7,a1
    80003f2c:	8a32                	mv	s4,a2
    80003f2e:	84b6                	mv	s1,a3
    80003f30:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f32:	9f35                	addw	a4,a4,a3
    return 0;
    80003f34:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f36:	0ad76063          	bltu	a4,a3,80003fd6 <readi+0xd2>
  if(off + n > ip->size)
    80003f3a:	00e7f463          	bgeu	a5,a4,80003f42 <readi+0x3e>
    n = ip->size - off;
    80003f3e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f42:	0a0a8963          	beqz	s5,80003ff4 <readi+0xf0>
    80003f46:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f48:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f4c:	5c7d                	li	s8,-1
    80003f4e:	a82d                	j	80003f88 <readi+0x84>
    80003f50:	020d1d93          	slli	s11,s10,0x20
    80003f54:	020ddd93          	srli	s11,s11,0x20
    80003f58:	05890613          	addi	a2,s2,88
    80003f5c:	86ee                	mv	a3,s11
    80003f5e:	963a                	add	a2,a2,a4
    80003f60:	85d2                	mv	a1,s4
    80003f62:	855e                	mv	a0,s7
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	878080e7          	jalr	-1928(ra) # 800027dc <either_copyout>
    80003f6c:	05850d63          	beq	a0,s8,80003fc6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f70:	854a                	mv	a0,s2
    80003f72:	fffff097          	auipc	ra,0xfffff
    80003f76:	5f6080e7          	jalr	1526(ra) # 80003568 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f7a:	013d09bb          	addw	s3,s10,s3
    80003f7e:	009d04bb          	addw	s1,s10,s1
    80003f82:	9a6e                	add	s4,s4,s11
    80003f84:	0559f763          	bgeu	s3,s5,80003fd2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f88:	00a4d59b          	srliw	a1,s1,0xa
    80003f8c:	855a                	mv	a0,s6
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	89e080e7          	jalr	-1890(ra) # 8000382c <bmap>
    80003f96:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f9a:	cd85                	beqz	a1,80003fd2 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f9c:	000b2503          	lw	a0,0(s6)
    80003fa0:	fffff097          	auipc	ra,0xfffff
    80003fa4:	498080e7          	jalr	1176(ra) # 80003438 <bread>
    80003fa8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003faa:	3ff4f713          	andi	a4,s1,1023
    80003fae:	40ec87bb          	subw	a5,s9,a4
    80003fb2:	413a86bb          	subw	a3,s5,s3
    80003fb6:	8d3e                	mv	s10,a5
    80003fb8:	2781                	sext.w	a5,a5
    80003fba:	0006861b          	sext.w	a2,a3
    80003fbe:	f8f679e3          	bgeu	a2,a5,80003f50 <readi+0x4c>
    80003fc2:	8d36                	mv	s10,a3
    80003fc4:	b771                	j	80003f50 <readi+0x4c>
      brelse(bp);
    80003fc6:	854a                	mv	a0,s2
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	5a0080e7          	jalr	1440(ra) # 80003568 <brelse>
      tot = -1;
    80003fd0:	59fd                	li	s3,-1
  }
  return tot;
    80003fd2:	0009851b          	sext.w	a0,s3
}
    80003fd6:	70a6                	ld	ra,104(sp)
    80003fd8:	7406                	ld	s0,96(sp)
    80003fda:	64e6                	ld	s1,88(sp)
    80003fdc:	6946                	ld	s2,80(sp)
    80003fde:	69a6                	ld	s3,72(sp)
    80003fe0:	6a06                	ld	s4,64(sp)
    80003fe2:	7ae2                	ld	s5,56(sp)
    80003fe4:	7b42                	ld	s6,48(sp)
    80003fe6:	7ba2                	ld	s7,40(sp)
    80003fe8:	7c02                	ld	s8,32(sp)
    80003fea:	6ce2                	ld	s9,24(sp)
    80003fec:	6d42                	ld	s10,16(sp)
    80003fee:	6da2                	ld	s11,8(sp)
    80003ff0:	6165                	addi	sp,sp,112
    80003ff2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ff4:	89d6                	mv	s3,s5
    80003ff6:	bff1                	j	80003fd2 <readi+0xce>
    return 0;
    80003ff8:	4501                	li	a0,0
}
    80003ffa:	8082                	ret

0000000080003ffc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ffc:	457c                	lw	a5,76(a0)
    80003ffe:	10d7e863          	bltu	a5,a3,8000410e <writei+0x112>
{
    80004002:	7159                	addi	sp,sp,-112
    80004004:	f486                	sd	ra,104(sp)
    80004006:	f0a2                	sd	s0,96(sp)
    80004008:	eca6                	sd	s1,88(sp)
    8000400a:	e8ca                	sd	s2,80(sp)
    8000400c:	e4ce                	sd	s3,72(sp)
    8000400e:	e0d2                	sd	s4,64(sp)
    80004010:	fc56                	sd	s5,56(sp)
    80004012:	f85a                	sd	s6,48(sp)
    80004014:	f45e                	sd	s7,40(sp)
    80004016:	f062                	sd	s8,32(sp)
    80004018:	ec66                	sd	s9,24(sp)
    8000401a:	e86a                	sd	s10,16(sp)
    8000401c:	e46e                	sd	s11,8(sp)
    8000401e:	1880                	addi	s0,sp,112
    80004020:	8aaa                	mv	s5,a0
    80004022:	8bae                	mv	s7,a1
    80004024:	8a32                	mv	s4,a2
    80004026:	8936                	mv	s2,a3
    80004028:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000402a:	00e687bb          	addw	a5,a3,a4
    8000402e:	0ed7e263          	bltu	a5,a3,80004112 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004032:	00043737          	lui	a4,0x43
    80004036:	0ef76063          	bltu	a4,a5,80004116 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000403a:	0c0b0863          	beqz	s6,8000410a <writei+0x10e>
    8000403e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004040:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004044:	5c7d                	li	s8,-1
    80004046:	a091                	j	8000408a <writei+0x8e>
    80004048:	020d1d93          	slli	s11,s10,0x20
    8000404c:	020ddd93          	srli	s11,s11,0x20
    80004050:	05848513          	addi	a0,s1,88
    80004054:	86ee                	mv	a3,s11
    80004056:	8652                	mv	a2,s4
    80004058:	85de                	mv	a1,s7
    8000405a:	953a                	add	a0,a0,a4
    8000405c:	ffffe097          	auipc	ra,0xffffe
    80004060:	7d6080e7          	jalr	2006(ra) # 80002832 <either_copyin>
    80004064:	07850263          	beq	a0,s8,800040c8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004068:	8526                	mv	a0,s1
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	788080e7          	jalr	1928(ra) # 800047f2 <log_write>
    brelse(bp);
    80004072:	8526                	mv	a0,s1
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	4f4080e7          	jalr	1268(ra) # 80003568 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000407c:	013d09bb          	addw	s3,s10,s3
    80004080:	012d093b          	addw	s2,s10,s2
    80004084:	9a6e                	add	s4,s4,s11
    80004086:	0569f663          	bgeu	s3,s6,800040d2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000408a:	00a9559b          	srliw	a1,s2,0xa
    8000408e:	8556                	mv	a0,s5
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	79c080e7          	jalr	1948(ra) # 8000382c <bmap>
    80004098:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000409c:	c99d                	beqz	a1,800040d2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000409e:	000aa503          	lw	a0,0(s5)
    800040a2:	fffff097          	auipc	ra,0xfffff
    800040a6:	396080e7          	jalr	918(ra) # 80003438 <bread>
    800040aa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040ac:	3ff97713          	andi	a4,s2,1023
    800040b0:	40ec87bb          	subw	a5,s9,a4
    800040b4:	413b06bb          	subw	a3,s6,s3
    800040b8:	8d3e                	mv	s10,a5
    800040ba:	2781                	sext.w	a5,a5
    800040bc:	0006861b          	sext.w	a2,a3
    800040c0:	f8f674e3          	bgeu	a2,a5,80004048 <writei+0x4c>
    800040c4:	8d36                	mv	s10,a3
    800040c6:	b749                	j	80004048 <writei+0x4c>
      brelse(bp);
    800040c8:	8526                	mv	a0,s1
    800040ca:	fffff097          	auipc	ra,0xfffff
    800040ce:	49e080e7          	jalr	1182(ra) # 80003568 <brelse>
  }

  if(off > ip->size)
    800040d2:	04caa783          	lw	a5,76(s5)
    800040d6:	0127f463          	bgeu	a5,s2,800040de <writei+0xe2>
    ip->size = off;
    800040da:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040de:	8556                	mv	a0,s5
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	aa4080e7          	jalr	-1372(ra) # 80003b84 <iupdate>

  return tot;
    800040e8:	0009851b          	sext.w	a0,s3
}
    800040ec:	70a6                	ld	ra,104(sp)
    800040ee:	7406                	ld	s0,96(sp)
    800040f0:	64e6                	ld	s1,88(sp)
    800040f2:	6946                	ld	s2,80(sp)
    800040f4:	69a6                	ld	s3,72(sp)
    800040f6:	6a06                	ld	s4,64(sp)
    800040f8:	7ae2                	ld	s5,56(sp)
    800040fa:	7b42                	ld	s6,48(sp)
    800040fc:	7ba2                	ld	s7,40(sp)
    800040fe:	7c02                	ld	s8,32(sp)
    80004100:	6ce2                	ld	s9,24(sp)
    80004102:	6d42                	ld	s10,16(sp)
    80004104:	6da2                	ld	s11,8(sp)
    80004106:	6165                	addi	sp,sp,112
    80004108:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000410a:	89da                	mv	s3,s6
    8000410c:	bfc9                	j	800040de <writei+0xe2>
    return -1;
    8000410e:	557d                	li	a0,-1
}
    80004110:	8082                	ret
    return -1;
    80004112:	557d                	li	a0,-1
    80004114:	bfe1                	j	800040ec <writei+0xf0>
    return -1;
    80004116:	557d                	li	a0,-1
    80004118:	bfd1                	j	800040ec <writei+0xf0>

000000008000411a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000411a:	1141                	addi	sp,sp,-16
    8000411c:	e406                	sd	ra,8(sp)
    8000411e:	e022                	sd	s0,0(sp)
    80004120:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004122:	4639                	li	a2,14
    80004124:	ffffd097          	auipc	ra,0xffffd
    80004128:	dd6080e7          	jalr	-554(ra) # 80000efa <strncmp>
}
    8000412c:	60a2                	ld	ra,8(sp)
    8000412e:	6402                	ld	s0,0(sp)
    80004130:	0141                	addi	sp,sp,16
    80004132:	8082                	ret

0000000080004134 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004134:	7139                	addi	sp,sp,-64
    80004136:	fc06                	sd	ra,56(sp)
    80004138:	f822                	sd	s0,48(sp)
    8000413a:	f426                	sd	s1,40(sp)
    8000413c:	f04a                	sd	s2,32(sp)
    8000413e:	ec4e                	sd	s3,24(sp)
    80004140:	e852                	sd	s4,16(sp)
    80004142:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004144:	04451703          	lh	a4,68(a0)
    80004148:	4785                	li	a5,1
    8000414a:	00f71a63          	bne	a4,a5,8000415e <dirlookup+0x2a>
    8000414e:	892a                	mv	s2,a0
    80004150:	89ae                	mv	s3,a1
    80004152:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004154:	457c                	lw	a5,76(a0)
    80004156:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004158:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000415a:	e79d                	bnez	a5,80004188 <dirlookup+0x54>
    8000415c:	a8a5                	j	800041d4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000415e:	00004517          	auipc	a0,0x4
    80004162:	5c250513          	addi	a0,a0,1474 # 80008720 <syscalls+0x1c8>
    80004166:	ffffc097          	auipc	ra,0xffffc
    8000416a:	3da080e7          	jalr	986(ra) # 80000540 <panic>
      panic("dirlookup read");
    8000416e:	00004517          	auipc	a0,0x4
    80004172:	5ca50513          	addi	a0,a0,1482 # 80008738 <syscalls+0x1e0>
    80004176:	ffffc097          	auipc	ra,0xffffc
    8000417a:	3ca080e7          	jalr	970(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000417e:	24c1                	addiw	s1,s1,16
    80004180:	04c92783          	lw	a5,76(s2)
    80004184:	04f4f763          	bgeu	s1,a5,800041d2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004188:	4741                	li	a4,16
    8000418a:	86a6                	mv	a3,s1
    8000418c:	fc040613          	addi	a2,s0,-64
    80004190:	4581                	li	a1,0
    80004192:	854a                	mv	a0,s2
    80004194:	00000097          	auipc	ra,0x0
    80004198:	d70080e7          	jalr	-656(ra) # 80003f04 <readi>
    8000419c:	47c1                	li	a5,16
    8000419e:	fcf518e3          	bne	a0,a5,8000416e <dirlookup+0x3a>
    if(de.inum == 0)
    800041a2:	fc045783          	lhu	a5,-64(s0)
    800041a6:	dfe1                	beqz	a5,8000417e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041a8:	fc240593          	addi	a1,s0,-62
    800041ac:	854e                	mv	a0,s3
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	f6c080e7          	jalr	-148(ra) # 8000411a <namecmp>
    800041b6:	f561                	bnez	a0,8000417e <dirlookup+0x4a>
      if(poff)
    800041b8:	000a0463          	beqz	s4,800041c0 <dirlookup+0x8c>
        *poff = off;
    800041bc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800041c0:	fc045583          	lhu	a1,-64(s0)
    800041c4:	00092503          	lw	a0,0(s2)
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	74e080e7          	jalr	1870(ra) # 80003916 <iget>
    800041d0:	a011                	j	800041d4 <dirlookup+0xa0>
  return 0;
    800041d2:	4501                	li	a0,0
}
    800041d4:	70e2                	ld	ra,56(sp)
    800041d6:	7442                	ld	s0,48(sp)
    800041d8:	74a2                	ld	s1,40(sp)
    800041da:	7902                	ld	s2,32(sp)
    800041dc:	69e2                	ld	s3,24(sp)
    800041de:	6a42                	ld	s4,16(sp)
    800041e0:	6121                	addi	sp,sp,64
    800041e2:	8082                	ret

00000000800041e4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041e4:	711d                	addi	sp,sp,-96
    800041e6:	ec86                	sd	ra,88(sp)
    800041e8:	e8a2                	sd	s0,80(sp)
    800041ea:	e4a6                	sd	s1,72(sp)
    800041ec:	e0ca                	sd	s2,64(sp)
    800041ee:	fc4e                	sd	s3,56(sp)
    800041f0:	f852                	sd	s4,48(sp)
    800041f2:	f456                	sd	s5,40(sp)
    800041f4:	f05a                	sd	s6,32(sp)
    800041f6:	ec5e                	sd	s7,24(sp)
    800041f8:	e862                	sd	s8,16(sp)
    800041fa:	e466                	sd	s9,8(sp)
    800041fc:	e06a                	sd	s10,0(sp)
    800041fe:	1080                	addi	s0,sp,96
    80004200:	84aa                	mv	s1,a0
    80004202:	8b2e                	mv	s6,a1
    80004204:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004206:	00054703          	lbu	a4,0(a0)
    8000420a:	02f00793          	li	a5,47
    8000420e:	02f70363          	beq	a4,a5,80004234 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004212:	ffffe097          	auipc	ra,0xffffe
    80004216:	a5a080e7          	jalr	-1446(ra) # 80001c6c <myproc>
    8000421a:	15053503          	ld	a0,336(a0)
    8000421e:	00000097          	auipc	ra,0x0
    80004222:	9f4080e7          	jalr	-1548(ra) # 80003c12 <idup>
    80004226:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004228:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000422c:	4cb5                	li	s9,13
  len = path - s;
    8000422e:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004230:	4c05                	li	s8,1
    80004232:	a87d                	j	800042f0 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004234:	4585                	li	a1,1
    80004236:	4505                	li	a0,1
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	6de080e7          	jalr	1758(ra) # 80003916 <iget>
    80004240:	8a2a                	mv	s4,a0
    80004242:	b7dd                	j	80004228 <namex+0x44>
      iunlockput(ip);
    80004244:	8552                	mv	a0,s4
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	c6c080e7          	jalr	-916(ra) # 80003eb2 <iunlockput>
      return 0;
    8000424e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004250:	8552                	mv	a0,s4
    80004252:	60e6                	ld	ra,88(sp)
    80004254:	6446                	ld	s0,80(sp)
    80004256:	64a6                	ld	s1,72(sp)
    80004258:	6906                	ld	s2,64(sp)
    8000425a:	79e2                	ld	s3,56(sp)
    8000425c:	7a42                	ld	s4,48(sp)
    8000425e:	7aa2                	ld	s5,40(sp)
    80004260:	7b02                	ld	s6,32(sp)
    80004262:	6be2                	ld	s7,24(sp)
    80004264:	6c42                	ld	s8,16(sp)
    80004266:	6ca2                	ld	s9,8(sp)
    80004268:	6d02                	ld	s10,0(sp)
    8000426a:	6125                	addi	sp,sp,96
    8000426c:	8082                	ret
      iunlock(ip);
    8000426e:	8552                	mv	a0,s4
    80004270:	00000097          	auipc	ra,0x0
    80004274:	aa2080e7          	jalr	-1374(ra) # 80003d12 <iunlock>
      return ip;
    80004278:	bfe1                	j	80004250 <namex+0x6c>
      iunlockput(ip);
    8000427a:	8552                	mv	a0,s4
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	c36080e7          	jalr	-970(ra) # 80003eb2 <iunlockput>
      return 0;
    80004284:	8a4e                	mv	s4,s3
    80004286:	b7e9                	j	80004250 <namex+0x6c>
  len = path - s;
    80004288:	40998633          	sub	a2,s3,s1
    8000428c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004290:	09acd863          	bge	s9,s10,80004320 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004294:	4639                	li	a2,14
    80004296:	85a6                	mv	a1,s1
    80004298:	8556                	mv	a0,s5
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	bec080e7          	jalr	-1044(ra) # 80000e86 <memmove>
    800042a2:	84ce                	mv	s1,s3
  while(*path == '/')
    800042a4:	0004c783          	lbu	a5,0(s1)
    800042a8:	01279763          	bne	a5,s2,800042b6 <namex+0xd2>
    path++;
    800042ac:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042ae:	0004c783          	lbu	a5,0(s1)
    800042b2:	ff278de3          	beq	a5,s2,800042ac <namex+0xc8>
    ilock(ip);
    800042b6:	8552                	mv	a0,s4
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	998080e7          	jalr	-1640(ra) # 80003c50 <ilock>
    if(ip->type != T_DIR){
    800042c0:	044a1783          	lh	a5,68(s4)
    800042c4:	f98790e3          	bne	a5,s8,80004244 <namex+0x60>
    if(nameiparent && *path == '\0'){
    800042c8:	000b0563          	beqz	s6,800042d2 <namex+0xee>
    800042cc:	0004c783          	lbu	a5,0(s1)
    800042d0:	dfd9                	beqz	a5,8000426e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800042d2:	865e                	mv	a2,s7
    800042d4:	85d6                	mv	a1,s5
    800042d6:	8552                	mv	a0,s4
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	e5c080e7          	jalr	-420(ra) # 80004134 <dirlookup>
    800042e0:	89aa                	mv	s3,a0
    800042e2:	dd41                	beqz	a0,8000427a <namex+0x96>
    iunlockput(ip);
    800042e4:	8552                	mv	a0,s4
    800042e6:	00000097          	auipc	ra,0x0
    800042ea:	bcc080e7          	jalr	-1076(ra) # 80003eb2 <iunlockput>
    ip = next;
    800042ee:	8a4e                	mv	s4,s3
  while(*path == '/')
    800042f0:	0004c783          	lbu	a5,0(s1)
    800042f4:	01279763          	bne	a5,s2,80004302 <namex+0x11e>
    path++;
    800042f8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042fa:	0004c783          	lbu	a5,0(s1)
    800042fe:	ff278de3          	beq	a5,s2,800042f8 <namex+0x114>
  if(*path == 0)
    80004302:	cb9d                	beqz	a5,80004338 <namex+0x154>
  while(*path != '/' && *path != 0)
    80004304:	0004c783          	lbu	a5,0(s1)
    80004308:	89a6                	mv	s3,s1
  len = path - s;
    8000430a:	8d5e                	mv	s10,s7
    8000430c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000430e:	01278963          	beq	a5,s2,80004320 <namex+0x13c>
    80004312:	dbbd                	beqz	a5,80004288 <namex+0xa4>
    path++;
    80004314:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004316:	0009c783          	lbu	a5,0(s3)
    8000431a:	ff279ce3          	bne	a5,s2,80004312 <namex+0x12e>
    8000431e:	b7ad                	j	80004288 <namex+0xa4>
    memmove(name, s, len);
    80004320:	2601                	sext.w	a2,a2
    80004322:	85a6                	mv	a1,s1
    80004324:	8556                	mv	a0,s5
    80004326:	ffffd097          	auipc	ra,0xffffd
    8000432a:	b60080e7          	jalr	-1184(ra) # 80000e86 <memmove>
    name[len] = 0;
    8000432e:	9d56                	add	s10,s10,s5
    80004330:	000d0023          	sb	zero,0(s10)
    80004334:	84ce                	mv	s1,s3
    80004336:	b7bd                	j	800042a4 <namex+0xc0>
  if(nameiparent){
    80004338:	f00b0ce3          	beqz	s6,80004250 <namex+0x6c>
    iput(ip);
    8000433c:	8552                	mv	a0,s4
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	acc080e7          	jalr	-1332(ra) # 80003e0a <iput>
    return 0;
    80004346:	4a01                	li	s4,0
    80004348:	b721                	j	80004250 <namex+0x6c>

000000008000434a <dirlink>:
{
    8000434a:	7139                	addi	sp,sp,-64
    8000434c:	fc06                	sd	ra,56(sp)
    8000434e:	f822                	sd	s0,48(sp)
    80004350:	f426                	sd	s1,40(sp)
    80004352:	f04a                	sd	s2,32(sp)
    80004354:	ec4e                	sd	s3,24(sp)
    80004356:	e852                	sd	s4,16(sp)
    80004358:	0080                	addi	s0,sp,64
    8000435a:	892a                	mv	s2,a0
    8000435c:	8a2e                	mv	s4,a1
    8000435e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004360:	4601                	li	a2,0
    80004362:	00000097          	auipc	ra,0x0
    80004366:	dd2080e7          	jalr	-558(ra) # 80004134 <dirlookup>
    8000436a:	e93d                	bnez	a0,800043e0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000436c:	04c92483          	lw	s1,76(s2)
    80004370:	c49d                	beqz	s1,8000439e <dirlink+0x54>
    80004372:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004374:	4741                	li	a4,16
    80004376:	86a6                	mv	a3,s1
    80004378:	fc040613          	addi	a2,s0,-64
    8000437c:	4581                	li	a1,0
    8000437e:	854a                	mv	a0,s2
    80004380:	00000097          	auipc	ra,0x0
    80004384:	b84080e7          	jalr	-1148(ra) # 80003f04 <readi>
    80004388:	47c1                	li	a5,16
    8000438a:	06f51163          	bne	a0,a5,800043ec <dirlink+0xa2>
    if(de.inum == 0)
    8000438e:	fc045783          	lhu	a5,-64(s0)
    80004392:	c791                	beqz	a5,8000439e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004394:	24c1                	addiw	s1,s1,16
    80004396:	04c92783          	lw	a5,76(s2)
    8000439a:	fcf4ede3          	bltu	s1,a5,80004374 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000439e:	4639                	li	a2,14
    800043a0:	85d2                	mv	a1,s4
    800043a2:	fc240513          	addi	a0,s0,-62
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	b90080e7          	jalr	-1136(ra) # 80000f36 <strncpy>
  de.inum = inum;
    800043ae:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043b2:	4741                	li	a4,16
    800043b4:	86a6                	mv	a3,s1
    800043b6:	fc040613          	addi	a2,s0,-64
    800043ba:	4581                	li	a1,0
    800043bc:	854a                	mv	a0,s2
    800043be:	00000097          	auipc	ra,0x0
    800043c2:	c3e080e7          	jalr	-962(ra) # 80003ffc <writei>
    800043c6:	1541                	addi	a0,a0,-16
    800043c8:	00a03533          	snez	a0,a0
    800043cc:	40a00533          	neg	a0,a0
}
    800043d0:	70e2                	ld	ra,56(sp)
    800043d2:	7442                	ld	s0,48(sp)
    800043d4:	74a2                	ld	s1,40(sp)
    800043d6:	7902                	ld	s2,32(sp)
    800043d8:	69e2                	ld	s3,24(sp)
    800043da:	6a42                	ld	s4,16(sp)
    800043dc:	6121                	addi	sp,sp,64
    800043de:	8082                	ret
    iput(ip);
    800043e0:	00000097          	auipc	ra,0x0
    800043e4:	a2a080e7          	jalr	-1494(ra) # 80003e0a <iput>
    return -1;
    800043e8:	557d                	li	a0,-1
    800043ea:	b7dd                	j	800043d0 <dirlink+0x86>
      panic("dirlink read");
    800043ec:	00004517          	auipc	a0,0x4
    800043f0:	35c50513          	addi	a0,a0,860 # 80008748 <syscalls+0x1f0>
    800043f4:	ffffc097          	auipc	ra,0xffffc
    800043f8:	14c080e7          	jalr	332(ra) # 80000540 <panic>

00000000800043fc <namei>:

struct inode*
namei(char *path)
{
    800043fc:	1101                	addi	sp,sp,-32
    800043fe:	ec06                	sd	ra,24(sp)
    80004400:	e822                	sd	s0,16(sp)
    80004402:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004404:	fe040613          	addi	a2,s0,-32
    80004408:	4581                	li	a1,0
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	dda080e7          	jalr	-550(ra) # 800041e4 <namex>
}
    80004412:	60e2                	ld	ra,24(sp)
    80004414:	6442                	ld	s0,16(sp)
    80004416:	6105                	addi	sp,sp,32
    80004418:	8082                	ret

000000008000441a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000441a:	1141                	addi	sp,sp,-16
    8000441c:	e406                	sd	ra,8(sp)
    8000441e:	e022                	sd	s0,0(sp)
    80004420:	0800                	addi	s0,sp,16
    80004422:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004424:	4585                	li	a1,1
    80004426:	00000097          	auipc	ra,0x0
    8000442a:	dbe080e7          	jalr	-578(ra) # 800041e4 <namex>
}
    8000442e:	60a2                	ld	ra,8(sp)
    80004430:	6402                	ld	s0,0(sp)
    80004432:	0141                	addi	sp,sp,16
    80004434:	8082                	ret

0000000080004436 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004436:	1101                	addi	sp,sp,-32
    80004438:	ec06                	sd	ra,24(sp)
    8000443a:	e822                	sd	s0,16(sp)
    8000443c:	e426                	sd	s1,8(sp)
    8000443e:	e04a                	sd	s2,0(sp)
    80004440:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004442:	0023d917          	auipc	s2,0x23d
    80004446:	84e90913          	addi	s2,s2,-1970 # 80240c90 <log>
    8000444a:	01892583          	lw	a1,24(s2)
    8000444e:	02892503          	lw	a0,40(s2)
    80004452:	fffff097          	auipc	ra,0xfffff
    80004456:	fe6080e7          	jalr	-26(ra) # 80003438 <bread>
    8000445a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000445c:	02c92683          	lw	a3,44(s2)
    80004460:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004462:	02d05863          	blez	a3,80004492 <write_head+0x5c>
    80004466:	0023d797          	auipc	a5,0x23d
    8000446a:	85a78793          	addi	a5,a5,-1958 # 80240cc0 <log+0x30>
    8000446e:	05c50713          	addi	a4,a0,92
    80004472:	36fd                	addiw	a3,a3,-1
    80004474:	02069613          	slli	a2,a3,0x20
    80004478:	01e65693          	srli	a3,a2,0x1e
    8000447c:	0023d617          	auipc	a2,0x23d
    80004480:	84860613          	addi	a2,a2,-1976 # 80240cc4 <log+0x34>
    80004484:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004486:	4390                	lw	a2,0(a5)
    80004488:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000448a:	0791                	addi	a5,a5,4
    8000448c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000448e:	fed79ce3          	bne	a5,a3,80004486 <write_head+0x50>
  }
  bwrite(buf);
    80004492:	8526                	mv	a0,s1
    80004494:	fffff097          	auipc	ra,0xfffff
    80004498:	096080e7          	jalr	150(ra) # 8000352a <bwrite>
  brelse(buf);
    8000449c:	8526                	mv	a0,s1
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	0ca080e7          	jalr	202(ra) # 80003568 <brelse>
}
    800044a6:	60e2                	ld	ra,24(sp)
    800044a8:	6442                	ld	s0,16(sp)
    800044aa:	64a2                	ld	s1,8(sp)
    800044ac:	6902                	ld	s2,0(sp)
    800044ae:	6105                	addi	sp,sp,32
    800044b0:	8082                	ret

00000000800044b2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b2:	0023d797          	auipc	a5,0x23d
    800044b6:	80a7a783          	lw	a5,-2038(a5) # 80240cbc <log+0x2c>
    800044ba:	0af05d63          	blez	a5,80004574 <install_trans+0xc2>
{
    800044be:	7139                	addi	sp,sp,-64
    800044c0:	fc06                	sd	ra,56(sp)
    800044c2:	f822                	sd	s0,48(sp)
    800044c4:	f426                	sd	s1,40(sp)
    800044c6:	f04a                	sd	s2,32(sp)
    800044c8:	ec4e                	sd	s3,24(sp)
    800044ca:	e852                	sd	s4,16(sp)
    800044cc:	e456                	sd	s5,8(sp)
    800044ce:	e05a                	sd	s6,0(sp)
    800044d0:	0080                	addi	s0,sp,64
    800044d2:	8b2a                	mv	s6,a0
    800044d4:	0023ca97          	auipc	s5,0x23c
    800044d8:	7eca8a93          	addi	s5,s5,2028 # 80240cc0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044dc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044de:	0023c997          	auipc	s3,0x23c
    800044e2:	7b298993          	addi	s3,s3,1970 # 80240c90 <log>
    800044e6:	a00d                	j	80004508 <install_trans+0x56>
    brelse(lbuf);
    800044e8:	854a                	mv	a0,s2
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	07e080e7          	jalr	126(ra) # 80003568 <brelse>
    brelse(dbuf);
    800044f2:	8526                	mv	a0,s1
    800044f4:	fffff097          	auipc	ra,0xfffff
    800044f8:	074080e7          	jalr	116(ra) # 80003568 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044fc:	2a05                	addiw	s4,s4,1
    800044fe:	0a91                	addi	s5,s5,4
    80004500:	02c9a783          	lw	a5,44(s3)
    80004504:	04fa5e63          	bge	s4,a5,80004560 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004508:	0189a583          	lw	a1,24(s3)
    8000450c:	014585bb          	addw	a1,a1,s4
    80004510:	2585                	addiw	a1,a1,1
    80004512:	0289a503          	lw	a0,40(s3)
    80004516:	fffff097          	auipc	ra,0xfffff
    8000451a:	f22080e7          	jalr	-222(ra) # 80003438 <bread>
    8000451e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004520:	000aa583          	lw	a1,0(s5)
    80004524:	0289a503          	lw	a0,40(s3)
    80004528:	fffff097          	auipc	ra,0xfffff
    8000452c:	f10080e7          	jalr	-240(ra) # 80003438 <bread>
    80004530:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004532:	40000613          	li	a2,1024
    80004536:	05890593          	addi	a1,s2,88
    8000453a:	05850513          	addi	a0,a0,88
    8000453e:	ffffd097          	auipc	ra,0xffffd
    80004542:	948080e7          	jalr	-1720(ra) # 80000e86 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004546:	8526                	mv	a0,s1
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	fe2080e7          	jalr	-30(ra) # 8000352a <bwrite>
    if(recovering == 0)
    80004550:	f80b1ce3          	bnez	s6,800044e8 <install_trans+0x36>
      bunpin(dbuf);
    80004554:	8526                	mv	a0,s1
    80004556:	fffff097          	auipc	ra,0xfffff
    8000455a:	0ec080e7          	jalr	236(ra) # 80003642 <bunpin>
    8000455e:	b769                	j	800044e8 <install_trans+0x36>
}
    80004560:	70e2                	ld	ra,56(sp)
    80004562:	7442                	ld	s0,48(sp)
    80004564:	74a2                	ld	s1,40(sp)
    80004566:	7902                	ld	s2,32(sp)
    80004568:	69e2                	ld	s3,24(sp)
    8000456a:	6a42                	ld	s4,16(sp)
    8000456c:	6aa2                	ld	s5,8(sp)
    8000456e:	6b02                	ld	s6,0(sp)
    80004570:	6121                	addi	sp,sp,64
    80004572:	8082                	ret
    80004574:	8082                	ret

0000000080004576 <initlog>:
{
    80004576:	7179                	addi	sp,sp,-48
    80004578:	f406                	sd	ra,40(sp)
    8000457a:	f022                	sd	s0,32(sp)
    8000457c:	ec26                	sd	s1,24(sp)
    8000457e:	e84a                	sd	s2,16(sp)
    80004580:	e44e                	sd	s3,8(sp)
    80004582:	1800                	addi	s0,sp,48
    80004584:	892a                	mv	s2,a0
    80004586:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004588:	0023c497          	auipc	s1,0x23c
    8000458c:	70848493          	addi	s1,s1,1800 # 80240c90 <log>
    80004590:	00004597          	auipc	a1,0x4
    80004594:	1c858593          	addi	a1,a1,456 # 80008758 <syscalls+0x200>
    80004598:	8526                	mv	a0,s1
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	704080e7          	jalr	1796(ra) # 80000c9e <initlock>
  log.start = sb->logstart;
    800045a2:	0149a583          	lw	a1,20(s3)
    800045a6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045a8:	0109a783          	lw	a5,16(s3)
    800045ac:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045ae:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045b2:	854a                	mv	a0,s2
    800045b4:	fffff097          	auipc	ra,0xfffff
    800045b8:	e84080e7          	jalr	-380(ra) # 80003438 <bread>
  log.lh.n = lh->n;
    800045bc:	4d34                	lw	a3,88(a0)
    800045be:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045c0:	02d05663          	blez	a3,800045ec <initlog+0x76>
    800045c4:	05c50793          	addi	a5,a0,92
    800045c8:	0023c717          	auipc	a4,0x23c
    800045cc:	6f870713          	addi	a4,a4,1784 # 80240cc0 <log+0x30>
    800045d0:	36fd                	addiw	a3,a3,-1
    800045d2:	02069613          	slli	a2,a3,0x20
    800045d6:	01e65693          	srli	a3,a2,0x1e
    800045da:	06050613          	addi	a2,a0,96
    800045de:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800045e0:	4390                	lw	a2,0(a5)
    800045e2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045e4:	0791                	addi	a5,a5,4
    800045e6:	0711                	addi	a4,a4,4
    800045e8:	fed79ce3          	bne	a5,a3,800045e0 <initlog+0x6a>
  brelse(buf);
    800045ec:	fffff097          	auipc	ra,0xfffff
    800045f0:	f7c080e7          	jalr	-132(ra) # 80003568 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045f4:	4505                	li	a0,1
    800045f6:	00000097          	auipc	ra,0x0
    800045fa:	ebc080e7          	jalr	-324(ra) # 800044b2 <install_trans>
  log.lh.n = 0;
    800045fe:	0023c797          	auipc	a5,0x23c
    80004602:	6a07af23          	sw	zero,1726(a5) # 80240cbc <log+0x2c>
  write_head(); // clear the log
    80004606:	00000097          	auipc	ra,0x0
    8000460a:	e30080e7          	jalr	-464(ra) # 80004436 <write_head>
}
    8000460e:	70a2                	ld	ra,40(sp)
    80004610:	7402                	ld	s0,32(sp)
    80004612:	64e2                	ld	s1,24(sp)
    80004614:	6942                	ld	s2,16(sp)
    80004616:	69a2                	ld	s3,8(sp)
    80004618:	6145                	addi	sp,sp,48
    8000461a:	8082                	ret

000000008000461c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000461c:	1101                	addi	sp,sp,-32
    8000461e:	ec06                	sd	ra,24(sp)
    80004620:	e822                	sd	s0,16(sp)
    80004622:	e426                	sd	s1,8(sp)
    80004624:	e04a                	sd	s2,0(sp)
    80004626:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004628:	0023c517          	auipc	a0,0x23c
    8000462c:	66850513          	addi	a0,a0,1640 # 80240c90 <log>
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	6fe080e7          	jalr	1790(ra) # 80000d2e <acquire>
  while(1){
    if(log.committing){
    80004638:	0023c497          	auipc	s1,0x23c
    8000463c:	65848493          	addi	s1,s1,1624 # 80240c90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004640:	4979                	li	s2,30
    80004642:	a039                	j	80004650 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004644:	85a6                	mv	a1,s1
    80004646:	8526                	mv	a0,s1
    80004648:	ffffe097          	auipc	ra,0xffffe
    8000464c:	d8c080e7          	jalr	-628(ra) # 800023d4 <sleep>
    if(log.committing){
    80004650:	50dc                	lw	a5,36(s1)
    80004652:	fbed                	bnez	a5,80004644 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004654:	5098                	lw	a4,32(s1)
    80004656:	2705                	addiw	a4,a4,1
    80004658:	0007069b          	sext.w	a3,a4
    8000465c:	0027179b          	slliw	a5,a4,0x2
    80004660:	9fb9                	addw	a5,a5,a4
    80004662:	0017979b          	slliw	a5,a5,0x1
    80004666:	54d8                	lw	a4,44(s1)
    80004668:	9fb9                	addw	a5,a5,a4
    8000466a:	00f95963          	bge	s2,a5,8000467c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000466e:	85a6                	mv	a1,s1
    80004670:	8526                	mv	a0,s1
    80004672:	ffffe097          	auipc	ra,0xffffe
    80004676:	d62080e7          	jalr	-670(ra) # 800023d4 <sleep>
    8000467a:	bfd9                	j	80004650 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000467c:	0023c517          	auipc	a0,0x23c
    80004680:	61450513          	addi	a0,a0,1556 # 80240c90 <log>
    80004684:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	75c080e7          	jalr	1884(ra) # 80000de2 <release>
      break;
    }
  }
}
    8000468e:	60e2                	ld	ra,24(sp)
    80004690:	6442                	ld	s0,16(sp)
    80004692:	64a2                	ld	s1,8(sp)
    80004694:	6902                	ld	s2,0(sp)
    80004696:	6105                	addi	sp,sp,32
    80004698:	8082                	ret

000000008000469a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000469a:	7139                	addi	sp,sp,-64
    8000469c:	fc06                	sd	ra,56(sp)
    8000469e:	f822                	sd	s0,48(sp)
    800046a0:	f426                	sd	s1,40(sp)
    800046a2:	f04a                	sd	s2,32(sp)
    800046a4:	ec4e                	sd	s3,24(sp)
    800046a6:	e852                	sd	s4,16(sp)
    800046a8:	e456                	sd	s5,8(sp)
    800046aa:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046ac:	0023c497          	auipc	s1,0x23c
    800046b0:	5e448493          	addi	s1,s1,1508 # 80240c90 <log>
    800046b4:	8526                	mv	a0,s1
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	678080e7          	jalr	1656(ra) # 80000d2e <acquire>
  log.outstanding -= 1;
    800046be:	509c                	lw	a5,32(s1)
    800046c0:	37fd                	addiw	a5,a5,-1
    800046c2:	0007891b          	sext.w	s2,a5
    800046c6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046c8:	50dc                	lw	a5,36(s1)
    800046ca:	e7b9                	bnez	a5,80004718 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046cc:	04091e63          	bnez	s2,80004728 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800046d0:	0023c497          	auipc	s1,0x23c
    800046d4:	5c048493          	addi	s1,s1,1472 # 80240c90 <log>
    800046d8:	4785                	li	a5,1
    800046da:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046dc:	8526                	mv	a0,s1
    800046de:	ffffc097          	auipc	ra,0xffffc
    800046e2:	704080e7          	jalr	1796(ra) # 80000de2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046e6:	54dc                	lw	a5,44(s1)
    800046e8:	06f04763          	bgtz	a5,80004756 <end_op+0xbc>
    acquire(&log.lock);
    800046ec:	0023c497          	auipc	s1,0x23c
    800046f0:	5a448493          	addi	s1,s1,1444 # 80240c90 <log>
    800046f4:	8526                	mv	a0,s1
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	638080e7          	jalr	1592(ra) # 80000d2e <acquire>
    log.committing = 0;
    800046fe:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004702:	8526                	mv	a0,s1
    80004704:	ffffe097          	auipc	ra,0xffffe
    80004708:	d34080e7          	jalr	-716(ra) # 80002438 <wakeup>
    release(&log.lock);
    8000470c:	8526                	mv	a0,s1
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	6d4080e7          	jalr	1748(ra) # 80000de2 <release>
}
    80004716:	a03d                	j	80004744 <end_op+0xaa>
    panic("log.committing");
    80004718:	00004517          	auipc	a0,0x4
    8000471c:	04850513          	addi	a0,a0,72 # 80008760 <syscalls+0x208>
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	e20080e7          	jalr	-480(ra) # 80000540 <panic>
    wakeup(&log);
    80004728:	0023c497          	auipc	s1,0x23c
    8000472c:	56848493          	addi	s1,s1,1384 # 80240c90 <log>
    80004730:	8526                	mv	a0,s1
    80004732:	ffffe097          	auipc	ra,0xffffe
    80004736:	d06080e7          	jalr	-762(ra) # 80002438 <wakeup>
  release(&log.lock);
    8000473a:	8526                	mv	a0,s1
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	6a6080e7          	jalr	1702(ra) # 80000de2 <release>
}
    80004744:	70e2                	ld	ra,56(sp)
    80004746:	7442                	ld	s0,48(sp)
    80004748:	74a2                	ld	s1,40(sp)
    8000474a:	7902                	ld	s2,32(sp)
    8000474c:	69e2                	ld	s3,24(sp)
    8000474e:	6a42                	ld	s4,16(sp)
    80004750:	6aa2                	ld	s5,8(sp)
    80004752:	6121                	addi	sp,sp,64
    80004754:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004756:	0023ca97          	auipc	s5,0x23c
    8000475a:	56aa8a93          	addi	s5,s5,1386 # 80240cc0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000475e:	0023ca17          	auipc	s4,0x23c
    80004762:	532a0a13          	addi	s4,s4,1330 # 80240c90 <log>
    80004766:	018a2583          	lw	a1,24(s4)
    8000476a:	012585bb          	addw	a1,a1,s2
    8000476e:	2585                	addiw	a1,a1,1
    80004770:	028a2503          	lw	a0,40(s4)
    80004774:	fffff097          	auipc	ra,0xfffff
    80004778:	cc4080e7          	jalr	-828(ra) # 80003438 <bread>
    8000477c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000477e:	000aa583          	lw	a1,0(s5)
    80004782:	028a2503          	lw	a0,40(s4)
    80004786:	fffff097          	auipc	ra,0xfffff
    8000478a:	cb2080e7          	jalr	-846(ra) # 80003438 <bread>
    8000478e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004790:	40000613          	li	a2,1024
    80004794:	05850593          	addi	a1,a0,88
    80004798:	05848513          	addi	a0,s1,88
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	6ea080e7          	jalr	1770(ra) # 80000e86 <memmove>
    bwrite(to);  // write the log
    800047a4:	8526                	mv	a0,s1
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	d84080e7          	jalr	-636(ra) # 8000352a <bwrite>
    brelse(from);
    800047ae:	854e                	mv	a0,s3
    800047b0:	fffff097          	auipc	ra,0xfffff
    800047b4:	db8080e7          	jalr	-584(ra) # 80003568 <brelse>
    brelse(to);
    800047b8:	8526                	mv	a0,s1
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	dae080e7          	jalr	-594(ra) # 80003568 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047c2:	2905                	addiw	s2,s2,1
    800047c4:	0a91                	addi	s5,s5,4
    800047c6:	02ca2783          	lw	a5,44(s4)
    800047ca:	f8f94ee3          	blt	s2,a5,80004766 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047ce:	00000097          	auipc	ra,0x0
    800047d2:	c68080e7          	jalr	-920(ra) # 80004436 <write_head>
    install_trans(0); // Now install writes to home locations
    800047d6:	4501                	li	a0,0
    800047d8:	00000097          	auipc	ra,0x0
    800047dc:	cda080e7          	jalr	-806(ra) # 800044b2 <install_trans>
    log.lh.n = 0;
    800047e0:	0023c797          	auipc	a5,0x23c
    800047e4:	4c07ae23          	sw	zero,1244(a5) # 80240cbc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047e8:	00000097          	auipc	ra,0x0
    800047ec:	c4e080e7          	jalr	-946(ra) # 80004436 <write_head>
    800047f0:	bdf5                	j	800046ec <end_op+0x52>

00000000800047f2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047f2:	1101                	addi	sp,sp,-32
    800047f4:	ec06                	sd	ra,24(sp)
    800047f6:	e822                	sd	s0,16(sp)
    800047f8:	e426                	sd	s1,8(sp)
    800047fa:	e04a                	sd	s2,0(sp)
    800047fc:	1000                	addi	s0,sp,32
    800047fe:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004800:	0023c917          	auipc	s2,0x23c
    80004804:	49090913          	addi	s2,s2,1168 # 80240c90 <log>
    80004808:	854a                	mv	a0,s2
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	524080e7          	jalr	1316(ra) # 80000d2e <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004812:	02c92603          	lw	a2,44(s2)
    80004816:	47f5                	li	a5,29
    80004818:	06c7c563          	blt	a5,a2,80004882 <log_write+0x90>
    8000481c:	0023c797          	auipc	a5,0x23c
    80004820:	4907a783          	lw	a5,1168(a5) # 80240cac <log+0x1c>
    80004824:	37fd                	addiw	a5,a5,-1
    80004826:	04f65e63          	bge	a2,a5,80004882 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000482a:	0023c797          	auipc	a5,0x23c
    8000482e:	4867a783          	lw	a5,1158(a5) # 80240cb0 <log+0x20>
    80004832:	06f05063          	blez	a5,80004892 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004836:	4781                	li	a5,0
    80004838:	06c05563          	blez	a2,800048a2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000483c:	44cc                	lw	a1,12(s1)
    8000483e:	0023c717          	auipc	a4,0x23c
    80004842:	48270713          	addi	a4,a4,1154 # 80240cc0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004846:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004848:	4314                	lw	a3,0(a4)
    8000484a:	04b68c63          	beq	a3,a1,800048a2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000484e:	2785                	addiw	a5,a5,1
    80004850:	0711                	addi	a4,a4,4
    80004852:	fef61be3          	bne	a2,a5,80004848 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004856:	0621                	addi	a2,a2,8
    80004858:	060a                	slli	a2,a2,0x2
    8000485a:	0023c797          	auipc	a5,0x23c
    8000485e:	43678793          	addi	a5,a5,1078 # 80240c90 <log>
    80004862:	97b2                	add	a5,a5,a2
    80004864:	44d8                	lw	a4,12(s1)
    80004866:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004868:	8526                	mv	a0,s1
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	d9c080e7          	jalr	-612(ra) # 80003606 <bpin>
    log.lh.n++;
    80004872:	0023c717          	auipc	a4,0x23c
    80004876:	41e70713          	addi	a4,a4,1054 # 80240c90 <log>
    8000487a:	575c                	lw	a5,44(a4)
    8000487c:	2785                	addiw	a5,a5,1
    8000487e:	d75c                	sw	a5,44(a4)
    80004880:	a82d                	j	800048ba <log_write+0xc8>
    panic("too big a transaction");
    80004882:	00004517          	auipc	a0,0x4
    80004886:	eee50513          	addi	a0,a0,-274 # 80008770 <syscalls+0x218>
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	cb6080e7          	jalr	-842(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004892:	00004517          	auipc	a0,0x4
    80004896:	ef650513          	addi	a0,a0,-266 # 80008788 <syscalls+0x230>
    8000489a:	ffffc097          	auipc	ra,0xffffc
    8000489e:	ca6080e7          	jalr	-858(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800048a2:	00878693          	addi	a3,a5,8
    800048a6:	068a                	slli	a3,a3,0x2
    800048a8:	0023c717          	auipc	a4,0x23c
    800048ac:	3e870713          	addi	a4,a4,1000 # 80240c90 <log>
    800048b0:	9736                	add	a4,a4,a3
    800048b2:	44d4                	lw	a3,12(s1)
    800048b4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048b6:	faf609e3          	beq	a2,a5,80004868 <log_write+0x76>
  }
  release(&log.lock);
    800048ba:	0023c517          	auipc	a0,0x23c
    800048be:	3d650513          	addi	a0,a0,982 # 80240c90 <log>
    800048c2:	ffffc097          	auipc	ra,0xffffc
    800048c6:	520080e7          	jalr	1312(ra) # 80000de2 <release>
}
    800048ca:	60e2                	ld	ra,24(sp)
    800048cc:	6442                	ld	s0,16(sp)
    800048ce:	64a2                	ld	s1,8(sp)
    800048d0:	6902                	ld	s2,0(sp)
    800048d2:	6105                	addi	sp,sp,32
    800048d4:	8082                	ret

00000000800048d6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048d6:	1101                	addi	sp,sp,-32
    800048d8:	ec06                	sd	ra,24(sp)
    800048da:	e822                	sd	s0,16(sp)
    800048dc:	e426                	sd	s1,8(sp)
    800048de:	e04a                	sd	s2,0(sp)
    800048e0:	1000                	addi	s0,sp,32
    800048e2:	84aa                	mv	s1,a0
    800048e4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048e6:	00004597          	auipc	a1,0x4
    800048ea:	ec258593          	addi	a1,a1,-318 # 800087a8 <syscalls+0x250>
    800048ee:	0521                	addi	a0,a0,8
    800048f0:	ffffc097          	auipc	ra,0xffffc
    800048f4:	3ae080e7          	jalr	942(ra) # 80000c9e <initlock>
  lk->name = name;
    800048f8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048fc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004900:	0204a423          	sw	zero,40(s1)
}
    80004904:	60e2                	ld	ra,24(sp)
    80004906:	6442                	ld	s0,16(sp)
    80004908:	64a2                	ld	s1,8(sp)
    8000490a:	6902                	ld	s2,0(sp)
    8000490c:	6105                	addi	sp,sp,32
    8000490e:	8082                	ret

0000000080004910 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004910:	1101                	addi	sp,sp,-32
    80004912:	ec06                	sd	ra,24(sp)
    80004914:	e822                	sd	s0,16(sp)
    80004916:	e426                	sd	s1,8(sp)
    80004918:	e04a                	sd	s2,0(sp)
    8000491a:	1000                	addi	s0,sp,32
    8000491c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000491e:	00850913          	addi	s2,a0,8
    80004922:	854a                	mv	a0,s2
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	40a080e7          	jalr	1034(ra) # 80000d2e <acquire>
  while (lk->locked) {
    8000492c:	409c                	lw	a5,0(s1)
    8000492e:	cb89                	beqz	a5,80004940 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004930:	85ca                	mv	a1,s2
    80004932:	8526                	mv	a0,s1
    80004934:	ffffe097          	auipc	ra,0xffffe
    80004938:	aa0080e7          	jalr	-1376(ra) # 800023d4 <sleep>
  while (lk->locked) {
    8000493c:	409c                	lw	a5,0(s1)
    8000493e:	fbed                	bnez	a5,80004930 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004940:	4785                	li	a5,1
    80004942:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004944:	ffffd097          	auipc	ra,0xffffd
    80004948:	328080e7          	jalr	808(ra) # 80001c6c <myproc>
    8000494c:	591c                	lw	a5,48(a0)
    8000494e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004950:	854a                	mv	a0,s2
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	490080e7          	jalr	1168(ra) # 80000de2 <release>
}
    8000495a:	60e2                	ld	ra,24(sp)
    8000495c:	6442                	ld	s0,16(sp)
    8000495e:	64a2                	ld	s1,8(sp)
    80004960:	6902                	ld	s2,0(sp)
    80004962:	6105                	addi	sp,sp,32
    80004964:	8082                	ret

0000000080004966 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004966:	1101                	addi	sp,sp,-32
    80004968:	ec06                	sd	ra,24(sp)
    8000496a:	e822                	sd	s0,16(sp)
    8000496c:	e426                	sd	s1,8(sp)
    8000496e:	e04a                	sd	s2,0(sp)
    80004970:	1000                	addi	s0,sp,32
    80004972:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004974:	00850913          	addi	s2,a0,8
    80004978:	854a                	mv	a0,s2
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	3b4080e7          	jalr	948(ra) # 80000d2e <acquire>
  lk->locked = 0;
    80004982:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004986:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000498a:	8526                	mv	a0,s1
    8000498c:	ffffe097          	auipc	ra,0xffffe
    80004990:	aac080e7          	jalr	-1364(ra) # 80002438 <wakeup>
  release(&lk->lk);
    80004994:	854a                	mv	a0,s2
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	44c080e7          	jalr	1100(ra) # 80000de2 <release>
}
    8000499e:	60e2                	ld	ra,24(sp)
    800049a0:	6442                	ld	s0,16(sp)
    800049a2:	64a2                	ld	s1,8(sp)
    800049a4:	6902                	ld	s2,0(sp)
    800049a6:	6105                	addi	sp,sp,32
    800049a8:	8082                	ret

00000000800049aa <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049aa:	7179                	addi	sp,sp,-48
    800049ac:	f406                	sd	ra,40(sp)
    800049ae:	f022                	sd	s0,32(sp)
    800049b0:	ec26                	sd	s1,24(sp)
    800049b2:	e84a                	sd	s2,16(sp)
    800049b4:	e44e                	sd	s3,8(sp)
    800049b6:	1800                	addi	s0,sp,48
    800049b8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049ba:	00850913          	addi	s2,a0,8
    800049be:	854a                	mv	a0,s2
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	36e080e7          	jalr	878(ra) # 80000d2e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049c8:	409c                	lw	a5,0(s1)
    800049ca:	ef99                	bnez	a5,800049e8 <holdingsleep+0x3e>
    800049cc:	4481                	li	s1,0
  release(&lk->lk);
    800049ce:	854a                	mv	a0,s2
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	412080e7          	jalr	1042(ra) # 80000de2 <release>
  return r;
}
    800049d8:	8526                	mv	a0,s1
    800049da:	70a2                	ld	ra,40(sp)
    800049dc:	7402                	ld	s0,32(sp)
    800049de:	64e2                	ld	s1,24(sp)
    800049e0:	6942                	ld	s2,16(sp)
    800049e2:	69a2                	ld	s3,8(sp)
    800049e4:	6145                	addi	sp,sp,48
    800049e6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049e8:	0284a983          	lw	s3,40(s1)
    800049ec:	ffffd097          	auipc	ra,0xffffd
    800049f0:	280080e7          	jalr	640(ra) # 80001c6c <myproc>
    800049f4:	5904                	lw	s1,48(a0)
    800049f6:	413484b3          	sub	s1,s1,s3
    800049fa:	0014b493          	seqz	s1,s1
    800049fe:	bfc1                	j	800049ce <holdingsleep+0x24>

0000000080004a00 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a00:	1141                	addi	sp,sp,-16
    80004a02:	e406                	sd	ra,8(sp)
    80004a04:	e022                	sd	s0,0(sp)
    80004a06:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a08:	00004597          	auipc	a1,0x4
    80004a0c:	db058593          	addi	a1,a1,-592 # 800087b8 <syscalls+0x260>
    80004a10:	0023c517          	auipc	a0,0x23c
    80004a14:	3c850513          	addi	a0,a0,968 # 80240dd8 <ftable>
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	286080e7          	jalr	646(ra) # 80000c9e <initlock>
}
    80004a20:	60a2                	ld	ra,8(sp)
    80004a22:	6402                	ld	s0,0(sp)
    80004a24:	0141                	addi	sp,sp,16
    80004a26:	8082                	ret

0000000080004a28 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a28:	1101                	addi	sp,sp,-32
    80004a2a:	ec06                	sd	ra,24(sp)
    80004a2c:	e822                	sd	s0,16(sp)
    80004a2e:	e426                	sd	s1,8(sp)
    80004a30:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a32:	0023c517          	auipc	a0,0x23c
    80004a36:	3a650513          	addi	a0,a0,934 # 80240dd8 <ftable>
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	2f4080e7          	jalr	756(ra) # 80000d2e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a42:	0023c497          	auipc	s1,0x23c
    80004a46:	3ae48493          	addi	s1,s1,942 # 80240df0 <ftable+0x18>
    80004a4a:	0023d717          	auipc	a4,0x23d
    80004a4e:	34670713          	addi	a4,a4,838 # 80241d90 <disk>
    if(f->ref == 0){
    80004a52:	40dc                	lw	a5,4(s1)
    80004a54:	cf99                	beqz	a5,80004a72 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a56:	02848493          	addi	s1,s1,40
    80004a5a:	fee49ce3          	bne	s1,a4,80004a52 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a5e:	0023c517          	auipc	a0,0x23c
    80004a62:	37a50513          	addi	a0,a0,890 # 80240dd8 <ftable>
    80004a66:	ffffc097          	auipc	ra,0xffffc
    80004a6a:	37c080e7          	jalr	892(ra) # 80000de2 <release>
  return 0;
    80004a6e:	4481                	li	s1,0
    80004a70:	a819                	j	80004a86 <filealloc+0x5e>
      f->ref = 1;
    80004a72:	4785                	li	a5,1
    80004a74:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a76:	0023c517          	auipc	a0,0x23c
    80004a7a:	36250513          	addi	a0,a0,866 # 80240dd8 <ftable>
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	364080e7          	jalr	868(ra) # 80000de2 <release>
}
    80004a86:	8526                	mv	a0,s1
    80004a88:	60e2                	ld	ra,24(sp)
    80004a8a:	6442                	ld	s0,16(sp)
    80004a8c:	64a2                	ld	s1,8(sp)
    80004a8e:	6105                	addi	sp,sp,32
    80004a90:	8082                	ret

0000000080004a92 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a92:	1101                	addi	sp,sp,-32
    80004a94:	ec06                	sd	ra,24(sp)
    80004a96:	e822                	sd	s0,16(sp)
    80004a98:	e426                	sd	s1,8(sp)
    80004a9a:	1000                	addi	s0,sp,32
    80004a9c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a9e:	0023c517          	auipc	a0,0x23c
    80004aa2:	33a50513          	addi	a0,a0,826 # 80240dd8 <ftable>
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	288080e7          	jalr	648(ra) # 80000d2e <acquire>
  if(f->ref < 1)
    80004aae:	40dc                	lw	a5,4(s1)
    80004ab0:	02f05263          	blez	a5,80004ad4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ab4:	2785                	addiw	a5,a5,1
    80004ab6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ab8:	0023c517          	auipc	a0,0x23c
    80004abc:	32050513          	addi	a0,a0,800 # 80240dd8 <ftable>
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	322080e7          	jalr	802(ra) # 80000de2 <release>
  return f;
}
    80004ac8:	8526                	mv	a0,s1
    80004aca:	60e2                	ld	ra,24(sp)
    80004acc:	6442                	ld	s0,16(sp)
    80004ace:	64a2                	ld	s1,8(sp)
    80004ad0:	6105                	addi	sp,sp,32
    80004ad2:	8082                	ret
    panic("filedup");
    80004ad4:	00004517          	auipc	a0,0x4
    80004ad8:	cec50513          	addi	a0,a0,-788 # 800087c0 <syscalls+0x268>
    80004adc:	ffffc097          	auipc	ra,0xffffc
    80004ae0:	a64080e7          	jalr	-1436(ra) # 80000540 <panic>

0000000080004ae4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ae4:	7139                	addi	sp,sp,-64
    80004ae6:	fc06                	sd	ra,56(sp)
    80004ae8:	f822                	sd	s0,48(sp)
    80004aea:	f426                	sd	s1,40(sp)
    80004aec:	f04a                	sd	s2,32(sp)
    80004aee:	ec4e                	sd	s3,24(sp)
    80004af0:	e852                	sd	s4,16(sp)
    80004af2:	e456                	sd	s5,8(sp)
    80004af4:	0080                	addi	s0,sp,64
    80004af6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004af8:	0023c517          	auipc	a0,0x23c
    80004afc:	2e050513          	addi	a0,a0,736 # 80240dd8 <ftable>
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	22e080e7          	jalr	558(ra) # 80000d2e <acquire>
  if(f->ref < 1)
    80004b08:	40dc                	lw	a5,4(s1)
    80004b0a:	06f05163          	blez	a5,80004b6c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b0e:	37fd                	addiw	a5,a5,-1
    80004b10:	0007871b          	sext.w	a4,a5
    80004b14:	c0dc                	sw	a5,4(s1)
    80004b16:	06e04363          	bgtz	a4,80004b7c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b1a:	0004a903          	lw	s2,0(s1)
    80004b1e:	0094ca83          	lbu	s5,9(s1)
    80004b22:	0104ba03          	ld	s4,16(s1)
    80004b26:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b2a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b2e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b32:	0023c517          	auipc	a0,0x23c
    80004b36:	2a650513          	addi	a0,a0,678 # 80240dd8 <ftable>
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	2a8080e7          	jalr	680(ra) # 80000de2 <release>

  if(ff.type == FD_PIPE){
    80004b42:	4785                	li	a5,1
    80004b44:	04f90d63          	beq	s2,a5,80004b9e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b48:	3979                	addiw	s2,s2,-2
    80004b4a:	4785                	li	a5,1
    80004b4c:	0527e063          	bltu	a5,s2,80004b8c <fileclose+0xa8>
    begin_op();
    80004b50:	00000097          	auipc	ra,0x0
    80004b54:	acc080e7          	jalr	-1332(ra) # 8000461c <begin_op>
    iput(ff.ip);
    80004b58:	854e                	mv	a0,s3
    80004b5a:	fffff097          	auipc	ra,0xfffff
    80004b5e:	2b0080e7          	jalr	688(ra) # 80003e0a <iput>
    end_op();
    80004b62:	00000097          	auipc	ra,0x0
    80004b66:	b38080e7          	jalr	-1224(ra) # 8000469a <end_op>
    80004b6a:	a00d                	j	80004b8c <fileclose+0xa8>
    panic("fileclose");
    80004b6c:	00004517          	auipc	a0,0x4
    80004b70:	c5c50513          	addi	a0,a0,-932 # 800087c8 <syscalls+0x270>
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	9cc080e7          	jalr	-1588(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004b7c:	0023c517          	auipc	a0,0x23c
    80004b80:	25c50513          	addi	a0,a0,604 # 80240dd8 <ftable>
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	25e080e7          	jalr	606(ra) # 80000de2 <release>
  }
}
    80004b8c:	70e2                	ld	ra,56(sp)
    80004b8e:	7442                	ld	s0,48(sp)
    80004b90:	74a2                	ld	s1,40(sp)
    80004b92:	7902                	ld	s2,32(sp)
    80004b94:	69e2                	ld	s3,24(sp)
    80004b96:	6a42                	ld	s4,16(sp)
    80004b98:	6aa2                	ld	s5,8(sp)
    80004b9a:	6121                	addi	sp,sp,64
    80004b9c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b9e:	85d6                	mv	a1,s5
    80004ba0:	8552                	mv	a0,s4
    80004ba2:	00000097          	auipc	ra,0x0
    80004ba6:	34c080e7          	jalr	844(ra) # 80004eee <pipeclose>
    80004baa:	b7cd                	j	80004b8c <fileclose+0xa8>

0000000080004bac <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bac:	715d                	addi	sp,sp,-80
    80004bae:	e486                	sd	ra,72(sp)
    80004bb0:	e0a2                	sd	s0,64(sp)
    80004bb2:	fc26                	sd	s1,56(sp)
    80004bb4:	f84a                	sd	s2,48(sp)
    80004bb6:	f44e                	sd	s3,40(sp)
    80004bb8:	0880                	addi	s0,sp,80
    80004bba:	84aa                	mv	s1,a0
    80004bbc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	0ae080e7          	jalr	174(ra) # 80001c6c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004bc6:	409c                	lw	a5,0(s1)
    80004bc8:	37f9                	addiw	a5,a5,-2
    80004bca:	4705                	li	a4,1
    80004bcc:	04f76763          	bltu	a4,a5,80004c1a <filestat+0x6e>
    80004bd0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bd2:	6c88                	ld	a0,24(s1)
    80004bd4:	fffff097          	auipc	ra,0xfffff
    80004bd8:	07c080e7          	jalr	124(ra) # 80003c50 <ilock>
    stati(f->ip, &st);
    80004bdc:	fb840593          	addi	a1,s0,-72
    80004be0:	6c88                	ld	a0,24(s1)
    80004be2:	fffff097          	auipc	ra,0xfffff
    80004be6:	2f8080e7          	jalr	760(ra) # 80003eda <stati>
    iunlock(f->ip);
    80004bea:	6c88                	ld	a0,24(s1)
    80004bec:	fffff097          	auipc	ra,0xfffff
    80004bf0:	126080e7          	jalr	294(ra) # 80003d12 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bf4:	46e1                	li	a3,24
    80004bf6:	fb840613          	addi	a2,s0,-72
    80004bfa:	85ce                	mv	a1,s3
    80004bfc:	05093503          	ld	a0,80(s2)
    80004c00:	ffffd097          	auipc	ra,0xffffd
    80004c04:	baa080e7          	jalr	-1110(ra) # 800017aa <copyout>
    80004c08:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c0c:	60a6                	ld	ra,72(sp)
    80004c0e:	6406                	ld	s0,64(sp)
    80004c10:	74e2                	ld	s1,56(sp)
    80004c12:	7942                	ld	s2,48(sp)
    80004c14:	79a2                	ld	s3,40(sp)
    80004c16:	6161                	addi	sp,sp,80
    80004c18:	8082                	ret
  return -1;
    80004c1a:	557d                	li	a0,-1
    80004c1c:	bfc5                	j	80004c0c <filestat+0x60>

0000000080004c1e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c1e:	7179                	addi	sp,sp,-48
    80004c20:	f406                	sd	ra,40(sp)
    80004c22:	f022                	sd	s0,32(sp)
    80004c24:	ec26                	sd	s1,24(sp)
    80004c26:	e84a                	sd	s2,16(sp)
    80004c28:	e44e                	sd	s3,8(sp)
    80004c2a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c2c:	00854783          	lbu	a5,8(a0)
    80004c30:	c3d5                	beqz	a5,80004cd4 <fileread+0xb6>
    80004c32:	84aa                	mv	s1,a0
    80004c34:	89ae                	mv	s3,a1
    80004c36:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c38:	411c                	lw	a5,0(a0)
    80004c3a:	4705                	li	a4,1
    80004c3c:	04e78963          	beq	a5,a4,80004c8e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c40:	470d                	li	a4,3
    80004c42:	04e78d63          	beq	a5,a4,80004c9c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c46:	4709                	li	a4,2
    80004c48:	06e79e63          	bne	a5,a4,80004cc4 <fileread+0xa6>
    ilock(f->ip);
    80004c4c:	6d08                	ld	a0,24(a0)
    80004c4e:	fffff097          	auipc	ra,0xfffff
    80004c52:	002080e7          	jalr	2(ra) # 80003c50 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c56:	874a                	mv	a4,s2
    80004c58:	5094                	lw	a3,32(s1)
    80004c5a:	864e                	mv	a2,s3
    80004c5c:	4585                	li	a1,1
    80004c5e:	6c88                	ld	a0,24(s1)
    80004c60:	fffff097          	auipc	ra,0xfffff
    80004c64:	2a4080e7          	jalr	676(ra) # 80003f04 <readi>
    80004c68:	892a                	mv	s2,a0
    80004c6a:	00a05563          	blez	a0,80004c74 <fileread+0x56>
      f->off += r;
    80004c6e:	509c                	lw	a5,32(s1)
    80004c70:	9fa9                	addw	a5,a5,a0
    80004c72:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c74:	6c88                	ld	a0,24(s1)
    80004c76:	fffff097          	auipc	ra,0xfffff
    80004c7a:	09c080e7          	jalr	156(ra) # 80003d12 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c7e:	854a                	mv	a0,s2
    80004c80:	70a2                	ld	ra,40(sp)
    80004c82:	7402                	ld	s0,32(sp)
    80004c84:	64e2                	ld	s1,24(sp)
    80004c86:	6942                	ld	s2,16(sp)
    80004c88:	69a2                	ld	s3,8(sp)
    80004c8a:	6145                	addi	sp,sp,48
    80004c8c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c8e:	6908                	ld	a0,16(a0)
    80004c90:	00000097          	auipc	ra,0x0
    80004c94:	3c6080e7          	jalr	966(ra) # 80005056 <piperead>
    80004c98:	892a                	mv	s2,a0
    80004c9a:	b7d5                	j	80004c7e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c9c:	02451783          	lh	a5,36(a0)
    80004ca0:	03079693          	slli	a3,a5,0x30
    80004ca4:	92c1                	srli	a3,a3,0x30
    80004ca6:	4725                	li	a4,9
    80004ca8:	02d76863          	bltu	a4,a3,80004cd8 <fileread+0xba>
    80004cac:	0792                	slli	a5,a5,0x4
    80004cae:	0023c717          	auipc	a4,0x23c
    80004cb2:	08a70713          	addi	a4,a4,138 # 80240d38 <devsw>
    80004cb6:	97ba                	add	a5,a5,a4
    80004cb8:	639c                	ld	a5,0(a5)
    80004cba:	c38d                	beqz	a5,80004cdc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cbc:	4505                	li	a0,1
    80004cbe:	9782                	jalr	a5
    80004cc0:	892a                	mv	s2,a0
    80004cc2:	bf75                	j	80004c7e <fileread+0x60>
    panic("fileread");
    80004cc4:	00004517          	auipc	a0,0x4
    80004cc8:	b1450513          	addi	a0,a0,-1260 # 800087d8 <syscalls+0x280>
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	874080e7          	jalr	-1932(ra) # 80000540 <panic>
    return -1;
    80004cd4:	597d                	li	s2,-1
    80004cd6:	b765                	j	80004c7e <fileread+0x60>
      return -1;
    80004cd8:	597d                	li	s2,-1
    80004cda:	b755                	j	80004c7e <fileread+0x60>
    80004cdc:	597d                	li	s2,-1
    80004cde:	b745                	j	80004c7e <fileread+0x60>

0000000080004ce0 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ce0:	715d                	addi	sp,sp,-80
    80004ce2:	e486                	sd	ra,72(sp)
    80004ce4:	e0a2                	sd	s0,64(sp)
    80004ce6:	fc26                	sd	s1,56(sp)
    80004ce8:	f84a                	sd	s2,48(sp)
    80004cea:	f44e                	sd	s3,40(sp)
    80004cec:	f052                	sd	s4,32(sp)
    80004cee:	ec56                	sd	s5,24(sp)
    80004cf0:	e85a                	sd	s6,16(sp)
    80004cf2:	e45e                	sd	s7,8(sp)
    80004cf4:	e062                	sd	s8,0(sp)
    80004cf6:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cf8:	00954783          	lbu	a5,9(a0)
    80004cfc:	10078663          	beqz	a5,80004e08 <filewrite+0x128>
    80004d00:	892a                	mv	s2,a0
    80004d02:	8b2e                	mv	s6,a1
    80004d04:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d06:	411c                	lw	a5,0(a0)
    80004d08:	4705                	li	a4,1
    80004d0a:	02e78263          	beq	a5,a4,80004d2e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d0e:	470d                	li	a4,3
    80004d10:	02e78663          	beq	a5,a4,80004d3c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d14:	4709                	li	a4,2
    80004d16:	0ee79163          	bne	a5,a4,80004df8 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d1a:	0ac05d63          	blez	a2,80004dd4 <filewrite+0xf4>
    int i = 0;
    80004d1e:	4981                	li	s3,0
    80004d20:	6b85                	lui	s7,0x1
    80004d22:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004d26:	6c05                	lui	s8,0x1
    80004d28:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004d2c:	a861                	j	80004dc4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004d2e:	6908                	ld	a0,16(a0)
    80004d30:	00000097          	auipc	ra,0x0
    80004d34:	22e080e7          	jalr	558(ra) # 80004f5e <pipewrite>
    80004d38:	8a2a                	mv	s4,a0
    80004d3a:	a045                	j	80004dda <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d3c:	02451783          	lh	a5,36(a0)
    80004d40:	03079693          	slli	a3,a5,0x30
    80004d44:	92c1                	srli	a3,a3,0x30
    80004d46:	4725                	li	a4,9
    80004d48:	0cd76263          	bltu	a4,a3,80004e0c <filewrite+0x12c>
    80004d4c:	0792                	slli	a5,a5,0x4
    80004d4e:	0023c717          	auipc	a4,0x23c
    80004d52:	fea70713          	addi	a4,a4,-22 # 80240d38 <devsw>
    80004d56:	97ba                	add	a5,a5,a4
    80004d58:	679c                	ld	a5,8(a5)
    80004d5a:	cbdd                	beqz	a5,80004e10 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d5c:	4505                	li	a0,1
    80004d5e:	9782                	jalr	a5
    80004d60:	8a2a                	mv	s4,a0
    80004d62:	a8a5                	j	80004dda <filewrite+0xfa>
    80004d64:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d68:	00000097          	auipc	ra,0x0
    80004d6c:	8b4080e7          	jalr	-1868(ra) # 8000461c <begin_op>
      ilock(f->ip);
    80004d70:	01893503          	ld	a0,24(s2)
    80004d74:	fffff097          	auipc	ra,0xfffff
    80004d78:	edc080e7          	jalr	-292(ra) # 80003c50 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d7c:	8756                	mv	a4,s5
    80004d7e:	02092683          	lw	a3,32(s2)
    80004d82:	01698633          	add	a2,s3,s6
    80004d86:	4585                	li	a1,1
    80004d88:	01893503          	ld	a0,24(s2)
    80004d8c:	fffff097          	auipc	ra,0xfffff
    80004d90:	270080e7          	jalr	624(ra) # 80003ffc <writei>
    80004d94:	84aa                	mv	s1,a0
    80004d96:	00a05763          	blez	a0,80004da4 <filewrite+0xc4>
        f->off += r;
    80004d9a:	02092783          	lw	a5,32(s2)
    80004d9e:	9fa9                	addw	a5,a5,a0
    80004da0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004da4:	01893503          	ld	a0,24(s2)
    80004da8:	fffff097          	auipc	ra,0xfffff
    80004dac:	f6a080e7          	jalr	-150(ra) # 80003d12 <iunlock>
      end_op();
    80004db0:	00000097          	auipc	ra,0x0
    80004db4:	8ea080e7          	jalr	-1814(ra) # 8000469a <end_op>

      if(r != n1){
    80004db8:	009a9f63          	bne	s5,s1,80004dd6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004dbc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004dc0:	0149db63          	bge	s3,s4,80004dd6 <filewrite+0xf6>
      int n1 = n - i;
    80004dc4:	413a04bb          	subw	s1,s4,s3
    80004dc8:	0004879b          	sext.w	a5,s1
    80004dcc:	f8fbdce3          	bge	s7,a5,80004d64 <filewrite+0x84>
    80004dd0:	84e2                	mv	s1,s8
    80004dd2:	bf49                	j	80004d64 <filewrite+0x84>
    int i = 0;
    80004dd4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004dd6:	013a1f63          	bne	s4,s3,80004df4 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004dda:	8552                	mv	a0,s4
    80004ddc:	60a6                	ld	ra,72(sp)
    80004dde:	6406                	ld	s0,64(sp)
    80004de0:	74e2                	ld	s1,56(sp)
    80004de2:	7942                	ld	s2,48(sp)
    80004de4:	79a2                	ld	s3,40(sp)
    80004de6:	7a02                	ld	s4,32(sp)
    80004de8:	6ae2                	ld	s5,24(sp)
    80004dea:	6b42                	ld	s6,16(sp)
    80004dec:	6ba2                	ld	s7,8(sp)
    80004dee:	6c02                	ld	s8,0(sp)
    80004df0:	6161                	addi	sp,sp,80
    80004df2:	8082                	ret
    ret = (i == n ? n : -1);
    80004df4:	5a7d                	li	s4,-1
    80004df6:	b7d5                	j	80004dda <filewrite+0xfa>
    panic("filewrite");
    80004df8:	00004517          	auipc	a0,0x4
    80004dfc:	9f050513          	addi	a0,a0,-1552 # 800087e8 <syscalls+0x290>
    80004e00:	ffffb097          	auipc	ra,0xffffb
    80004e04:	740080e7          	jalr	1856(ra) # 80000540 <panic>
    return -1;
    80004e08:	5a7d                	li	s4,-1
    80004e0a:	bfc1                	j	80004dda <filewrite+0xfa>
      return -1;
    80004e0c:	5a7d                	li	s4,-1
    80004e0e:	b7f1                	j	80004dda <filewrite+0xfa>
    80004e10:	5a7d                	li	s4,-1
    80004e12:	b7e1                	j	80004dda <filewrite+0xfa>

0000000080004e14 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e14:	7179                	addi	sp,sp,-48
    80004e16:	f406                	sd	ra,40(sp)
    80004e18:	f022                	sd	s0,32(sp)
    80004e1a:	ec26                	sd	s1,24(sp)
    80004e1c:	e84a                	sd	s2,16(sp)
    80004e1e:	e44e                	sd	s3,8(sp)
    80004e20:	e052                	sd	s4,0(sp)
    80004e22:	1800                	addi	s0,sp,48
    80004e24:	84aa                	mv	s1,a0
    80004e26:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e28:	0005b023          	sd	zero,0(a1)
    80004e2c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e30:	00000097          	auipc	ra,0x0
    80004e34:	bf8080e7          	jalr	-1032(ra) # 80004a28 <filealloc>
    80004e38:	e088                	sd	a0,0(s1)
    80004e3a:	c551                	beqz	a0,80004ec6 <pipealloc+0xb2>
    80004e3c:	00000097          	auipc	ra,0x0
    80004e40:	bec080e7          	jalr	-1044(ra) # 80004a28 <filealloc>
    80004e44:	00aa3023          	sd	a0,0(s4)
    80004e48:	c92d                	beqz	a0,80004eba <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e4a:	ffffc097          	auipc	ra,0xffffc
    80004e4e:	d44080e7          	jalr	-700(ra) # 80000b8e <kalloc>
    80004e52:	892a                	mv	s2,a0
    80004e54:	c125                	beqz	a0,80004eb4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e56:	4985                	li	s3,1
    80004e58:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e5c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e60:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e64:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e68:	00004597          	auipc	a1,0x4
    80004e6c:	99058593          	addi	a1,a1,-1648 # 800087f8 <syscalls+0x2a0>
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	e2e080e7          	jalr	-466(ra) # 80000c9e <initlock>
  (*f0)->type = FD_PIPE;
    80004e78:	609c                	ld	a5,0(s1)
    80004e7a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e7e:	609c                	ld	a5,0(s1)
    80004e80:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e84:	609c                	ld	a5,0(s1)
    80004e86:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e8a:	609c                	ld	a5,0(s1)
    80004e8c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e90:	000a3783          	ld	a5,0(s4)
    80004e94:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e98:	000a3783          	ld	a5,0(s4)
    80004e9c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ea0:	000a3783          	ld	a5,0(s4)
    80004ea4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ea8:	000a3783          	ld	a5,0(s4)
    80004eac:	0127b823          	sd	s2,16(a5)
  return 0;
    80004eb0:	4501                	li	a0,0
    80004eb2:	a025                	j	80004eda <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004eb4:	6088                	ld	a0,0(s1)
    80004eb6:	e501                	bnez	a0,80004ebe <pipealloc+0xaa>
    80004eb8:	a039                	j	80004ec6 <pipealloc+0xb2>
    80004eba:	6088                	ld	a0,0(s1)
    80004ebc:	c51d                	beqz	a0,80004eea <pipealloc+0xd6>
    fileclose(*f0);
    80004ebe:	00000097          	auipc	ra,0x0
    80004ec2:	c26080e7          	jalr	-986(ra) # 80004ae4 <fileclose>
  if(*f1)
    80004ec6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004eca:	557d                	li	a0,-1
  if(*f1)
    80004ecc:	c799                	beqz	a5,80004eda <pipealloc+0xc6>
    fileclose(*f1);
    80004ece:	853e                	mv	a0,a5
    80004ed0:	00000097          	auipc	ra,0x0
    80004ed4:	c14080e7          	jalr	-1004(ra) # 80004ae4 <fileclose>
  return -1;
    80004ed8:	557d                	li	a0,-1
}
    80004eda:	70a2                	ld	ra,40(sp)
    80004edc:	7402                	ld	s0,32(sp)
    80004ede:	64e2                	ld	s1,24(sp)
    80004ee0:	6942                	ld	s2,16(sp)
    80004ee2:	69a2                	ld	s3,8(sp)
    80004ee4:	6a02                	ld	s4,0(sp)
    80004ee6:	6145                	addi	sp,sp,48
    80004ee8:	8082                	ret
  return -1;
    80004eea:	557d                	li	a0,-1
    80004eec:	b7fd                	j	80004eda <pipealloc+0xc6>

0000000080004eee <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004eee:	1101                	addi	sp,sp,-32
    80004ef0:	ec06                	sd	ra,24(sp)
    80004ef2:	e822                	sd	s0,16(sp)
    80004ef4:	e426                	sd	s1,8(sp)
    80004ef6:	e04a                	sd	s2,0(sp)
    80004ef8:	1000                	addi	s0,sp,32
    80004efa:	84aa                	mv	s1,a0
    80004efc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	e30080e7          	jalr	-464(ra) # 80000d2e <acquire>
  if(writable){
    80004f06:	02090d63          	beqz	s2,80004f40 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f0a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f0e:	21848513          	addi	a0,s1,536
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	526080e7          	jalr	1318(ra) # 80002438 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f1a:	2204b783          	ld	a5,544(s1)
    80004f1e:	eb95                	bnez	a5,80004f52 <pipeclose+0x64>
    release(&pi->lock);
    80004f20:	8526                	mv	a0,s1
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	ec0080e7          	jalr	-320(ra) # 80000de2 <release>
    kfree((char*)pi);
    80004f2a:	8526                	mv	a0,s1
    80004f2c:	ffffc097          	auipc	ra,0xffffc
    80004f30:	ace080e7          	jalr	-1330(ra) # 800009fa <kfree>
  } else
    release(&pi->lock);
}
    80004f34:	60e2                	ld	ra,24(sp)
    80004f36:	6442                	ld	s0,16(sp)
    80004f38:	64a2                	ld	s1,8(sp)
    80004f3a:	6902                	ld	s2,0(sp)
    80004f3c:	6105                	addi	sp,sp,32
    80004f3e:	8082                	ret
    pi->readopen = 0;
    80004f40:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f44:	21c48513          	addi	a0,s1,540
    80004f48:	ffffd097          	auipc	ra,0xffffd
    80004f4c:	4f0080e7          	jalr	1264(ra) # 80002438 <wakeup>
    80004f50:	b7e9                	j	80004f1a <pipeclose+0x2c>
    release(&pi->lock);
    80004f52:	8526                	mv	a0,s1
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	e8e080e7          	jalr	-370(ra) # 80000de2 <release>
}
    80004f5c:	bfe1                	j	80004f34 <pipeclose+0x46>

0000000080004f5e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f5e:	711d                	addi	sp,sp,-96
    80004f60:	ec86                	sd	ra,88(sp)
    80004f62:	e8a2                	sd	s0,80(sp)
    80004f64:	e4a6                	sd	s1,72(sp)
    80004f66:	e0ca                	sd	s2,64(sp)
    80004f68:	fc4e                	sd	s3,56(sp)
    80004f6a:	f852                	sd	s4,48(sp)
    80004f6c:	f456                	sd	s5,40(sp)
    80004f6e:	f05a                	sd	s6,32(sp)
    80004f70:	ec5e                	sd	s7,24(sp)
    80004f72:	e862                	sd	s8,16(sp)
    80004f74:	1080                	addi	s0,sp,96
    80004f76:	84aa                	mv	s1,a0
    80004f78:	8aae                	mv	s5,a1
    80004f7a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	cf0080e7          	jalr	-784(ra) # 80001c6c <myproc>
    80004f84:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f86:	8526                	mv	a0,s1
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	da6080e7          	jalr	-602(ra) # 80000d2e <acquire>
  while(i < n){
    80004f90:	0b405663          	blez	s4,8000503c <pipewrite+0xde>
  int i = 0;
    80004f94:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f96:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f98:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f9c:	21c48b93          	addi	s7,s1,540
    80004fa0:	a089                	j	80004fe2 <pipewrite+0x84>
      release(&pi->lock);
    80004fa2:	8526                	mv	a0,s1
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	e3e080e7          	jalr	-450(ra) # 80000de2 <release>
      return -1;
    80004fac:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fae:	854a                	mv	a0,s2
    80004fb0:	60e6                	ld	ra,88(sp)
    80004fb2:	6446                	ld	s0,80(sp)
    80004fb4:	64a6                	ld	s1,72(sp)
    80004fb6:	6906                	ld	s2,64(sp)
    80004fb8:	79e2                	ld	s3,56(sp)
    80004fba:	7a42                	ld	s4,48(sp)
    80004fbc:	7aa2                	ld	s5,40(sp)
    80004fbe:	7b02                	ld	s6,32(sp)
    80004fc0:	6be2                	ld	s7,24(sp)
    80004fc2:	6c42                	ld	s8,16(sp)
    80004fc4:	6125                	addi	sp,sp,96
    80004fc6:	8082                	ret
      wakeup(&pi->nread);
    80004fc8:	8562                	mv	a0,s8
    80004fca:	ffffd097          	auipc	ra,0xffffd
    80004fce:	46e080e7          	jalr	1134(ra) # 80002438 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fd2:	85a6                	mv	a1,s1
    80004fd4:	855e                	mv	a0,s7
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	3fe080e7          	jalr	1022(ra) # 800023d4 <sleep>
  while(i < n){
    80004fde:	07495063          	bge	s2,s4,8000503e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004fe2:	2204a783          	lw	a5,544(s1)
    80004fe6:	dfd5                	beqz	a5,80004fa2 <pipewrite+0x44>
    80004fe8:	854e                	mv	a0,s3
    80004fea:	ffffd097          	auipc	ra,0xffffd
    80004fee:	692080e7          	jalr	1682(ra) # 8000267c <killed>
    80004ff2:	f945                	bnez	a0,80004fa2 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ff4:	2184a783          	lw	a5,536(s1)
    80004ff8:	21c4a703          	lw	a4,540(s1)
    80004ffc:	2007879b          	addiw	a5,a5,512
    80005000:	fcf704e3          	beq	a4,a5,80004fc8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005004:	4685                	li	a3,1
    80005006:	01590633          	add	a2,s2,s5
    8000500a:	faf40593          	addi	a1,s0,-81
    8000500e:	0509b503          	ld	a0,80(s3)
    80005012:	ffffd097          	auipc	ra,0xffffd
    80005016:	824080e7          	jalr	-2012(ra) # 80001836 <copyin>
    8000501a:	03650263          	beq	a0,s6,8000503e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000501e:	21c4a783          	lw	a5,540(s1)
    80005022:	0017871b          	addiw	a4,a5,1
    80005026:	20e4ae23          	sw	a4,540(s1)
    8000502a:	1ff7f793          	andi	a5,a5,511
    8000502e:	97a6                	add	a5,a5,s1
    80005030:	faf44703          	lbu	a4,-81(s0)
    80005034:	00e78c23          	sb	a4,24(a5)
      i++;
    80005038:	2905                	addiw	s2,s2,1
    8000503a:	b755                	j	80004fde <pipewrite+0x80>
  int i = 0;
    8000503c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000503e:	21848513          	addi	a0,s1,536
    80005042:	ffffd097          	auipc	ra,0xffffd
    80005046:	3f6080e7          	jalr	1014(ra) # 80002438 <wakeup>
  release(&pi->lock);
    8000504a:	8526                	mv	a0,s1
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	d96080e7          	jalr	-618(ra) # 80000de2 <release>
  return i;
    80005054:	bfa9                	j	80004fae <pipewrite+0x50>

0000000080005056 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005056:	715d                	addi	sp,sp,-80
    80005058:	e486                	sd	ra,72(sp)
    8000505a:	e0a2                	sd	s0,64(sp)
    8000505c:	fc26                	sd	s1,56(sp)
    8000505e:	f84a                	sd	s2,48(sp)
    80005060:	f44e                	sd	s3,40(sp)
    80005062:	f052                	sd	s4,32(sp)
    80005064:	ec56                	sd	s5,24(sp)
    80005066:	e85a                	sd	s6,16(sp)
    80005068:	0880                	addi	s0,sp,80
    8000506a:	84aa                	mv	s1,a0
    8000506c:	892e                	mv	s2,a1
    8000506e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005070:	ffffd097          	auipc	ra,0xffffd
    80005074:	bfc080e7          	jalr	-1028(ra) # 80001c6c <myproc>
    80005078:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000507a:	8526                	mv	a0,s1
    8000507c:	ffffc097          	auipc	ra,0xffffc
    80005080:	cb2080e7          	jalr	-846(ra) # 80000d2e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005084:	2184a703          	lw	a4,536(s1)
    80005088:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000508c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005090:	02f71763          	bne	a4,a5,800050be <piperead+0x68>
    80005094:	2244a783          	lw	a5,548(s1)
    80005098:	c39d                	beqz	a5,800050be <piperead+0x68>
    if(killed(pr)){
    8000509a:	8552                	mv	a0,s4
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	5e0080e7          	jalr	1504(ra) # 8000267c <killed>
    800050a4:	e949                	bnez	a0,80005136 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050a6:	85a6                	mv	a1,s1
    800050a8:	854e                	mv	a0,s3
    800050aa:	ffffd097          	auipc	ra,0xffffd
    800050ae:	32a080e7          	jalr	810(ra) # 800023d4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050b2:	2184a703          	lw	a4,536(s1)
    800050b6:	21c4a783          	lw	a5,540(s1)
    800050ba:	fcf70de3          	beq	a4,a5,80005094 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050be:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050c0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050c2:	05505463          	blez	s5,8000510a <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800050c6:	2184a783          	lw	a5,536(s1)
    800050ca:	21c4a703          	lw	a4,540(s1)
    800050ce:	02f70e63          	beq	a4,a5,8000510a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050d2:	0017871b          	addiw	a4,a5,1
    800050d6:	20e4ac23          	sw	a4,536(s1)
    800050da:	1ff7f793          	andi	a5,a5,511
    800050de:	97a6                	add	a5,a5,s1
    800050e0:	0187c783          	lbu	a5,24(a5)
    800050e4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050e8:	4685                	li	a3,1
    800050ea:	fbf40613          	addi	a2,s0,-65
    800050ee:	85ca                	mv	a1,s2
    800050f0:	050a3503          	ld	a0,80(s4)
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	6b6080e7          	jalr	1718(ra) # 800017aa <copyout>
    800050fc:	01650763          	beq	a0,s6,8000510a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005100:	2985                	addiw	s3,s3,1
    80005102:	0905                	addi	s2,s2,1
    80005104:	fd3a91e3          	bne	s5,s3,800050c6 <piperead+0x70>
    80005108:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000510a:	21c48513          	addi	a0,s1,540
    8000510e:	ffffd097          	auipc	ra,0xffffd
    80005112:	32a080e7          	jalr	810(ra) # 80002438 <wakeup>
  release(&pi->lock);
    80005116:	8526                	mv	a0,s1
    80005118:	ffffc097          	auipc	ra,0xffffc
    8000511c:	cca080e7          	jalr	-822(ra) # 80000de2 <release>
  return i;
}
    80005120:	854e                	mv	a0,s3
    80005122:	60a6                	ld	ra,72(sp)
    80005124:	6406                	ld	s0,64(sp)
    80005126:	74e2                	ld	s1,56(sp)
    80005128:	7942                	ld	s2,48(sp)
    8000512a:	79a2                	ld	s3,40(sp)
    8000512c:	7a02                	ld	s4,32(sp)
    8000512e:	6ae2                	ld	s5,24(sp)
    80005130:	6b42                	ld	s6,16(sp)
    80005132:	6161                	addi	sp,sp,80
    80005134:	8082                	ret
      release(&pi->lock);
    80005136:	8526                	mv	a0,s1
    80005138:	ffffc097          	auipc	ra,0xffffc
    8000513c:	caa080e7          	jalr	-854(ra) # 80000de2 <release>
      return -1;
    80005140:	59fd                	li	s3,-1
    80005142:	bff9                	j	80005120 <piperead+0xca>

0000000080005144 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005144:	1141                	addi	sp,sp,-16
    80005146:	e422                	sd	s0,8(sp)
    80005148:	0800                	addi	s0,sp,16
    8000514a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000514c:	8905                	andi	a0,a0,1
    8000514e:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005150:	8b89                	andi	a5,a5,2
    80005152:	c399                	beqz	a5,80005158 <flags2perm+0x14>
      perm |= PTE_W;
    80005154:	00456513          	ori	a0,a0,4
    return perm;
}
    80005158:	6422                	ld	s0,8(sp)
    8000515a:	0141                	addi	sp,sp,16
    8000515c:	8082                	ret

000000008000515e <exec>:

int
exec(char *path, char **argv)
{
    8000515e:	de010113          	addi	sp,sp,-544
    80005162:	20113c23          	sd	ra,536(sp)
    80005166:	20813823          	sd	s0,528(sp)
    8000516a:	20913423          	sd	s1,520(sp)
    8000516e:	21213023          	sd	s2,512(sp)
    80005172:	ffce                	sd	s3,504(sp)
    80005174:	fbd2                	sd	s4,496(sp)
    80005176:	f7d6                	sd	s5,488(sp)
    80005178:	f3da                	sd	s6,480(sp)
    8000517a:	efde                	sd	s7,472(sp)
    8000517c:	ebe2                	sd	s8,464(sp)
    8000517e:	e7e6                	sd	s9,456(sp)
    80005180:	e3ea                	sd	s10,448(sp)
    80005182:	ff6e                	sd	s11,440(sp)
    80005184:	1400                	addi	s0,sp,544
    80005186:	892a                	mv	s2,a0
    80005188:	dea43423          	sd	a0,-536(s0)
    8000518c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	adc080e7          	jalr	-1316(ra) # 80001c6c <myproc>
    80005198:	84aa                	mv	s1,a0

  begin_op();
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	482080e7          	jalr	1154(ra) # 8000461c <begin_op>

  if((ip = namei(path)) == 0){
    800051a2:	854a                	mv	a0,s2
    800051a4:	fffff097          	auipc	ra,0xfffff
    800051a8:	258080e7          	jalr	600(ra) # 800043fc <namei>
    800051ac:	c93d                	beqz	a0,80005222 <exec+0xc4>
    800051ae:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	aa0080e7          	jalr	-1376(ra) # 80003c50 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051b8:	04000713          	li	a4,64
    800051bc:	4681                	li	a3,0
    800051be:	e5040613          	addi	a2,s0,-432
    800051c2:	4581                	li	a1,0
    800051c4:	8556                	mv	a0,s5
    800051c6:	fffff097          	auipc	ra,0xfffff
    800051ca:	d3e080e7          	jalr	-706(ra) # 80003f04 <readi>
    800051ce:	04000793          	li	a5,64
    800051d2:	00f51a63          	bne	a0,a5,800051e6 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800051d6:	e5042703          	lw	a4,-432(s0)
    800051da:	464c47b7          	lui	a5,0x464c4
    800051de:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051e2:	04f70663          	beq	a4,a5,8000522e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051e6:	8556                	mv	a0,s5
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	cca080e7          	jalr	-822(ra) # 80003eb2 <iunlockput>
    end_op();
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	4aa080e7          	jalr	1194(ra) # 8000469a <end_op>
  }
  return -1;
    800051f8:	557d                	li	a0,-1
}
    800051fa:	21813083          	ld	ra,536(sp)
    800051fe:	21013403          	ld	s0,528(sp)
    80005202:	20813483          	ld	s1,520(sp)
    80005206:	20013903          	ld	s2,512(sp)
    8000520a:	79fe                	ld	s3,504(sp)
    8000520c:	7a5e                	ld	s4,496(sp)
    8000520e:	7abe                	ld	s5,488(sp)
    80005210:	7b1e                	ld	s6,480(sp)
    80005212:	6bfe                	ld	s7,472(sp)
    80005214:	6c5e                	ld	s8,464(sp)
    80005216:	6cbe                	ld	s9,456(sp)
    80005218:	6d1e                	ld	s10,448(sp)
    8000521a:	7dfa                	ld	s11,440(sp)
    8000521c:	22010113          	addi	sp,sp,544
    80005220:	8082                	ret
    end_op();
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	478080e7          	jalr	1144(ra) # 8000469a <end_op>
    return -1;
    8000522a:	557d                	li	a0,-1
    8000522c:	b7f9                	j	800051fa <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000522e:	8526                	mv	a0,s1
    80005230:	ffffd097          	auipc	ra,0xffffd
    80005234:	b00080e7          	jalr	-1280(ra) # 80001d30 <proc_pagetable>
    80005238:	8b2a                	mv	s6,a0
    8000523a:	d555                	beqz	a0,800051e6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000523c:	e7042783          	lw	a5,-400(s0)
    80005240:	e8845703          	lhu	a4,-376(s0)
    80005244:	c735                	beqz	a4,800052b0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005246:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005248:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    8000524c:	6a05                	lui	s4,0x1
    8000524e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005252:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005256:	6d85                	lui	s11,0x1
    80005258:	7d7d                	lui	s10,0xfffff
    8000525a:	ac3d                	j	80005498 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000525c:	00003517          	auipc	a0,0x3
    80005260:	5a450513          	addi	a0,a0,1444 # 80008800 <syscalls+0x2a8>
    80005264:	ffffb097          	auipc	ra,0xffffb
    80005268:	2dc080e7          	jalr	732(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000526c:	874a                	mv	a4,s2
    8000526e:	009c86bb          	addw	a3,s9,s1
    80005272:	4581                	li	a1,0
    80005274:	8556                	mv	a0,s5
    80005276:	fffff097          	auipc	ra,0xfffff
    8000527a:	c8e080e7          	jalr	-882(ra) # 80003f04 <readi>
    8000527e:	2501                	sext.w	a0,a0
    80005280:	1aa91963          	bne	s2,a0,80005432 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005284:	009d84bb          	addw	s1,s11,s1
    80005288:	013d09bb          	addw	s3,s10,s3
    8000528c:	1f74f663          	bgeu	s1,s7,80005478 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005290:	02049593          	slli	a1,s1,0x20
    80005294:	9181                	srli	a1,a1,0x20
    80005296:	95e2                	add	a1,a1,s8
    80005298:	855a                	mv	a0,s6
    8000529a:	ffffc097          	auipc	ra,0xffffc
    8000529e:	f1a080e7          	jalr	-230(ra) # 800011b4 <walkaddr>
    800052a2:	862a                	mv	a2,a0
    if(pa == 0)
    800052a4:	dd45                	beqz	a0,8000525c <exec+0xfe>
      n = PGSIZE;
    800052a6:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800052a8:	fd49f2e3          	bgeu	s3,s4,8000526c <exec+0x10e>
      n = sz - i;
    800052ac:	894e                	mv	s2,s3
    800052ae:	bf7d                	j	8000526c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052b0:	4901                	li	s2,0
  iunlockput(ip);
    800052b2:	8556                	mv	a0,s5
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	bfe080e7          	jalr	-1026(ra) # 80003eb2 <iunlockput>
  end_op();
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	3de080e7          	jalr	990(ra) # 8000469a <end_op>
  p = myproc();
    800052c4:	ffffd097          	auipc	ra,0xffffd
    800052c8:	9a8080e7          	jalr	-1624(ra) # 80001c6c <myproc>
    800052cc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800052ce:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800052d2:	6785                	lui	a5,0x1
    800052d4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800052d6:	97ca                	add	a5,a5,s2
    800052d8:	777d                	lui	a4,0xfffff
    800052da:	8ff9                	and	a5,a5,a4
    800052dc:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052e0:	4691                	li	a3,4
    800052e2:	6609                	lui	a2,0x2
    800052e4:	963e                	add	a2,a2,a5
    800052e6:	85be                	mv	a1,a5
    800052e8:	855a                	mv	a0,s6
    800052ea:	ffffc097          	auipc	ra,0xffffc
    800052ee:	27e080e7          	jalr	638(ra) # 80001568 <uvmalloc>
    800052f2:	8c2a                	mv	s8,a0
  ip = 0;
    800052f4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052f6:	12050e63          	beqz	a0,80005432 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052fa:	75f9                	lui	a1,0xffffe
    800052fc:	95aa                	add	a1,a1,a0
    800052fe:	855a                	mv	a0,s6
    80005300:	ffffc097          	auipc	ra,0xffffc
    80005304:	478080e7          	jalr	1144(ra) # 80001778 <uvmclear>
  stackbase = sp - PGSIZE;
    80005308:	7afd                	lui	s5,0xfffff
    8000530a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000530c:	df043783          	ld	a5,-528(s0)
    80005310:	6388                	ld	a0,0(a5)
    80005312:	c925                	beqz	a0,80005382 <exec+0x224>
    80005314:	e9040993          	addi	s3,s0,-368
    80005318:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000531c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000531e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	c86080e7          	jalr	-890(ra) # 80000fa6 <strlen>
    80005328:	0015079b          	addiw	a5,a0,1
    8000532c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005330:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005334:	13596663          	bltu	s2,s5,80005460 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005338:	df043d83          	ld	s11,-528(s0)
    8000533c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005340:	8552                	mv	a0,s4
    80005342:	ffffc097          	auipc	ra,0xffffc
    80005346:	c64080e7          	jalr	-924(ra) # 80000fa6 <strlen>
    8000534a:	0015069b          	addiw	a3,a0,1
    8000534e:	8652                	mv	a2,s4
    80005350:	85ca                	mv	a1,s2
    80005352:	855a                	mv	a0,s6
    80005354:	ffffc097          	auipc	ra,0xffffc
    80005358:	456080e7          	jalr	1110(ra) # 800017aa <copyout>
    8000535c:	10054663          	bltz	a0,80005468 <exec+0x30a>
    ustack[argc] = sp;
    80005360:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005364:	0485                	addi	s1,s1,1
    80005366:	008d8793          	addi	a5,s11,8
    8000536a:	def43823          	sd	a5,-528(s0)
    8000536e:	008db503          	ld	a0,8(s11)
    80005372:	c911                	beqz	a0,80005386 <exec+0x228>
    if(argc >= MAXARG)
    80005374:	09a1                	addi	s3,s3,8
    80005376:	fb3c95e3          	bne	s9,s3,80005320 <exec+0x1c2>
  sz = sz1;
    8000537a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000537e:	4a81                	li	s5,0
    80005380:	a84d                	j	80005432 <exec+0x2d4>
  sp = sz;
    80005382:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005384:	4481                	li	s1,0
  ustack[argc] = 0;
    80005386:	00349793          	slli	a5,s1,0x3
    8000538a:	f9078793          	addi	a5,a5,-112
    8000538e:	97a2                	add	a5,a5,s0
    80005390:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005394:	00148693          	addi	a3,s1,1
    80005398:	068e                	slli	a3,a3,0x3
    8000539a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000539e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800053a2:	01597663          	bgeu	s2,s5,800053ae <exec+0x250>
  sz = sz1;
    800053a6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053aa:	4a81                	li	s5,0
    800053ac:	a059                	j	80005432 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800053ae:	e9040613          	addi	a2,s0,-368
    800053b2:	85ca                	mv	a1,s2
    800053b4:	855a                	mv	a0,s6
    800053b6:	ffffc097          	auipc	ra,0xffffc
    800053ba:	3f4080e7          	jalr	1012(ra) # 800017aa <copyout>
    800053be:	0a054963          	bltz	a0,80005470 <exec+0x312>
  p->trapframe->a1 = sp;
    800053c2:	058bb783          	ld	a5,88(s7)
    800053c6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800053ca:	de843783          	ld	a5,-536(s0)
    800053ce:	0007c703          	lbu	a4,0(a5)
    800053d2:	cf11                	beqz	a4,800053ee <exec+0x290>
    800053d4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053d6:	02f00693          	li	a3,47
    800053da:	a039                	j	800053e8 <exec+0x28a>
      last = s+1;
    800053dc:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800053e0:	0785                	addi	a5,a5,1
    800053e2:	fff7c703          	lbu	a4,-1(a5)
    800053e6:	c701                	beqz	a4,800053ee <exec+0x290>
    if(*s == '/')
    800053e8:	fed71ce3          	bne	a4,a3,800053e0 <exec+0x282>
    800053ec:	bfc5                	j	800053dc <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800053ee:	4641                	li	a2,16
    800053f0:	de843583          	ld	a1,-536(s0)
    800053f4:	158b8513          	addi	a0,s7,344
    800053f8:	ffffc097          	auipc	ra,0xffffc
    800053fc:	b7c080e7          	jalr	-1156(ra) # 80000f74 <safestrcpy>
  oldpagetable = p->pagetable;
    80005400:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005404:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005408:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000540c:	058bb783          	ld	a5,88(s7)
    80005410:	e6843703          	ld	a4,-408(s0)
    80005414:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005416:	058bb783          	ld	a5,88(s7)
    8000541a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000541e:	85ea                	mv	a1,s10
    80005420:	ffffd097          	auipc	ra,0xffffd
    80005424:	9ac080e7          	jalr	-1620(ra) # 80001dcc <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005428:	0004851b          	sext.w	a0,s1
    8000542c:	b3f9                	j	800051fa <exec+0x9c>
    8000542e:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005432:	df843583          	ld	a1,-520(s0)
    80005436:	855a                	mv	a0,s6
    80005438:	ffffd097          	auipc	ra,0xffffd
    8000543c:	994080e7          	jalr	-1644(ra) # 80001dcc <proc_freepagetable>
  if(ip){
    80005440:	da0a93e3          	bnez	s5,800051e6 <exec+0x88>
  return -1;
    80005444:	557d                	li	a0,-1
    80005446:	bb55                	j	800051fa <exec+0x9c>
    80005448:	df243c23          	sd	s2,-520(s0)
    8000544c:	b7dd                	j	80005432 <exec+0x2d4>
    8000544e:	df243c23          	sd	s2,-520(s0)
    80005452:	b7c5                	j	80005432 <exec+0x2d4>
    80005454:	df243c23          	sd	s2,-520(s0)
    80005458:	bfe9                	j	80005432 <exec+0x2d4>
    8000545a:	df243c23          	sd	s2,-520(s0)
    8000545e:	bfd1                	j	80005432 <exec+0x2d4>
  sz = sz1;
    80005460:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005464:	4a81                	li	s5,0
    80005466:	b7f1                	j	80005432 <exec+0x2d4>
  sz = sz1;
    80005468:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000546c:	4a81                	li	s5,0
    8000546e:	b7d1                	j	80005432 <exec+0x2d4>
  sz = sz1;
    80005470:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005474:	4a81                	li	s5,0
    80005476:	bf75                	j	80005432 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005478:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000547c:	e0843783          	ld	a5,-504(s0)
    80005480:	0017869b          	addiw	a3,a5,1
    80005484:	e0d43423          	sd	a3,-504(s0)
    80005488:	e0043783          	ld	a5,-512(s0)
    8000548c:	0387879b          	addiw	a5,a5,56
    80005490:	e8845703          	lhu	a4,-376(s0)
    80005494:	e0e6dfe3          	bge	a3,a4,800052b2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005498:	2781                	sext.w	a5,a5
    8000549a:	e0f43023          	sd	a5,-512(s0)
    8000549e:	03800713          	li	a4,56
    800054a2:	86be                	mv	a3,a5
    800054a4:	e1840613          	addi	a2,s0,-488
    800054a8:	4581                	li	a1,0
    800054aa:	8556                	mv	a0,s5
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	a58080e7          	jalr	-1448(ra) # 80003f04 <readi>
    800054b4:	03800793          	li	a5,56
    800054b8:	f6f51be3          	bne	a0,a5,8000542e <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800054bc:	e1842783          	lw	a5,-488(s0)
    800054c0:	4705                	li	a4,1
    800054c2:	fae79de3          	bne	a5,a4,8000547c <exec+0x31e>
    if(ph.memsz < ph.filesz)
    800054c6:	e4043483          	ld	s1,-448(s0)
    800054ca:	e3843783          	ld	a5,-456(s0)
    800054ce:	f6f4ede3          	bltu	s1,a5,80005448 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800054d2:	e2843783          	ld	a5,-472(s0)
    800054d6:	94be                	add	s1,s1,a5
    800054d8:	f6f4ebe3          	bltu	s1,a5,8000544e <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800054dc:	de043703          	ld	a4,-544(s0)
    800054e0:	8ff9                	and	a5,a5,a4
    800054e2:	fbad                	bnez	a5,80005454 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054e4:	e1c42503          	lw	a0,-484(s0)
    800054e8:	00000097          	auipc	ra,0x0
    800054ec:	c5c080e7          	jalr	-932(ra) # 80005144 <flags2perm>
    800054f0:	86aa                	mv	a3,a0
    800054f2:	8626                	mv	a2,s1
    800054f4:	85ca                	mv	a1,s2
    800054f6:	855a                	mv	a0,s6
    800054f8:	ffffc097          	auipc	ra,0xffffc
    800054fc:	070080e7          	jalr	112(ra) # 80001568 <uvmalloc>
    80005500:	dea43c23          	sd	a0,-520(s0)
    80005504:	d939                	beqz	a0,8000545a <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005506:	e2843c03          	ld	s8,-472(s0)
    8000550a:	e2042c83          	lw	s9,-480(s0)
    8000550e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005512:	f60b83e3          	beqz	s7,80005478 <exec+0x31a>
    80005516:	89de                	mv	s3,s7
    80005518:	4481                	li	s1,0
    8000551a:	bb9d                	j	80005290 <exec+0x132>

000000008000551c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000551c:	7179                	addi	sp,sp,-48
    8000551e:	f406                	sd	ra,40(sp)
    80005520:	f022                	sd	s0,32(sp)
    80005522:	ec26                	sd	s1,24(sp)
    80005524:	e84a                	sd	s2,16(sp)
    80005526:	1800                	addi	s0,sp,48
    80005528:	892e                	mv	s2,a1
    8000552a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000552c:	fdc40593          	addi	a1,s0,-36
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	a76080e7          	jalr	-1418(ra) # 80002fa6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005538:	fdc42703          	lw	a4,-36(s0)
    8000553c:	47bd                	li	a5,15
    8000553e:	02e7eb63          	bltu	a5,a4,80005574 <argfd+0x58>
    80005542:	ffffc097          	auipc	ra,0xffffc
    80005546:	72a080e7          	jalr	1834(ra) # 80001c6c <myproc>
    8000554a:	fdc42703          	lw	a4,-36(s0)
    8000554e:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7fdbd14a>
    80005552:	078e                	slli	a5,a5,0x3
    80005554:	953e                	add	a0,a0,a5
    80005556:	611c                	ld	a5,0(a0)
    80005558:	c385                	beqz	a5,80005578 <argfd+0x5c>
    return -1;
  if(pfd)
    8000555a:	00090463          	beqz	s2,80005562 <argfd+0x46>
    *pfd = fd;
    8000555e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005562:	4501                	li	a0,0
  if(pf)
    80005564:	c091                	beqz	s1,80005568 <argfd+0x4c>
    *pf = f;
    80005566:	e09c                	sd	a5,0(s1)
}
    80005568:	70a2                	ld	ra,40(sp)
    8000556a:	7402                	ld	s0,32(sp)
    8000556c:	64e2                	ld	s1,24(sp)
    8000556e:	6942                	ld	s2,16(sp)
    80005570:	6145                	addi	sp,sp,48
    80005572:	8082                	ret
    return -1;
    80005574:	557d                	li	a0,-1
    80005576:	bfcd                	j	80005568 <argfd+0x4c>
    80005578:	557d                	li	a0,-1
    8000557a:	b7fd                	j	80005568 <argfd+0x4c>

000000008000557c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000557c:	1101                	addi	sp,sp,-32
    8000557e:	ec06                	sd	ra,24(sp)
    80005580:	e822                	sd	s0,16(sp)
    80005582:	e426                	sd	s1,8(sp)
    80005584:	1000                	addi	s0,sp,32
    80005586:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005588:	ffffc097          	auipc	ra,0xffffc
    8000558c:	6e4080e7          	jalr	1764(ra) # 80001c6c <myproc>
    80005590:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005592:	0d050793          	addi	a5,a0,208
    80005596:	4501                	li	a0,0
    80005598:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000559a:	6398                	ld	a4,0(a5)
    8000559c:	cb19                	beqz	a4,800055b2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000559e:	2505                	addiw	a0,a0,1
    800055a0:	07a1                	addi	a5,a5,8
    800055a2:	fed51ce3          	bne	a0,a3,8000559a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055a6:	557d                	li	a0,-1
}
    800055a8:	60e2                	ld	ra,24(sp)
    800055aa:	6442                	ld	s0,16(sp)
    800055ac:	64a2                	ld	s1,8(sp)
    800055ae:	6105                	addi	sp,sp,32
    800055b0:	8082                	ret
      p->ofile[fd] = f;
    800055b2:	01a50793          	addi	a5,a0,26
    800055b6:	078e                	slli	a5,a5,0x3
    800055b8:	963e                	add	a2,a2,a5
    800055ba:	e204                	sd	s1,0(a2)
      return fd;
    800055bc:	b7f5                	j	800055a8 <fdalloc+0x2c>

00000000800055be <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055be:	715d                	addi	sp,sp,-80
    800055c0:	e486                	sd	ra,72(sp)
    800055c2:	e0a2                	sd	s0,64(sp)
    800055c4:	fc26                	sd	s1,56(sp)
    800055c6:	f84a                	sd	s2,48(sp)
    800055c8:	f44e                	sd	s3,40(sp)
    800055ca:	f052                	sd	s4,32(sp)
    800055cc:	ec56                	sd	s5,24(sp)
    800055ce:	e85a                	sd	s6,16(sp)
    800055d0:	0880                	addi	s0,sp,80
    800055d2:	8b2e                	mv	s6,a1
    800055d4:	89b2                	mv	s3,a2
    800055d6:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055d8:	fb040593          	addi	a1,s0,-80
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	e3e080e7          	jalr	-450(ra) # 8000441a <nameiparent>
    800055e4:	84aa                	mv	s1,a0
    800055e6:	14050f63          	beqz	a0,80005744 <create+0x186>
    return 0;

  ilock(dp);
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	666080e7          	jalr	1638(ra) # 80003c50 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055f2:	4601                	li	a2,0
    800055f4:	fb040593          	addi	a1,s0,-80
    800055f8:	8526                	mv	a0,s1
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	b3a080e7          	jalr	-1222(ra) # 80004134 <dirlookup>
    80005602:	8aaa                	mv	s5,a0
    80005604:	c931                	beqz	a0,80005658 <create+0x9a>
    iunlockput(dp);
    80005606:	8526                	mv	a0,s1
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	8aa080e7          	jalr	-1878(ra) # 80003eb2 <iunlockput>
    ilock(ip);
    80005610:	8556                	mv	a0,s5
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	63e080e7          	jalr	1598(ra) # 80003c50 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000561a:	000b059b          	sext.w	a1,s6
    8000561e:	4789                	li	a5,2
    80005620:	02f59563          	bne	a1,a5,8000564a <create+0x8c>
    80005624:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbd174>
    80005628:	37f9                	addiw	a5,a5,-2
    8000562a:	17c2                	slli	a5,a5,0x30
    8000562c:	93c1                	srli	a5,a5,0x30
    8000562e:	4705                	li	a4,1
    80005630:	00f76d63          	bltu	a4,a5,8000564a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005634:	8556                	mv	a0,s5
    80005636:	60a6                	ld	ra,72(sp)
    80005638:	6406                	ld	s0,64(sp)
    8000563a:	74e2                	ld	s1,56(sp)
    8000563c:	7942                	ld	s2,48(sp)
    8000563e:	79a2                	ld	s3,40(sp)
    80005640:	7a02                	ld	s4,32(sp)
    80005642:	6ae2                	ld	s5,24(sp)
    80005644:	6b42                	ld	s6,16(sp)
    80005646:	6161                	addi	sp,sp,80
    80005648:	8082                	ret
    iunlockput(ip);
    8000564a:	8556                	mv	a0,s5
    8000564c:	fffff097          	auipc	ra,0xfffff
    80005650:	866080e7          	jalr	-1946(ra) # 80003eb2 <iunlockput>
    return 0;
    80005654:	4a81                	li	s5,0
    80005656:	bff9                	j	80005634 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005658:	85da                	mv	a1,s6
    8000565a:	4088                	lw	a0,0(s1)
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	456080e7          	jalr	1110(ra) # 80003ab2 <ialloc>
    80005664:	8a2a                	mv	s4,a0
    80005666:	c539                	beqz	a0,800056b4 <create+0xf6>
  ilock(ip);
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	5e8080e7          	jalr	1512(ra) # 80003c50 <ilock>
  ip->major = major;
    80005670:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005674:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005678:	4905                	li	s2,1
    8000567a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000567e:	8552                	mv	a0,s4
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	504080e7          	jalr	1284(ra) # 80003b84 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005688:	000b059b          	sext.w	a1,s6
    8000568c:	03258b63          	beq	a1,s2,800056c2 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005690:	004a2603          	lw	a2,4(s4)
    80005694:	fb040593          	addi	a1,s0,-80
    80005698:	8526                	mv	a0,s1
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	cb0080e7          	jalr	-848(ra) # 8000434a <dirlink>
    800056a2:	06054f63          	bltz	a0,80005720 <create+0x162>
  iunlockput(dp);
    800056a6:	8526                	mv	a0,s1
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	80a080e7          	jalr	-2038(ra) # 80003eb2 <iunlockput>
  return ip;
    800056b0:	8ad2                	mv	s5,s4
    800056b2:	b749                	j	80005634 <create+0x76>
    iunlockput(dp);
    800056b4:	8526                	mv	a0,s1
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	7fc080e7          	jalr	2044(ra) # 80003eb2 <iunlockput>
    return 0;
    800056be:	8ad2                	mv	s5,s4
    800056c0:	bf95                	j	80005634 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056c2:	004a2603          	lw	a2,4(s4)
    800056c6:	00003597          	auipc	a1,0x3
    800056ca:	15a58593          	addi	a1,a1,346 # 80008820 <syscalls+0x2c8>
    800056ce:	8552                	mv	a0,s4
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	c7a080e7          	jalr	-902(ra) # 8000434a <dirlink>
    800056d8:	04054463          	bltz	a0,80005720 <create+0x162>
    800056dc:	40d0                	lw	a2,4(s1)
    800056de:	00003597          	auipc	a1,0x3
    800056e2:	14a58593          	addi	a1,a1,330 # 80008828 <syscalls+0x2d0>
    800056e6:	8552                	mv	a0,s4
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	c62080e7          	jalr	-926(ra) # 8000434a <dirlink>
    800056f0:	02054863          	bltz	a0,80005720 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800056f4:	004a2603          	lw	a2,4(s4)
    800056f8:	fb040593          	addi	a1,s0,-80
    800056fc:	8526                	mv	a0,s1
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	c4c080e7          	jalr	-948(ra) # 8000434a <dirlink>
    80005706:	00054d63          	bltz	a0,80005720 <create+0x162>
    dp->nlink++;  // for ".."
    8000570a:	04a4d783          	lhu	a5,74(s1)
    8000570e:	2785                	addiw	a5,a5,1
    80005710:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005714:	8526                	mv	a0,s1
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	46e080e7          	jalr	1134(ra) # 80003b84 <iupdate>
    8000571e:	b761                	j	800056a6 <create+0xe8>
  ip->nlink = 0;
    80005720:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005724:	8552                	mv	a0,s4
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	45e080e7          	jalr	1118(ra) # 80003b84 <iupdate>
  iunlockput(ip);
    8000572e:	8552                	mv	a0,s4
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	782080e7          	jalr	1922(ra) # 80003eb2 <iunlockput>
  iunlockput(dp);
    80005738:	8526                	mv	a0,s1
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	778080e7          	jalr	1912(ra) # 80003eb2 <iunlockput>
  return 0;
    80005742:	bdcd                	j	80005634 <create+0x76>
    return 0;
    80005744:	8aaa                	mv	s5,a0
    80005746:	b5fd                	j	80005634 <create+0x76>

0000000080005748 <sys_dup>:
{
    80005748:	7179                	addi	sp,sp,-48
    8000574a:	f406                	sd	ra,40(sp)
    8000574c:	f022                	sd	s0,32(sp)
    8000574e:	ec26                	sd	s1,24(sp)
    80005750:	e84a                	sd	s2,16(sp)
    80005752:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005754:	fd840613          	addi	a2,s0,-40
    80005758:	4581                	li	a1,0
    8000575a:	4501                	li	a0,0
    8000575c:	00000097          	auipc	ra,0x0
    80005760:	dc0080e7          	jalr	-576(ra) # 8000551c <argfd>
    return -1;
    80005764:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005766:	02054363          	bltz	a0,8000578c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000576a:	fd843903          	ld	s2,-40(s0)
    8000576e:	854a                	mv	a0,s2
    80005770:	00000097          	auipc	ra,0x0
    80005774:	e0c080e7          	jalr	-500(ra) # 8000557c <fdalloc>
    80005778:	84aa                	mv	s1,a0
    return -1;
    8000577a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000577c:	00054863          	bltz	a0,8000578c <sys_dup+0x44>
  filedup(f);
    80005780:	854a                	mv	a0,s2
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	310080e7          	jalr	784(ra) # 80004a92 <filedup>
  return fd;
    8000578a:	87a6                	mv	a5,s1
}
    8000578c:	853e                	mv	a0,a5
    8000578e:	70a2                	ld	ra,40(sp)
    80005790:	7402                	ld	s0,32(sp)
    80005792:	64e2                	ld	s1,24(sp)
    80005794:	6942                	ld	s2,16(sp)
    80005796:	6145                	addi	sp,sp,48
    80005798:	8082                	ret

000000008000579a <sys_read>:
{
    8000579a:	7179                	addi	sp,sp,-48
    8000579c:	f406                	sd	ra,40(sp)
    8000579e:	f022                	sd	s0,32(sp)
    800057a0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057a2:	fd840593          	addi	a1,s0,-40
    800057a6:	4505                	li	a0,1
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	81e080e7          	jalr	-2018(ra) # 80002fc6 <argaddr>
  argint(2, &n);
    800057b0:	fe440593          	addi	a1,s0,-28
    800057b4:	4509                	li	a0,2
    800057b6:	ffffd097          	auipc	ra,0xffffd
    800057ba:	7f0080e7          	jalr	2032(ra) # 80002fa6 <argint>
  if(argfd(0, 0, &f) < 0)
    800057be:	fe840613          	addi	a2,s0,-24
    800057c2:	4581                	li	a1,0
    800057c4:	4501                	li	a0,0
    800057c6:	00000097          	auipc	ra,0x0
    800057ca:	d56080e7          	jalr	-682(ra) # 8000551c <argfd>
    800057ce:	87aa                	mv	a5,a0
    return -1;
    800057d0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057d2:	0007cc63          	bltz	a5,800057ea <sys_read+0x50>
  return fileread(f, p, n);
    800057d6:	fe442603          	lw	a2,-28(s0)
    800057da:	fd843583          	ld	a1,-40(s0)
    800057de:	fe843503          	ld	a0,-24(s0)
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	43c080e7          	jalr	1084(ra) # 80004c1e <fileread>
}
    800057ea:	70a2                	ld	ra,40(sp)
    800057ec:	7402                	ld	s0,32(sp)
    800057ee:	6145                	addi	sp,sp,48
    800057f0:	8082                	ret

00000000800057f2 <sys_write>:
{
    800057f2:	7179                	addi	sp,sp,-48
    800057f4:	f406                	sd	ra,40(sp)
    800057f6:	f022                	sd	s0,32(sp)
    800057f8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057fa:	fd840593          	addi	a1,s0,-40
    800057fe:	4505                	li	a0,1
    80005800:	ffffd097          	auipc	ra,0xffffd
    80005804:	7c6080e7          	jalr	1990(ra) # 80002fc6 <argaddr>
  argint(2, &n);
    80005808:	fe440593          	addi	a1,s0,-28
    8000580c:	4509                	li	a0,2
    8000580e:	ffffd097          	auipc	ra,0xffffd
    80005812:	798080e7          	jalr	1944(ra) # 80002fa6 <argint>
  if(argfd(0, 0, &f) < 0)
    80005816:	fe840613          	addi	a2,s0,-24
    8000581a:	4581                	li	a1,0
    8000581c:	4501                	li	a0,0
    8000581e:	00000097          	auipc	ra,0x0
    80005822:	cfe080e7          	jalr	-770(ra) # 8000551c <argfd>
    80005826:	87aa                	mv	a5,a0
    return -1;
    80005828:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000582a:	0007cc63          	bltz	a5,80005842 <sys_write+0x50>
  return filewrite(f, p, n);
    8000582e:	fe442603          	lw	a2,-28(s0)
    80005832:	fd843583          	ld	a1,-40(s0)
    80005836:	fe843503          	ld	a0,-24(s0)
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	4a6080e7          	jalr	1190(ra) # 80004ce0 <filewrite>
}
    80005842:	70a2                	ld	ra,40(sp)
    80005844:	7402                	ld	s0,32(sp)
    80005846:	6145                	addi	sp,sp,48
    80005848:	8082                	ret

000000008000584a <sys_close>:
{
    8000584a:	1101                	addi	sp,sp,-32
    8000584c:	ec06                	sd	ra,24(sp)
    8000584e:	e822                	sd	s0,16(sp)
    80005850:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005852:	fe040613          	addi	a2,s0,-32
    80005856:	fec40593          	addi	a1,s0,-20
    8000585a:	4501                	li	a0,0
    8000585c:	00000097          	auipc	ra,0x0
    80005860:	cc0080e7          	jalr	-832(ra) # 8000551c <argfd>
    return -1;
    80005864:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005866:	02054463          	bltz	a0,8000588e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000586a:	ffffc097          	auipc	ra,0xffffc
    8000586e:	402080e7          	jalr	1026(ra) # 80001c6c <myproc>
    80005872:	fec42783          	lw	a5,-20(s0)
    80005876:	07e9                	addi	a5,a5,26
    80005878:	078e                	slli	a5,a5,0x3
    8000587a:	953e                	add	a0,a0,a5
    8000587c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005880:	fe043503          	ld	a0,-32(s0)
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	260080e7          	jalr	608(ra) # 80004ae4 <fileclose>
  return 0;
    8000588c:	4781                	li	a5,0
}
    8000588e:	853e                	mv	a0,a5
    80005890:	60e2                	ld	ra,24(sp)
    80005892:	6442                	ld	s0,16(sp)
    80005894:	6105                	addi	sp,sp,32
    80005896:	8082                	ret

0000000080005898 <sys_fstat>:
{
    80005898:	1101                	addi	sp,sp,-32
    8000589a:	ec06                	sd	ra,24(sp)
    8000589c:	e822                	sd	s0,16(sp)
    8000589e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800058a0:	fe040593          	addi	a1,s0,-32
    800058a4:	4505                	li	a0,1
    800058a6:	ffffd097          	auipc	ra,0xffffd
    800058aa:	720080e7          	jalr	1824(ra) # 80002fc6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800058ae:	fe840613          	addi	a2,s0,-24
    800058b2:	4581                	li	a1,0
    800058b4:	4501                	li	a0,0
    800058b6:	00000097          	auipc	ra,0x0
    800058ba:	c66080e7          	jalr	-922(ra) # 8000551c <argfd>
    800058be:	87aa                	mv	a5,a0
    return -1;
    800058c0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058c2:	0007ca63          	bltz	a5,800058d6 <sys_fstat+0x3e>
  return filestat(f, st);
    800058c6:	fe043583          	ld	a1,-32(s0)
    800058ca:	fe843503          	ld	a0,-24(s0)
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	2de080e7          	jalr	734(ra) # 80004bac <filestat>
}
    800058d6:	60e2                	ld	ra,24(sp)
    800058d8:	6442                	ld	s0,16(sp)
    800058da:	6105                	addi	sp,sp,32
    800058dc:	8082                	ret

00000000800058de <sys_link>:
{
    800058de:	7169                	addi	sp,sp,-304
    800058e0:	f606                	sd	ra,296(sp)
    800058e2:	f222                	sd	s0,288(sp)
    800058e4:	ee26                	sd	s1,280(sp)
    800058e6:	ea4a                	sd	s2,272(sp)
    800058e8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058ea:	08000613          	li	a2,128
    800058ee:	ed040593          	addi	a1,s0,-304
    800058f2:	4501                	li	a0,0
    800058f4:	ffffd097          	auipc	ra,0xffffd
    800058f8:	6f2080e7          	jalr	1778(ra) # 80002fe6 <argstr>
    return -1;
    800058fc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058fe:	10054e63          	bltz	a0,80005a1a <sys_link+0x13c>
    80005902:	08000613          	li	a2,128
    80005906:	f5040593          	addi	a1,s0,-176
    8000590a:	4505                	li	a0,1
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	6da080e7          	jalr	1754(ra) # 80002fe6 <argstr>
    return -1;
    80005914:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005916:	10054263          	bltz	a0,80005a1a <sys_link+0x13c>
  begin_op();
    8000591a:	fffff097          	auipc	ra,0xfffff
    8000591e:	d02080e7          	jalr	-766(ra) # 8000461c <begin_op>
  if((ip = namei(old)) == 0){
    80005922:	ed040513          	addi	a0,s0,-304
    80005926:	fffff097          	auipc	ra,0xfffff
    8000592a:	ad6080e7          	jalr	-1322(ra) # 800043fc <namei>
    8000592e:	84aa                	mv	s1,a0
    80005930:	c551                	beqz	a0,800059bc <sys_link+0xde>
  ilock(ip);
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	31e080e7          	jalr	798(ra) # 80003c50 <ilock>
  if(ip->type == T_DIR){
    8000593a:	04449703          	lh	a4,68(s1)
    8000593e:	4785                	li	a5,1
    80005940:	08f70463          	beq	a4,a5,800059c8 <sys_link+0xea>
  ip->nlink++;
    80005944:	04a4d783          	lhu	a5,74(s1)
    80005948:	2785                	addiw	a5,a5,1
    8000594a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	234080e7          	jalr	564(ra) # 80003b84 <iupdate>
  iunlock(ip);
    80005958:	8526                	mv	a0,s1
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	3b8080e7          	jalr	952(ra) # 80003d12 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005962:	fd040593          	addi	a1,s0,-48
    80005966:	f5040513          	addi	a0,s0,-176
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	ab0080e7          	jalr	-1360(ra) # 8000441a <nameiparent>
    80005972:	892a                	mv	s2,a0
    80005974:	c935                	beqz	a0,800059e8 <sys_link+0x10a>
  ilock(dp);
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	2da080e7          	jalr	730(ra) # 80003c50 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000597e:	00092703          	lw	a4,0(s2)
    80005982:	409c                	lw	a5,0(s1)
    80005984:	04f71d63          	bne	a4,a5,800059de <sys_link+0x100>
    80005988:	40d0                	lw	a2,4(s1)
    8000598a:	fd040593          	addi	a1,s0,-48
    8000598e:	854a                	mv	a0,s2
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	9ba080e7          	jalr	-1606(ra) # 8000434a <dirlink>
    80005998:	04054363          	bltz	a0,800059de <sys_link+0x100>
  iunlockput(dp);
    8000599c:	854a                	mv	a0,s2
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	514080e7          	jalr	1300(ra) # 80003eb2 <iunlockput>
  iput(ip);
    800059a6:	8526                	mv	a0,s1
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	462080e7          	jalr	1122(ra) # 80003e0a <iput>
  end_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	cea080e7          	jalr	-790(ra) # 8000469a <end_op>
  return 0;
    800059b8:	4781                	li	a5,0
    800059ba:	a085                	j	80005a1a <sys_link+0x13c>
    end_op();
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	cde080e7          	jalr	-802(ra) # 8000469a <end_op>
    return -1;
    800059c4:	57fd                	li	a5,-1
    800059c6:	a891                	j	80005a1a <sys_link+0x13c>
    iunlockput(ip);
    800059c8:	8526                	mv	a0,s1
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	4e8080e7          	jalr	1256(ra) # 80003eb2 <iunlockput>
    end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	cc8080e7          	jalr	-824(ra) # 8000469a <end_op>
    return -1;
    800059da:	57fd                	li	a5,-1
    800059dc:	a83d                	j	80005a1a <sys_link+0x13c>
    iunlockput(dp);
    800059de:	854a                	mv	a0,s2
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	4d2080e7          	jalr	1234(ra) # 80003eb2 <iunlockput>
  ilock(ip);
    800059e8:	8526                	mv	a0,s1
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	266080e7          	jalr	614(ra) # 80003c50 <ilock>
  ip->nlink--;
    800059f2:	04a4d783          	lhu	a5,74(s1)
    800059f6:	37fd                	addiw	a5,a5,-1
    800059f8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059fc:	8526                	mv	a0,s1
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	186080e7          	jalr	390(ra) # 80003b84 <iupdate>
  iunlockput(ip);
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	4aa080e7          	jalr	1194(ra) # 80003eb2 <iunlockput>
  end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	c8a080e7          	jalr	-886(ra) # 8000469a <end_op>
  return -1;
    80005a18:	57fd                	li	a5,-1
}
    80005a1a:	853e                	mv	a0,a5
    80005a1c:	70b2                	ld	ra,296(sp)
    80005a1e:	7412                	ld	s0,288(sp)
    80005a20:	64f2                	ld	s1,280(sp)
    80005a22:	6952                	ld	s2,272(sp)
    80005a24:	6155                	addi	sp,sp,304
    80005a26:	8082                	ret

0000000080005a28 <sys_unlink>:
{
    80005a28:	7151                	addi	sp,sp,-240
    80005a2a:	f586                	sd	ra,232(sp)
    80005a2c:	f1a2                	sd	s0,224(sp)
    80005a2e:	eda6                	sd	s1,216(sp)
    80005a30:	e9ca                	sd	s2,208(sp)
    80005a32:	e5ce                	sd	s3,200(sp)
    80005a34:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a36:	08000613          	li	a2,128
    80005a3a:	f3040593          	addi	a1,s0,-208
    80005a3e:	4501                	li	a0,0
    80005a40:	ffffd097          	auipc	ra,0xffffd
    80005a44:	5a6080e7          	jalr	1446(ra) # 80002fe6 <argstr>
    80005a48:	18054163          	bltz	a0,80005bca <sys_unlink+0x1a2>
  begin_op();
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	bd0080e7          	jalr	-1072(ra) # 8000461c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a54:	fb040593          	addi	a1,s0,-80
    80005a58:	f3040513          	addi	a0,s0,-208
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	9be080e7          	jalr	-1602(ra) # 8000441a <nameiparent>
    80005a64:	84aa                	mv	s1,a0
    80005a66:	c979                	beqz	a0,80005b3c <sys_unlink+0x114>
  ilock(dp);
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	1e8080e7          	jalr	488(ra) # 80003c50 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a70:	00003597          	auipc	a1,0x3
    80005a74:	db058593          	addi	a1,a1,-592 # 80008820 <syscalls+0x2c8>
    80005a78:	fb040513          	addi	a0,s0,-80
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	69e080e7          	jalr	1694(ra) # 8000411a <namecmp>
    80005a84:	14050a63          	beqz	a0,80005bd8 <sys_unlink+0x1b0>
    80005a88:	00003597          	auipc	a1,0x3
    80005a8c:	da058593          	addi	a1,a1,-608 # 80008828 <syscalls+0x2d0>
    80005a90:	fb040513          	addi	a0,s0,-80
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	686080e7          	jalr	1670(ra) # 8000411a <namecmp>
    80005a9c:	12050e63          	beqz	a0,80005bd8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005aa0:	f2c40613          	addi	a2,s0,-212
    80005aa4:	fb040593          	addi	a1,s0,-80
    80005aa8:	8526                	mv	a0,s1
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	68a080e7          	jalr	1674(ra) # 80004134 <dirlookup>
    80005ab2:	892a                	mv	s2,a0
    80005ab4:	12050263          	beqz	a0,80005bd8 <sys_unlink+0x1b0>
  ilock(ip);
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	198080e7          	jalr	408(ra) # 80003c50 <ilock>
  if(ip->nlink < 1)
    80005ac0:	04a91783          	lh	a5,74(s2)
    80005ac4:	08f05263          	blez	a5,80005b48 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ac8:	04491703          	lh	a4,68(s2)
    80005acc:	4785                	li	a5,1
    80005ace:	08f70563          	beq	a4,a5,80005b58 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ad2:	4641                	li	a2,16
    80005ad4:	4581                	li	a1,0
    80005ad6:	fc040513          	addi	a0,s0,-64
    80005ada:	ffffb097          	auipc	ra,0xffffb
    80005ade:	350080e7          	jalr	848(ra) # 80000e2a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ae2:	4741                	li	a4,16
    80005ae4:	f2c42683          	lw	a3,-212(s0)
    80005ae8:	fc040613          	addi	a2,s0,-64
    80005aec:	4581                	li	a1,0
    80005aee:	8526                	mv	a0,s1
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	50c080e7          	jalr	1292(ra) # 80003ffc <writei>
    80005af8:	47c1                	li	a5,16
    80005afa:	0af51563          	bne	a0,a5,80005ba4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005afe:	04491703          	lh	a4,68(s2)
    80005b02:	4785                	li	a5,1
    80005b04:	0af70863          	beq	a4,a5,80005bb4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b08:	8526                	mv	a0,s1
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	3a8080e7          	jalr	936(ra) # 80003eb2 <iunlockput>
  ip->nlink--;
    80005b12:	04a95783          	lhu	a5,74(s2)
    80005b16:	37fd                	addiw	a5,a5,-1
    80005b18:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b1c:	854a                	mv	a0,s2
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	066080e7          	jalr	102(ra) # 80003b84 <iupdate>
  iunlockput(ip);
    80005b26:	854a                	mv	a0,s2
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	38a080e7          	jalr	906(ra) # 80003eb2 <iunlockput>
  end_op();
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	b6a080e7          	jalr	-1174(ra) # 8000469a <end_op>
  return 0;
    80005b38:	4501                	li	a0,0
    80005b3a:	a84d                	j	80005bec <sys_unlink+0x1c4>
    end_op();
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	b5e080e7          	jalr	-1186(ra) # 8000469a <end_op>
    return -1;
    80005b44:	557d                	li	a0,-1
    80005b46:	a05d                	j	80005bec <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b48:	00003517          	auipc	a0,0x3
    80005b4c:	ce850513          	addi	a0,a0,-792 # 80008830 <syscalls+0x2d8>
    80005b50:	ffffb097          	auipc	ra,0xffffb
    80005b54:	9f0080e7          	jalr	-1552(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b58:	04c92703          	lw	a4,76(s2)
    80005b5c:	02000793          	li	a5,32
    80005b60:	f6e7f9e3          	bgeu	a5,a4,80005ad2 <sys_unlink+0xaa>
    80005b64:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b68:	4741                	li	a4,16
    80005b6a:	86ce                	mv	a3,s3
    80005b6c:	f1840613          	addi	a2,s0,-232
    80005b70:	4581                	li	a1,0
    80005b72:	854a                	mv	a0,s2
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	390080e7          	jalr	912(ra) # 80003f04 <readi>
    80005b7c:	47c1                	li	a5,16
    80005b7e:	00f51b63          	bne	a0,a5,80005b94 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b82:	f1845783          	lhu	a5,-232(s0)
    80005b86:	e7a1                	bnez	a5,80005bce <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b88:	29c1                	addiw	s3,s3,16
    80005b8a:	04c92783          	lw	a5,76(s2)
    80005b8e:	fcf9ede3          	bltu	s3,a5,80005b68 <sys_unlink+0x140>
    80005b92:	b781                	j	80005ad2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b94:	00003517          	auipc	a0,0x3
    80005b98:	cb450513          	addi	a0,a0,-844 # 80008848 <syscalls+0x2f0>
    80005b9c:	ffffb097          	auipc	ra,0xffffb
    80005ba0:	9a4080e7          	jalr	-1628(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005ba4:	00003517          	auipc	a0,0x3
    80005ba8:	cbc50513          	addi	a0,a0,-836 # 80008860 <syscalls+0x308>
    80005bac:	ffffb097          	auipc	ra,0xffffb
    80005bb0:	994080e7          	jalr	-1644(ra) # 80000540 <panic>
    dp->nlink--;
    80005bb4:	04a4d783          	lhu	a5,74(s1)
    80005bb8:	37fd                	addiw	a5,a5,-1
    80005bba:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bbe:	8526                	mv	a0,s1
    80005bc0:	ffffe097          	auipc	ra,0xffffe
    80005bc4:	fc4080e7          	jalr	-60(ra) # 80003b84 <iupdate>
    80005bc8:	b781                	j	80005b08 <sys_unlink+0xe0>
    return -1;
    80005bca:	557d                	li	a0,-1
    80005bcc:	a005                	j	80005bec <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bce:	854a                	mv	a0,s2
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	2e2080e7          	jalr	738(ra) # 80003eb2 <iunlockput>
  iunlockput(dp);
    80005bd8:	8526                	mv	a0,s1
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	2d8080e7          	jalr	728(ra) # 80003eb2 <iunlockput>
  end_op();
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	ab8080e7          	jalr	-1352(ra) # 8000469a <end_op>
  return -1;
    80005bea:	557d                	li	a0,-1
}
    80005bec:	70ae                	ld	ra,232(sp)
    80005bee:	740e                	ld	s0,224(sp)
    80005bf0:	64ee                	ld	s1,216(sp)
    80005bf2:	694e                	ld	s2,208(sp)
    80005bf4:	69ae                	ld	s3,200(sp)
    80005bf6:	616d                	addi	sp,sp,240
    80005bf8:	8082                	ret

0000000080005bfa <sys_open>:

uint64
sys_open(void)
{
    80005bfa:	7131                	addi	sp,sp,-192
    80005bfc:	fd06                	sd	ra,184(sp)
    80005bfe:	f922                	sd	s0,176(sp)
    80005c00:	f526                	sd	s1,168(sp)
    80005c02:	f14a                	sd	s2,160(sp)
    80005c04:	ed4e                	sd	s3,152(sp)
    80005c06:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005c08:	f4c40593          	addi	a1,s0,-180
    80005c0c:	4505                	li	a0,1
    80005c0e:	ffffd097          	auipc	ra,0xffffd
    80005c12:	398080e7          	jalr	920(ra) # 80002fa6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c16:	08000613          	li	a2,128
    80005c1a:	f5040593          	addi	a1,s0,-176
    80005c1e:	4501                	li	a0,0
    80005c20:	ffffd097          	auipc	ra,0xffffd
    80005c24:	3c6080e7          	jalr	966(ra) # 80002fe6 <argstr>
    80005c28:	87aa                	mv	a5,a0
    return -1;
    80005c2a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c2c:	0a07c963          	bltz	a5,80005cde <sys_open+0xe4>

  begin_op();
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	9ec080e7          	jalr	-1556(ra) # 8000461c <begin_op>

  if(omode & O_CREATE){
    80005c38:	f4c42783          	lw	a5,-180(s0)
    80005c3c:	2007f793          	andi	a5,a5,512
    80005c40:	cfc5                	beqz	a5,80005cf8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c42:	4681                	li	a3,0
    80005c44:	4601                	li	a2,0
    80005c46:	4589                	li	a1,2
    80005c48:	f5040513          	addi	a0,s0,-176
    80005c4c:	00000097          	auipc	ra,0x0
    80005c50:	972080e7          	jalr	-1678(ra) # 800055be <create>
    80005c54:	84aa                	mv	s1,a0
    if(ip == 0){
    80005c56:	c959                	beqz	a0,80005cec <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c58:	04449703          	lh	a4,68(s1)
    80005c5c:	478d                	li	a5,3
    80005c5e:	00f71763          	bne	a4,a5,80005c6c <sys_open+0x72>
    80005c62:	0464d703          	lhu	a4,70(s1)
    80005c66:	47a5                	li	a5,9
    80005c68:	0ce7ed63          	bltu	a5,a4,80005d42 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	dbc080e7          	jalr	-580(ra) # 80004a28 <filealloc>
    80005c74:	89aa                	mv	s3,a0
    80005c76:	10050363          	beqz	a0,80005d7c <sys_open+0x182>
    80005c7a:	00000097          	auipc	ra,0x0
    80005c7e:	902080e7          	jalr	-1790(ra) # 8000557c <fdalloc>
    80005c82:	892a                	mv	s2,a0
    80005c84:	0e054763          	bltz	a0,80005d72 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c88:	04449703          	lh	a4,68(s1)
    80005c8c:	478d                	li	a5,3
    80005c8e:	0cf70563          	beq	a4,a5,80005d58 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c92:	4789                	li	a5,2
    80005c94:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c98:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c9c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ca0:	f4c42783          	lw	a5,-180(s0)
    80005ca4:	0017c713          	xori	a4,a5,1
    80005ca8:	8b05                	andi	a4,a4,1
    80005caa:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cae:	0037f713          	andi	a4,a5,3
    80005cb2:	00e03733          	snez	a4,a4
    80005cb6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cba:	4007f793          	andi	a5,a5,1024
    80005cbe:	c791                	beqz	a5,80005cca <sys_open+0xd0>
    80005cc0:	04449703          	lh	a4,68(s1)
    80005cc4:	4789                	li	a5,2
    80005cc6:	0af70063          	beq	a4,a5,80005d66 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005cca:	8526                	mv	a0,s1
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	046080e7          	jalr	70(ra) # 80003d12 <iunlock>
  end_op();
    80005cd4:	fffff097          	auipc	ra,0xfffff
    80005cd8:	9c6080e7          	jalr	-1594(ra) # 8000469a <end_op>

  return fd;
    80005cdc:	854a                	mv	a0,s2
}
    80005cde:	70ea                	ld	ra,184(sp)
    80005ce0:	744a                	ld	s0,176(sp)
    80005ce2:	74aa                	ld	s1,168(sp)
    80005ce4:	790a                	ld	s2,160(sp)
    80005ce6:	69ea                	ld	s3,152(sp)
    80005ce8:	6129                	addi	sp,sp,192
    80005cea:	8082                	ret
      end_op();
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	9ae080e7          	jalr	-1618(ra) # 8000469a <end_op>
      return -1;
    80005cf4:	557d                	li	a0,-1
    80005cf6:	b7e5                	j	80005cde <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005cf8:	f5040513          	addi	a0,s0,-176
    80005cfc:	ffffe097          	auipc	ra,0xffffe
    80005d00:	700080e7          	jalr	1792(ra) # 800043fc <namei>
    80005d04:	84aa                	mv	s1,a0
    80005d06:	c905                	beqz	a0,80005d36 <sys_open+0x13c>
    ilock(ip);
    80005d08:	ffffe097          	auipc	ra,0xffffe
    80005d0c:	f48080e7          	jalr	-184(ra) # 80003c50 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d10:	04449703          	lh	a4,68(s1)
    80005d14:	4785                	li	a5,1
    80005d16:	f4f711e3          	bne	a4,a5,80005c58 <sys_open+0x5e>
    80005d1a:	f4c42783          	lw	a5,-180(s0)
    80005d1e:	d7b9                	beqz	a5,80005c6c <sys_open+0x72>
      iunlockput(ip);
    80005d20:	8526                	mv	a0,s1
    80005d22:	ffffe097          	auipc	ra,0xffffe
    80005d26:	190080e7          	jalr	400(ra) # 80003eb2 <iunlockput>
      end_op();
    80005d2a:	fffff097          	auipc	ra,0xfffff
    80005d2e:	970080e7          	jalr	-1680(ra) # 8000469a <end_op>
      return -1;
    80005d32:	557d                	li	a0,-1
    80005d34:	b76d                	j	80005cde <sys_open+0xe4>
      end_op();
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	964080e7          	jalr	-1692(ra) # 8000469a <end_op>
      return -1;
    80005d3e:	557d                	li	a0,-1
    80005d40:	bf79                	j	80005cde <sys_open+0xe4>
    iunlockput(ip);
    80005d42:	8526                	mv	a0,s1
    80005d44:	ffffe097          	auipc	ra,0xffffe
    80005d48:	16e080e7          	jalr	366(ra) # 80003eb2 <iunlockput>
    end_op();
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	94e080e7          	jalr	-1714(ra) # 8000469a <end_op>
    return -1;
    80005d54:	557d                	li	a0,-1
    80005d56:	b761                	j	80005cde <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d58:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d5c:	04649783          	lh	a5,70(s1)
    80005d60:	02f99223          	sh	a5,36(s3)
    80005d64:	bf25                	j	80005c9c <sys_open+0xa2>
    itrunc(ip);
    80005d66:	8526                	mv	a0,s1
    80005d68:	ffffe097          	auipc	ra,0xffffe
    80005d6c:	ff6080e7          	jalr	-10(ra) # 80003d5e <itrunc>
    80005d70:	bfa9                	j	80005cca <sys_open+0xd0>
      fileclose(f);
    80005d72:	854e                	mv	a0,s3
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	d70080e7          	jalr	-656(ra) # 80004ae4 <fileclose>
    iunlockput(ip);
    80005d7c:	8526                	mv	a0,s1
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	134080e7          	jalr	308(ra) # 80003eb2 <iunlockput>
    end_op();
    80005d86:	fffff097          	auipc	ra,0xfffff
    80005d8a:	914080e7          	jalr	-1772(ra) # 8000469a <end_op>
    return -1;
    80005d8e:	557d                	li	a0,-1
    80005d90:	b7b9                	j	80005cde <sys_open+0xe4>

0000000080005d92 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d92:	7175                	addi	sp,sp,-144
    80005d94:	e506                	sd	ra,136(sp)
    80005d96:	e122                	sd	s0,128(sp)
    80005d98:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d9a:	fffff097          	auipc	ra,0xfffff
    80005d9e:	882080e7          	jalr	-1918(ra) # 8000461c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005da2:	08000613          	li	a2,128
    80005da6:	f7040593          	addi	a1,s0,-144
    80005daa:	4501                	li	a0,0
    80005dac:	ffffd097          	auipc	ra,0xffffd
    80005db0:	23a080e7          	jalr	570(ra) # 80002fe6 <argstr>
    80005db4:	02054963          	bltz	a0,80005de6 <sys_mkdir+0x54>
    80005db8:	4681                	li	a3,0
    80005dba:	4601                	li	a2,0
    80005dbc:	4585                	li	a1,1
    80005dbe:	f7040513          	addi	a0,s0,-144
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	7fc080e7          	jalr	2044(ra) # 800055be <create>
    80005dca:	cd11                	beqz	a0,80005de6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	0e6080e7          	jalr	230(ra) # 80003eb2 <iunlockput>
  end_op();
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	8c6080e7          	jalr	-1850(ra) # 8000469a <end_op>
  return 0;
    80005ddc:	4501                	li	a0,0
}
    80005dde:	60aa                	ld	ra,136(sp)
    80005de0:	640a                	ld	s0,128(sp)
    80005de2:	6149                	addi	sp,sp,144
    80005de4:	8082                	ret
    end_op();
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	8b4080e7          	jalr	-1868(ra) # 8000469a <end_op>
    return -1;
    80005dee:	557d                	li	a0,-1
    80005df0:	b7fd                	j	80005dde <sys_mkdir+0x4c>

0000000080005df2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005df2:	7135                	addi	sp,sp,-160
    80005df4:	ed06                	sd	ra,152(sp)
    80005df6:	e922                	sd	s0,144(sp)
    80005df8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	822080e7          	jalr	-2014(ra) # 8000461c <begin_op>
  argint(1, &major);
    80005e02:	f6c40593          	addi	a1,s0,-148
    80005e06:	4505                	li	a0,1
    80005e08:	ffffd097          	auipc	ra,0xffffd
    80005e0c:	19e080e7          	jalr	414(ra) # 80002fa6 <argint>
  argint(2, &minor);
    80005e10:	f6840593          	addi	a1,s0,-152
    80005e14:	4509                	li	a0,2
    80005e16:	ffffd097          	auipc	ra,0xffffd
    80005e1a:	190080e7          	jalr	400(ra) # 80002fa6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e1e:	08000613          	li	a2,128
    80005e22:	f7040593          	addi	a1,s0,-144
    80005e26:	4501                	li	a0,0
    80005e28:	ffffd097          	auipc	ra,0xffffd
    80005e2c:	1be080e7          	jalr	446(ra) # 80002fe6 <argstr>
    80005e30:	02054b63          	bltz	a0,80005e66 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e34:	f6841683          	lh	a3,-152(s0)
    80005e38:	f6c41603          	lh	a2,-148(s0)
    80005e3c:	458d                	li	a1,3
    80005e3e:	f7040513          	addi	a0,s0,-144
    80005e42:	fffff097          	auipc	ra,0xfffff
    80005e46:	77c080e7          	jalr	1916(ra) # 800055be <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e4a:	cd11                	beqz	a0,80005e66 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e4c:	ffffe097          	auipc	ra,0xffffe
    80005e50:	066080e7          	jalr	102(ra) # 80003eb2 <iunlockput>
  end_op();
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	846080e7          	jalr	-1978(ra) # 8000469a <end_op>
  return 0;
    80005e5c:	4501                	li	a0,0
}
    80005e5e:	60ea                	ld	ra,152(sp)
    80005e60:	644a                	ld	s0,144(sp)
    80005e62:	610d                	addi	sp,sp,160
    80005e64:	8082                	ret
    end_op();
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	834080e7          	jalr	-1996(ra) # 8000469a <end_op>
    return -1;
    80005e6e:	557d                	li	a0,-1
    80005e70:	b7fd                	j	80005e5e <sys_mknod+0x6c>

0000000080005e72 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e72:	7135                	addi	sp,sp,-160
    80005e74:	ed06                	sd	ra,152(sp)
    80005e76:	e922                	sd	s0,144(sp)
    80005e78:	e526                	sd	s1,136(sp)
    80005e7a:	e14a                	sd	s2,128(sp)
    80005e7c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e7e:	ffffc097          	auipc	ra,0xffffc
    80005e82:	dee080e7          	jalr	-530(ra) # 80001c6c <myproc>
    80005e86:	892a                	mv	s2,a0
  
  begin_op();
    80005e88:	ffffe097          	auipc	ra,0xffffe
    80005e8c:	794080e7          	jalr	1940(ra) # 8000461c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e90:	08000613          	li	a2,128
    80005e94:	f6040593          	addi	a1,s0,-160
    80005e98:	4501                	li	a0,0
    80005e9a:	ffffd097          	auipc	ra,0xffffd
    80005e9e:	14c080e7          	jalr	332(ra) # 80002fe6 <argstr>
    80005ea2:	04054b63          	bltz	a0,80005ef8 <sys_chdir+0x86>
    80005ea6:	f6040513          	addi	a0,s0,-160
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	552080e7          	jalr	1362(ra) # 800043fc <namei>
    80005eb2:	84aa                	mv	s1,a0
    80005eb4:	c131                	beqz	a0,80005ef8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005eb6:	ffffe097          	auipc	ra,0xffffe
    80005eba:	d9a080e7          	jalr	-614(ra) # 80003c50 <ilock>
  if(ip->type != T_DIR){
    80005ebe:	04449703          	lh	a4,68(s1)
    80005ec2:	4785                	li	a5,1
    80005ec4:	04f71063          	bne	a4,a5,80005f04 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ec8:	8526                	mv	a0,s1
    80005eca:	ffffe097          	auipc	ra,0xffffe
    80005ece:	e48080e7          	jalr	-440(ra) # 80003d12 <iunlock>
  iput(p->cwd);
    80005ed2:	15093503          	ld	a0,336(s2)
    80005ed6:	ffffe097          	auipc	ra,0xffffe
    80005eda:	f34080e7          	jalr	-204(ra) # 80003e0a <iput>
  end_op();
    80005ede:	ffffe097          	auipc	ra,0xffffe
    80005ee2:	7bc080e7          	jalr	1980(ra) # 8000469a <end_op>
  p->cwd = ip;
    80005ee6:	14993823          	sd	s1,336(s2)
  return 0;
    80005eea:	4501                	li	a0,0
}
    80005eec:	60ea                	ld	ra,152(sp)
    80005eee:	644a                	ld	s0,144(sp)
    80005ef0:	64aa                	ld	s1,136(sp)
    80005ef2:	690a                	ld	s2,128(sp)
    80005ef4:	610d                	addi	sp,sp,160
    80005ef6:	8082                	ret
    end_op();
    80005ef8:	ffffe097          	auipc	ra,0xffffe
    80005efc:	7a2080e7          	jalr	1954(ra) # 8000469a <end_op>
    return -1;
    80005f00:	557d                	li	a0,-1
    80005f02:	b7ed                	j	80005eec <sys_chdir+0x7a>
    iunlockput(ip);
    80005f04:	8526                	mv	a0,s1
    80005f06:	ffffe097          	auipc	ra,0xffffe
    80005f0a:	fac080e7          	jalr	-84(ra) # 80003eb2 <iunlockput>
    end_op();
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	78c080e7          	jalr	1932(ra) # 8000469a <end_op>
    return -1;
    80005f16:	557d                	li	a0,-1
    80005f18:	bfd1                	j	80005eec <sys_chdir+0x7a>

0000000080005f1a <sys_exec>:

uint64
sys_exec(void)
{
    80005f1a:	7145                	addi	sp,sp,-464
    80005f1c:	e786                	sd	ra,456(sp)
    80005f1e:	e3a2                	sd	s0,448(sp)
    80005f20:	ff26                	sd	s1,440(sp)
    80005f22:	fb4a                	sd	s2,432(sp)
    80005f24:	f74e                	sd	s3,424(sp)
    80005f26:	f352                	sd	s4,416(sp)
    80005f28:	ef56                	sd	s5,408(sp)
    80005f2a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005f2c:	e3840593          	addi	a1,s0,-456
    80005f30:	4505                	li	a0,1
    80005f32:	ffffd097          	auipc	ra,0xffffd
    80005f36:	094080e7          	jalr	148(ra) # 80002fc6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f3a:	08000613          	li	a2,128
    80005f3e:	f4040593          	addi	a1,s0,-192
    80005f42:	4501                	li	a0,0
    80005f44:	ffffd097          	auipc	ra,0xffffd
    80005f48:	0a2080e7          	jalr	162(ra) # 80002fe6 <argstr>
    80005f4c:	87aa                	mv	a5,a0
    return -1;
    80005f4e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f50:	0c07c363          	bltz	a5,80006016 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005f54:	10000613          	li	a2,256
    80005f58:	4581                	li	a1,0
    80005f5a:	e4040513          	addi	a0,s0,-448
    80005f5e:	ffffb097          	auipc	ra,0xffffb
    80005f62:	ecc080e7          	jalr	-308(ra) # 80000e2a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f66:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f6a:	89a6                	mv	s3,s1
    80005f6c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f6e:	02000a13          	li	s4,32
    80005f72:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f76:	00391513          	slli	a0,s2,0x3
    80005f7a:	e3040593          	addi	a1,s0,-464
    80005f7e:	e3843783          	ld	a5,-456(s0)
    80005f82:	953e                	add	a0,a0,a5
    80005f84:	ffffd097          	auipc	ra,0xffffd
    80005f88:	f84080e7          	jalr	-124(ra) # 80002f08 <fetchaddr>
    80005f8c:	02054a63          	bltz	a0,80005fc0 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005f90:	e3043783          	ld	a5,-464(s0)
    80005f94:	c3b9                	beqz	a5,80005fda <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f96:	ffffb097          	auipc	ra,0xffffb
    80005f9a:	bf8080e7          	jalr	-1032(ra) # 80000b8e <kalloc>
    80005f9e:	85aa                	mv	a1,a0
    80005fa0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fa4:	cd11                	beqz	a0,80005fc0 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fa6:	6605                	lui	a2,0x1
    80005fa8:	e3043503          	ld	a0,-464(s0)
    80005fac:	ffffd097          	auipc	ra,0xffffd
    80005fb0:	fae080e7          	jalr	-82(ra) # 80002f5a <fetchstr>
    80005fb4:	00054663          	bltz	a0,80005fc0 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005fb8:	0905                	addi	s2,s2,1
    80005fba:	09a1                	addi	s3,s3,8
    80005fbc:	fb491be3          	bne	s2,s4,80005f72 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fc0:	f4040913          	addi	s2,s0,-192
    80005fc4:	6088                	ld	a0,0(s1)
    80005fc6:	c539                	beqz	a0,80006014 <sys_exec+0xfa>
    kfree(argv[i]);
    80005fc8:	ffffb097          	auipc	ra,0xffffb
    80005fcc:	a32080e7          	jalr	-1486(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fd0:	04a1                	addi	s1,s1,8
    80005fd2:	ff2499e3          	bne	s1,s2,80005fc4 <sys_exec+0xaa>
  return -1;
    80005fd6:	557d                	li	a0,-1
    80005fd8:	a83d                	j	80006016 <sys_exec+0xfc>
      argv[i] = 0;
    80005fda:	0a8e                	slli	s5,s5,0x3
    80005fdc:	fc0a8793          	addi	a5,s5,-64
    80005fe0:	00878ab3          	add	s5,a5,s0
    80005fe4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fe8:	e4040593          	addi	a1,s0,-448
    80005fec:	f4040513          	addi	a0,s0,-192
    80005ff0:	fffff097          	auipc	ra,0xfffff
    80005ff4:	16e080e7          	jalr	366(ra) # 8000515e <exec>
    80005ff8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ffa:	f4040993          	addi	s3,s0,-192
    80005ffe:	6088                	ld	a0,0(s1)
    80006000:	c901                	beqz	a0,80006010 <sys_exec+0xf6>
    kfree(argv[i]);
    80006002:	ffffb097          	auipc	ra,0xffffb
    80006006:	9f8080e7          	jalr	-1544(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000600a:	04a1                	addi	s1,s1,8
    8000600c:	ff3499e3          	bne	s1,s3,80005ffe <sys_exec+0xe4>
  return ret;
    80006010:	854a                	mv	a0,s2
    80006012:	a011                	j	80006016 <sys_exec+0xfc>
  return -1;
    80006014:	557d                	li	a0,-1
}
    80006016:	60be                	ld	ra,456(sp)
    80006018:	641e                	ld	s0,448(sp)
    8000601a:	74fa                	ld	s1,440(sp)
    8000601c:	795a                	ld	s2,432(sp)
    8000601e:	79ba                	ld	s3,424(sp)
    80006020:	7a1a                	ld	s4,416(sp)
    80006022:	6afa                	ld	s5,408(sp)
    80006024:	6179                	addi	sp,sp,464
    80006026:	8082                	ret

0000000080006028 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006028:	7139                	addi	sp,sp,-64
    8000602a:	fc06                	sd	ra,56(sp)
    8000602c:	f822                	sd	s0,48(sp)
    8000602e:	f426                	sd	s1,40(sp)
    80006030:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006032:	ffffc097          	auipc	ra,0xffffc
    80006036:	c3a080e7          	jalr	-966(ra) # 80001c6c <myproc>
    8000603a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000603c:	fd840593          	addi	a1,s0,-40
    80006040:	4501                	li	a0,0
    80006042:	ffffd097          	auipc	ra,0xffffd
    80006046:	f84080e7          	jalr	-124(ra) # 80002fc6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000604a:	fc840593          	addi	a1,s0,-56
    8000604e:	fd040513          	addi	a0,s0,-48
    80006052:	fffff097          	auipc	ra,0xfffff
    80006056:	dc2080e7          	jalr	-574(ra) # 80004e14 <pipealloc>
    return -1;
    8000605a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000605c:	0c054463          	bltz	a0,80006124 <sys_pipe+0xfc>
  fd0 = -1;
    80006060:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006064:	fd043503          	ld	a0,-48(s0)
    80006068:	fffff097          	auipc	ra,0xfffff
    8000606c:	514080e7          	jalr	1300(ra) # 8000557c <fdalloc>
    80006070:	fca42223          	sw	a0,-60(s0)
    80006074:	08054b63          	bltz	a0,8000610a <sys_pipe+0xe2>
    80006078:	fc843503          	ld	a0,-56(s0)
    8000607c:	fffff097          	auipc	ra,0xfffff
    80006080:	500080e7          	jalr	1280(ra) # 8000557c <fdalloc>
    80006084:	fca42023          	sw	a0,-64(s0)
    80006088:	06054863          	bltz	a0,800060f8 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000608c:	4691                	li	a3,4
    8000608e:	fc440613          	addi	a2,s0,-60
    80006092:	fd843583          	ld	a1,-40(s0)
    80006096:	68a8                	ld	a0,80(s1)
    80006098:	ffffb097          	auipc	ra,0xffffb
    8000609c:	712080e7          	jalr	1810(ra) # 800017aa <copyout>
    800060a0:	02054063          	bltz	a0,800060c0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060a4:	4691                	li	a3,4
    800060a6:	fc040613          	addi	a2,s0,-64
    800060aa:	fd843583          	ld	a1,-40(s0)
    800060ae:	0591                	addi	a1,a1,4
    800060b0:	68a8                	ld	a0,80(s1)
    800060b2:	ffffb097          	auipc	ra,0xffffb
    800060b6:	6f8080e7          	jalr	1784(ra) # 800017aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060ba:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060bc:	06055463          	bgez	a0,80006124 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800060c0:	fc442783          	lw	a5,-60(s0)
    800060c4:	07e9                	addi	a5,a5,26
    800060c6:	078e                	slli	a5,a5,0x3
    800060c8:	97a6                	add	a5,a5,s1
    800060ca:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060ce:	fc042783          	lw	a5,-64(s0)
    800060d2:	07e9                	addi	a5,a5,26
    800060d4:	078e                	slli	a5,a5,0x3
    800060d6:	94be                	add	s1,s1,a5
    800060d8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800060dc:	fd043503          	ld	a0,-48(s0)
    800060e0:	fffff097          	auipc	ra,0xfffff
    800060e4:	a04080e7          	jalr	-1532(ra) # 80004ae4 <fileclose>
    fileclose(wf);
    800060e8:	fc843503          	ld	a0,-56(s0)
    800060ec:	fffff097          	auipc	ra,0xfffff
    800060f0:	9f8080e7          	jalr	-1544(ra) # 80004ae4 <fileclose>
    return -1;
    800060f4:	57fd                	li	a5,-1
    800060f6:	a03d                	j	80006124 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800060f8:	fc442783          	lw	a5,-60(s0)
    800060fc:	0007c763          	bltz	a5,8000610a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006100:	07e9                	addi	a5,a5,26
    80006102:	078e                	slli	a5,a5,0x3
    80006104:	97a6                	add	a5,a5,s1
    80006106:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000610a:	fd043503          	ld	a0,-48(s0)
    8000610e:	fffff097          	auipc	ra,0xfffff
    80006112:	9d6080e7          	jalr	-1578(ra) # 80004ae4 <fileclose>
    fileclose(wf);
    80006116:	fc843503          	ld	a0,-56(s0)
    8000611a:	fffff097          	auipc	ra,0xfffff
    8000611e:	9ca080e7          	jalr	-1590(ra) # 80004ae4 <fileclose>
    return -1;
    80006122:	57fd                	li	a5,-1
}
    80006124:	853e                	mv	a0,a5
    80006126:	70e2                	ld	ra,56(sp)
    80006128:	7442                	ld	s0,48(sp)
    8000612a:	74a2                	ld	s1,40(sp)
    8000612c:	6121                	addi	sp,sp,64
    8000612e:	8082                	ret

0000000080006130 <kernelvec>:
    80006130:	7111                	addi	sp,sp,-256
    80006132:	e006                	sd	ra,0(sp)
    80006134:	e40a                	sd	sp,8(sp)
    80006136:	e80e                	sd	gp,16(sp)
    80006138:	ec12                	sd	tp,24(sp)
    8000613a:	f016                	sd	t0,32(sp)
    8000613c:	f41a                	sd	t1,40(sp)
    8000613e:	f81e                	sd	t2,48(sp)
    80006140:	fc22                	sd	s0,56(sp)
    80006142:	e0a6                	sd	s1,64(sp)
    80006144:	e4aa                	sd	a0,72(sp)
    80006146:	e8ae                	sd	a1,80(sp)
    80006148:	ecb2                	sd	a2,88(sp)
    8000614a:	f0b6                	sd	a3,96(sp)
    8000614c:	f4ba                	sd	a4,104(sp)
    8000614e:	f8be                	sd	a5,112(sp)
    80006150:	fcc2                	sd	a6,120(sp)
    80006152:	e146                	sd	a7,128(sp)
    80006154:	e54a                	sd	s2,136(sp)
    80006156:	e94e                	sd	s3,144(sp)
    80006158:	ed52                	sd	s4,152(sp)
    8000615a:	f156                	sd	s5,160(sp)
    8000615c:	f55a                	sd	s6,168(sp)
    8000615e:	f95e                	sd	s7,176(sp)
    80006160:	fd62                	sd	s8,184(sp)
    80006162:	e1e6                	sd	s9,192(sp)
    80006164:	e5ea                	sd	s10,200(sp)
    80006166:	e9ee                	sd	s11,208(sp)
    80006168:	edf2                	sd	t3,216(sp)
    8000616a:	f1f6                	sd	t4,224(sp)
    8000616c:	f5fa                	sd	t5,232(sp)
    8000616e:	f9fe                	sd	t6,240(sp)
    80006170:	c65fc0ef          	jal	ra,80002dd4 <kerneltrap>
    80006174:	6082                	ld	ra,0(sp)
    80006176:	6122                	ld	sp,8(sp)
    80006178:	61c2                	ld	gp,16(sp)
    8000617a:	7282                	ld	t0,32(sp)
    8000617c:	7322                	ld	t1,40(sp)
    8000617e:	73c2                	ld	t2,48(sp)
    80006180:	7462                	ld	s0,56(sp)
    80006182:	6486                	ld	s1,64(sp)
    80006184:	6526                	ld	a0,72(sp)
    80006186:	65c6                	ld	a1,80(sp)
    80006188:	6666                	ld	a2,88(sp)
    8000618a:	7686                	ld	a3,96(sp)
    8000618c:	7726                	ld	a4,104(sp)
    8000618e:	77c6                	ld	a5,112(sp)
    80006190:	7866                	ld	a6,120(sp)
    80006192:	688a                	ld	a7,128(sp)
    80006194:	692a                	ld	s2,136(sp)
    80006196:	69ca                	ld	s3,144(sp)
    80006198:	6a6a                	ld	s4,152(sp)
    8000619a:	7a8a                	ld	s5,160(sp)
    8000619c:	7b2a                	ld	s6,168(sp)
    8000619e:	7bca                	ld	s7,176(sp)
    800061a0:	7c6a                	ld	s8,184(sp)
    800061a2:	6c8e                	ld	s9,192(sp)
    800061a4:	6d2e                	ld	s10,200(sp)
    800061a6:	6dce                	ld	s11,208(sp)
    800061a8:	6e6e                	ld	t3,216(sp)
    800061aa:	7e8e                	ld	t4,224(sp)
    800061ac:	7f2e                	ld	t5,232(sp)
    800061ae:	7fce                	ld	t6,240(sp)
    800061b0:	6111                	addi	sp,sp,256
    800061b2:	10200073          	sret
    800061b6:	00000013          	nop
    800061ba:	00000013          	nop
    800061be:	0001                	nop

00000000800061c0 <timervec>:
    800061c0:	34051573          	csrrw	a0,mscratch,a0
    800061c4:	e10c                	sd	a1,0(a0)
    800061c6:	e510                	sd	a2,8(a0)
    800061c8:	e914                	sd	a3,16(a0)
    800061ca:	6d0c                	ld	a1,24(a0)
    800061cc:	7110                	ld	a2,32(a0)
    800061ce:	6194                	ld	a3,0(a1)
    800061d0:	96b2                	add	a3,a3,a2
    800061d2:	e194                	sd	a3,0(a1)
    800061d4:	4589                	li	a1,2
    800061d6:	14459073          	csrw	sip,a1
    800061da:	6914                	ld	a3,16(a0)
    800061dc:	6510                	ld	a2,8(a0)
    800061de:	610c                	ld	a1,0(a0)
    800061e0:	34051573          	csrrw	a0,mscratch,a0
    800061e4:	30200073          	mret
	...

00000000800061ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061ea:	1141                	addi	sp,sp,-16
    800061ec:	e422                	sd	s0,8(sp)
    800061ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061f0:	0c0007b7          	lui	a5,0xc000
    800061f4:	4705                	li	a4,1
    800061f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061f8:	c3d8                	sw	a4,4(a5)
}
    800061fa:	6422                	ld	s0,8(sp)
    800061fc:	0141                	addi	sp,sp,16
    800061fe:	8082                	ret

0000000080006200 <plicinithart>:

void
plicinithart(void)
{
    80006200:	1141                	addi	sp,sp,-16
    80006202:	e406                	sd	ra,8(sp)
    80006204:	e022                	sd	s0,0(sp)
    80006206:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	a38080e7          	jalr	-1480(ra) # 80001c40 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006210:	0085171b          	slliw	a4,a0,0x8
    80006214:	0c0027b7          	lui	a5,0xc002
    80006218:	97ba                	add	a5,a5,a4
    8000621a:	40200713          	li	a4,1026
    8000621e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006222:	00d5151b          	slliw	a0,a0,0xd
    80006226:	0c2017b7          	lui	a5,0xc201
    8000622a:	97aa                	add	a5,a5,a0
    8000622c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006230:	60a2                	ld	ra,8(sp)
    80006232:	6402                	ld	s0,0(sp)
    80006234:	0141                	addi	sp,sp,16
    80006236:	8082                	ret

0000000080006238 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006238:	1141                	addi	sp,sp,-16
    8000623a:	e406                	sd	ra,8(sp)
    8000623c:	e022                	sd	s0,0(sp)
    8000623e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006240:	ffffc097          	auipc	ra,0xffffc
    80006244:	a00080e7          	jalr	-1536(ra) # 80001c40 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006248:	00d5151b          	slliw	a0,a0,0xd
    8000624c:	0c2017b7          	lui	a5,0xc201
    80006250:	97aa                	add	a5,a5,a0
  return irq;
}
    80006252:	43c8                	lw	a0,4(a5)
    80006254:	60a2                	ld	ra,8(sp)
    80006256:	6402                	ld	s0,0(sp)
    80006258:	0141                	addi	sp,sp,16
    8000625a:	8082                	ret

000000008000625c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000625c:	1101                	addi	sp,sp,-32
    8000625e:	ec06                	sd	ra,24(sp)
    80006260:	e822                	sd	s0,16(sp)
    80006262:	e426                	sd	s1,8(sp)
    80006264:	1000                	addi	s0,sp,32
    80006266:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006268:	ffffc097          	auipc	ra,0xffffc
    8000626c:	9d8080e7          	jalr	-1576(ra) # 80001c40 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006270:	00d5151b          	slliw	a0,a0,0xd
    80006274:	0c2017b7          	lui	a5,0xc201
    80006278:	97aa                	add	a5,a5,a0
    8000627a:	c3c4                	sw	s1,4(a5)
}
    8000627c:	60e2                	ld	ra,24(sp)
    8000627e:	6442                	ld	s0,16(sp)
    80006280:	64a2                	ld	s1,8(sp)
    80006282:	6105                	addi	sp,sp,32
    80006284:	8082                	ret

0000000080006286 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006286:	1141                	addi	sp,sp,-16
    80006288:	e406                	sd	ra,8(sp)
    8000628a:	e022                	sd	s0,0(sp)
    8000628c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000628e:	479d                	li	a5,7
    80006290:	04a7cc63          	blt	a5,a0,800062e8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006294:	0023c797          	auipc	a5,0x23c
    80006298:	afc78793          	addi	a5,a5,-1284 # 80241d90 <disk>
    8000629c:	97aa                	add	a5,a5,a0
    8000629e:	0187c783          	lbu	a5,24(a5)
    800062a2:	ebb9                	bnez	a5,800062f8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062a4:	00451693          	slli	a3,a0,0x4
    800062a8:	0023c797          	auipc	a5,0x23c
    800062ac:	ae878793          	addi	a5,a5,-1304 # 80241d90 <disk>
    800062b0:	6398                	ld	a4,0(a5)
    800062b2:	9736                	add	a4,a4,a3
    800062b4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800062b8:	6398                	ld	a4,0(a5)
    800062ba:	9736                	add	a4,a4,a3
    800062bc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800062c0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800062c4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800062c8:	97aa                	add	a5,a5,a0
    800062ca:	4705                	li	a4,1
    800062cc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800062d0:	0023c517          	auipc	a0,0x23c
    800062d4:	ad850513          	addi	a0,a0,-1320 # 80241da8 <disk+0x18>
    800062d8:	ffffc097          	auipc	ra,0xffffc
    800062dc:	160080e7          	jalr	352(ra) # 80002438 <wakeup>
}
    800062e0:	60a2                	ld	ra,8(sp)
    800062e2:	6402                	ld	s0,0(sp)
    800062e4:	0141                	addi	sp,sp,16
    800062e6:	8082                	ret
    panic("free_desc 1");
    800062e8:	00002517          	auipc	a0,0x2
    800062ec:	58850513          	addi	a0,a0,1416 # 80008870 <syscalls+0x318>
    800062f0:	ffffa097          	auipc	ra,0xffffa
    800062f4:	250080e7          	jalr	592(ra) # 80000540 <panic>
    panic("free_desc 2");
    800062f8:	00002517          	auipc	a0,0x2
    800062fc:	58850513          	addi	a0,a0,1416 # 80008880 <syscalls+0x328>
    80006300:	ffffa097          	auipc	ra,0xffffa
    80006304:	240080e7          	jalr	576(ra) # 80000540 <panic>

0000000080006308 <virtio_disk_init>:
{
    80006308:	1101                	addi	sp,sp,-32
    8000630a:	ec06                	sd	ra,24(sp)
    8000630c:	e822                	sd	s0,16(sp)
    8000630e:	e426                	sd	s1,8(sp)
    80006310:	e04a                	sd	s2,0(sp)
    80006312:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006314:	00002597          	auipc	a1,0x2
    80006318:	57c58593          	addi	a1,a1,1404 # 80008890 <syscalls+0x338>
    8000631c:	0023c517          	auipc	a0,0x23c
    80006320:	b9c50513          	addi	a0,a0,-1124 # 80241eb8 <disk+0x128>
    80006324:	ffffb097          	auipc	ra,0xffffb
    80006328:	97a080e7          	jalr	-1670(ra) # 80000c9e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000632c:	100017b7          	lui	a5,0x10001
    80006330:	4398                	lw	a4,0(a5)
    80006332:	2701                	sext.w	a4,a4
    80006334:	747277b7          	lui	a5,0x74727
    80006338:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000633c:	14f71b63          	bne	a4,a5,80006492 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006340:	100017b7          	lui	a5,0x10001
    80006344:	43dc                	lw	a5,4(a5)
    80006346:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006348:	4709                	li	a4,2
    8000634a:	14e79463          	bne	a5,a4,80006492 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000634e:	100017b7          	lui	a5,0x10001
    80006352:	479c                	lw	a5,8(a5)
    80006354:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006356:	12e79e63          	bne	a5,a4,80006492 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000635a:	100017b7          	lui	a5,0x10001
    8000635e:	47d8                	lw	a4,12(a5)
    80006360:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006362:	554d47b7          	lui	a5,0x554d4
    80006366:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000636a:	12f71463          	bne	a4,a5,80006492 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000636e:	100017b7          	lui	a5,0x10001
    80006372:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006376:	4705                	li	a4,1
    80006378:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000637a:	470d                	li	a4,3
    8000637c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000637e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006380:	c7ffe6b7          	lui	a3,0xc7ffe
    80006384:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbc88f>
    80006388:	8f75                	and	a4,a4,a3
    8000638a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000638c:	472d                	li	a4,11
    8000638e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006390:	5bbc                	lw	a5,112(a5)
    80006392:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006396:	8ba1                	andi	a5,a5,8
    80006398:	10078563          	beqz	a5,800064a2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000639c:	100017b7          	lui	a5,0x10001
    800063a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800063a4:	43fc                	lw	a5,68(a5)
    800063a6:	2781                	sext.w	a5,a5
    800063a8:	10079563          	bnez	a5,800064b2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063ac:	100017b7          	lui	a5,0x10001
    800063b0:	5bdc                	lw	a5,52(a5)
    800063b2:	2781                	sext.w	a5,a5
  if(max == 0)
    800063b4:	10078763          	beqz	a5,800064c2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800063b8:	471d                	li	a4,7
    800063ba:	10f77c63          	bgeu	a4,a5,800064d2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800063be:	ffffa097          	auipc	ra,0xffffa
    800063c2:	7d0080e7          	jalr	2000(ra) # 80000b8e <kalloc>
    800063c6:	0023c497          	auipc	s1,0x23c
    800063ca:	9ca48493          	addi	s1,s1,-1590 # 80241d90 <disk>
    800063ce:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800063d0:	ffffa097          	auipc	ra,0xffffa
    800063d4:	7be080e7          	jalr	1982(ra) # 80000b8e <kalloc>
    800063d8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	7b4080e7          	jalr	1972(ra) # 80000b8e <kalloc>
    800063e2:	87aa                	mv	a5,a0
    800063e4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800063e6:	6088                	ld	a0,0(s1)
    800063e8:	cd6d                	beqz	a0,800064e2 <virtio_disk_init+0x1da>
    800063ea:	0023c717          	auipc	a4,0x23c
    800063ee:	9ae73703          	ld	a4,-1618(a4) # 80241d98 <disk+0x8>
    800063f2:	cb65                	beqz	a4,800064e2 <virtio_disk_init+0x1da>
    800063f4:	c7fd                	beqz	a5,800064e2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800063f6:	6605                	lui	a2,0x1
    800063f8:	4581                	li	a1,0
    800063fa:	ffffb097          	auipc	ra,0xffffb
    800063fe:	a30080e7          	jalr	-1488(ra) # 80000e2a <memset>
  memset(disk.avail, 0, PGSIZE);
    80006402:	0023c497          	auipc	s1,0x23c
    80006406:	98e48493          	addi	s1,s1,-1650 # 80241d90 <disk>
    8000640a:	6605                	lui	a2,0x1
    8000640c:	4581                	li	a1,0
    8000640e:	6488                	ld	a0,8(s1)
    80006410:	ffffb097          	auipc	ra,0xffffb
    80006414:	a1a080e7          	jalr	-1510(ra) # 80000e2a <memset>
  memset(disk.used, 0, PGSIZE);
    80006418:	6605                	lui	a2,0x1
    8000641a:	4581                	li	a1,0
    8000641c:	6888                	ld	a0,16(s1)
    8000641e:	ffffb097          	auipc	ra,0xffffb
    80006422:	a0c080e7          	jalr	-1524(ra) # 80000e2a <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006426:	100017b7          	lui	a5,0x10001
    8000642a:	4721                	li	a4,8
    8000642c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000642e:	4098                	lw	a4,0(s1)
    80006430:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006434:	40d8                	lw	a4,4(s1)
    80006436:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000643a:	6498                	ld	a4,8(s1)
    8000643c:	0007069b          	sext.w	a3,a4
    80006440:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006444:	9701                	srai	a4,a4,0x20
    80006446:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000644a:	6898                	ld	a4,16(s1)
    8000644c:	0007069b          	sext.w	a3,a4
    80006450:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006454:	9701                	srai	a4,a4,0x20
    80006456:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000645a:	4705                	li	a4,1
    8000645c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000645e:	00e48c23          	sb	a4,24(s1)
    80006462:	00e48ca3          	sb	a4,25(s1)
    80006466:	00e48d23          	sb	a4,26(s1)
    8000646a:	00e48da3          	sb	a4,27(s1)
    8000646e:	00e48e23          	sb	a4,28(s1)
    80006472:	00e48ea3          	sb	a4,29(s1)
    80006476:	00e48f23          	sb	a4,30(s1)
    8000647a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000647e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006482:	0727a823          	sw	s2,112(a5)
}
    80006486:	60e2                	ld	ra,24(sp)
    80006488:	6442                	ld	s0,16(sp)
    8000648a:	64a2                	ld	s1,8(sp)
    8000648c:	6902                	ld	s2,0(sp)
    8000648e:	6105                	addi	sp,sp,32
    80006490:	8082                	ret
    panic("could not find virtio disk");
    80006492:	00002517          	auipc	a0,0x2
    80006496:	40e50513          	addi	a0,a0,1038 # 800088a0 <syscalls+0x348>
    8000649a:	ffffa097          	auipc	ra,0xffffa
    8000649e:	0a6080e7          	jalr	166(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800064a2:	00002517          	auipc	a0,0x2
    800064a6:	41e50513          	addi	a0,a0,1054 # 800088c0 <syscalls+0x368>
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	096080e7          	jalr	150(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800064b2:	00002517          	auipc	a0,0x2
    800064b6:	42e50513          	addi	a0,a0,1070 # 800088e0 <syscalls+0x388>
    800064ba:	ffffa097          	auipc	ra,0xffffa
    800064be:	086080e7          	jalr	134(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800064c2:	00002517          	auipc	a0,0x2
    800064c6:	43e50513          	addi	a0,a0,1086 # 80008900 <syscalls+0x3a8>
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	076080e7          	jalr	118(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800064d2:	00002517          	auipc	a0,0x2
    800064d6:	44e50513          	addi	a0,a0,1102 # 80008920 <syscalls+0x3c8>
    800064da:	ffffa097          	auipc	ra,0xffffa
    800064de:	066080e7          	jalr	102(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800064e2:	00002517          	auipc	a0,0x2
    800064e6:	45e50513          	addi	a0,a0,1118 # 80008940 <syscalls+0x3e8>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	056080e7          	jalr	86(ra) # 80000540 <panic>

00000000800064f2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064f2:	7119                	addi	sp,sp,-128
    800064f4:	fc86                	sd	ra,120(sp)
    800064f6:	f8a2                	sd	s0,112(sp)
    800064f8:	f4a6                	sd	s1,104(sp)
    800064fa:	f0ca                	sd	s2,96(sp)
    800064fc:	ecce                	sd	s3,88(sp)
    800064fe:	e8d2                	sd	s4,80(sp)
    80006500:	e4d6                	sd	s5,72(sp)
    80006502:	e0da                	sd	s6,64(sp)
    80006504:	fc5e                	sd	s7,56(sp)
    80006506:	f862                	sd	s8,48(sp)
    80006508:	f466                	sd	s9,40(sp)
    8000650a:	f06a                	sd	s10,32(sp)
    8000650c:	ec6e                	sd	s11,24(sp)
    8000650e:	0100                	addi	s0,sp,128
    80006510:	8aaa                	mv	s5,a0
    80006512:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006514:	00c52d03          	lw	s10,12(a0)
    80006518:	001d1d1b          	slliw	s10,s10,0x1
    8000651c:	1d02                	slli	s10,s10,0x20
    8000651e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006522:	0023c517          	auipc	a0,0x23c
    80006526:	99650513          	addi	a0,a0,-1642 # 80241eb8 <disk+0x128>
    8000652a:	ffffb097          	auipc	ra,0xffffb
    8000652e:	804080e7          	jalr	-2044(ra) # 80000d2e <acquire>
  for(int i = 0; i < 3; i++){
    80006532:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006534:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006536:	0023cb97          	auipc	s7,0x23c
    8000653a:	85ab8b93          	addi	s7,s7,-1958 # 80241d90 <disk>
  for(int i = 0; i < 3; i++){
    8000653e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006540:	0023cc97          	auipc	s9,0x23c
    80006544:	978c8c93          	addi	s9,s9,-1672 # 80241eb8 <disk+0x128>
    80006548:	a08d                	j	800065aa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000654a:	00fb8733          	add	a4,s7,a5
    8000654e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006552:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006554:	0207c563          	bltz	a5,8000657e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006558:	2905                	addiw	s2,s2,1
    8000655a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000655c:	05690c63          	beq	s2,s6,800065b4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006560:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006562:	0023c717          	auipc	a4,0x23c
    80006566:	82e70713          	addi	a4,a4,-2002 # 80241d90 <disk>
    8000656a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000656c:	01874683          	lbu	a3,24(a4)
    80006570:	fee9                	bnez	a3,8000654a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006572:	2785                	addiw	a5,a5,1
    80006574:	0705                	addi	a4,a4,1
    80006576:	fe979be3          	bne	a5,s1,8000656c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000657a:	57fd                	li	a5,-1
    8000657c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000657e:	01205d63          	blez	s2,80006598 <virtio_disk_rw+0xa6>
    80006582:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006584:	000a2503          	lw	a0,0(s4)
    80006588:	00000097          	auipc	ra,0x0
    8000658c:	cfe080e7          	jalr	-770(ra) # 80006286 <free_desc>
      for(int j = 0; j < i; j++)
    80006590:	2d85                	addiw	s11,s11,1
    80006592:	0a11                	addi	s4,s4,4
    80006594:	ff2d98e3          	bne	s11,s2,80006584 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006598:	85e6                	mv	a1,s9
    8000659a:	0023c517          	auipc	a0,0x23c
    8000659e:	80e50513          	addi	a0,a0,-2034 # 80241da8 <disk+0x18>
    800065a2:	ffffc097          	auipc	ra,0xffffc
    800065a6:	e32080e7          	jalr	-462(ra) # 800023d4 <sleep>
  for(int i = 0; i < 3; i++){
    800065aa:	f8040a13          	addi	s4,s0,-128
{
    800065ae:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800065b0:	894e                	mv	s2,s3
    800065b2:	b77d                	j	80006560 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065b4:	f8042503          	lw	a0,-128(s0)
    800065b8:	00a50713          	addi	a4,a0,10
    800065bc:	0712                	slli	a4,a4,0x4

  if(write)
    800065be:	0023b797          	auipc	a5,0x23b
    800065c2:	7d278793          	addi	a5,a5,2002 # 80241d90 <disk>
    800065c6:	00e786b3          	add	a3,a5,a4
    800065ca:	01803633          	snez	a2,s8
    800065ce:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065d0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800065d4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065d8:	f6070613          	addi	a2,a4,-160
    800065dc:	6394                	ld	a3,0(a5)
    800065de:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065e0:	00870593          	addi	a1,a4,8
    800065e4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800065e6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065e8:	0007b803          	ld	a6,0(a5)
    800065ec:	9642                	add	a2,a2,a6
    800065ee:	46c1                	li	a3,16
    800065f0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065f2:	4585                	li	a1,1
    800065f4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800065f8:	f8442683          	lw	a3,-124(s0)
    800065fc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006600:	0692                	slli	a3,a3,0x4
    80006602:	9836                	add	a6,a6,a3
    80006604:	058a8613          	addi	a2,s5,88
    80006608:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000660c:	0007b803          	ld	a6,0(a5)
    80006610:	96c2                	add	a3,a3,a6
    80006612:	40000613          	li	a2,1024
    80006616:	c690                	sw	a2,8(a3)
  if(write)
    80006618:	001c3613          	seqz	a2,s8
    8000661c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006620:	00166613          	ori	a2,a2,1
    80006624:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006628:	f8842603          	lw	a2,-120(s0)
    8000662c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006630:	00250693          	addi	a3,a0,2
    80006634:	0692                	slli	a3,a3,0x4
    80006636:	96be                	add	a3,a3,a5
    80006638:	58fd                	li	a7,-1
    8000663a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000663e:	0612                	slli	a2,a2,0x4
    80006640:	9832                	add	a6,a6,a2
    80006642:	f9070713          	addi	a4,a4,-112
    80006646:	973e                	add	a4,a4,a5
    80006648:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000664c:	6398                	ld	a4,0(a5)
    8000664e:	9732                	add	a4,a4,a2
    80006650:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006652:	4609                	li	a2,2
    80006654:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006658:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000665c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006660:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006664:	6794                	ld	a3,8(a5)
    80006666:	0026d703          	lhu	a4,2(a3)
    8000666a:	8b1d                	andi	a4,a4,7
    8000666c:	0706                	slli	a4,a4,0x1
    8000666e:	96ba                	add	a3,a3,a4
    80006670:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006674:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006678:	6798                	ld	a4,8(a5)
    8000667a:	00275783          	lhu	a5,2(a4)
    8000667e:	2785                	addiw	a5,a5,1
    80006680:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006684:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006688:	100017b7          	lui	a5,0x10001
    8000668c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006690:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006694:	0023c917          	auipc	s2,0x23c
    80006698:	82490913          	addi	s2,s2,-2012 # 80241eb8 <disk+0x128>
  while(b->disk == 1) {
    8000669c:	4485                	li	s1,1
    8000669e:	00b79c63          	bne	a5,a1,800066b6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800066a2:	85ca                	mv	a1,s2
    800066a4:	8556                	mv	a0,s5
    800066a6:	ffffc097          	auipc	ra,0xffffc
    800066aa:	d2e080e7          	jalr	-722(ra) # 800023d4 <sleep>
  while(b->disk == 1) {
    800066ae:	004aa783          	lw	a5,4(s5)
    800066b2:	fe9788e3          	beq	a5,s1,800066a2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800066b6:	f8042903          	lw	s2,-128(s0)
    800066ba:	00290713          	addi	a4,s2,2
    800066be:	0712                	slli	a4,a4,0x4
    800066c0:	0023b797          	auipc	a5,0x23b
    800066c4:	6d078793          	addi	a5,a5,1744 # 80241d90 <disk>
    800066c8:	97ba                	add	a5,a5,a4
    800066ca:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800066ce:	0023b997          	auipc	s3,0x23b
    800066d2:	6c298993          	addi	s3,s3,1730 # 80241d90 <disk>
    800066d6:	00491713          	slli	a4,s2,0x4
    800066da:	0009b783          	ld	a5,0(s3)
    800066de:	97ba                	add	a5,a5,a4
    800066e0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066e4:	854a                	mv	a0,s2
    800066e6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066ea:	00000097          	auipc	ra,0x0
    800066ee:	b9c080e7          	jalr	-1124(ra) # 80006286 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066f2:	8885                	andi	s1,s1,1
    800066f4:	f0ed                	bnez	s1,800066d6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066f6:	0023b517          	auipc	a0,0x23b
    800066fa:	7c250513          	addi	a0,a0,1986 # 80241eb8 <disk+0x128>
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	6e4080e7          	jalr	1764(ra) # 80000de2 <release>
}
    80006706:	70e6                	ld	ra,120(sp)
    80006708:	7446                	ld	s0,112(sp)
    8000670a:	74a6                	ld	s1,104(sp)
    8000670c:	7906                	ld	s2,96(sp)
    8000670e:	69e6                	ld	s3,88(sp)
    80006710:	6a46                	ld	s4,80(sp)
    80006712:	6aa6                	ld	s5,72(sp)
    80006714:	6b06                	ld	s6,64(sp)
    80006716:	7be2                	ld	s7,56(sp)
    80006718:	7c42                	ld	s8,48(sp)
    8000671a:	7ca2                	ld	s9,40(sp)
    8000671c:	7d02                	ld	s10,32(sp)
    8000671e:	6de2                	ld	s11,24(sp)
    80006720:	6109                	addi	sp,sp,128
    80006722:	8082                	ret

0000000080006724 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006724:	1101                	addi	sp,sp,-32
    80006726:	ec06                	sd	ra,24(sp)
    80006728:	e822                	sd	s0,16(sp)
    8000672a:	e426                	sd	s1,8(sp)
    8000672c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000672e:	0023b497          	auipc	s1,0x23b
    80006732:	66248493          	addi	s1,s1,1634 # 80241d90 <disk>
    80006736:	0023b517          	auipc	a0,0x23b
    8000673a:	78250513          	addi	a0,a0,1922 # 80241eb8 <disk+0x128>
    8000673e:	ffffa097          	auipc	ra,0xffffa
    80006742:	5f0080e7          	jalr	1520(ra) # 80000d2e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006746:	10001737          	lui	a4,0x10001
    8000674a:	533c                	lw	a5,96(a4)
    8000674c:	8b8d                	andi	a5,a5,3
    8000674e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006750:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006754:	689c                	ld	a5,16(s1)
    80006756:	0204d703          	lhu	a4,32(s1)
    8000675a:	0027d783          	lhu	a5,2(a5)
    8000675e:	04f70863          	beq	a4,a5,800067ae <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006762:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006766:	6898                	ld	a4,16(s1)
    80006768:	0204d783          	lhu	a5,32(s1)
    8000676c:	8b9d                	andi	a5,a5,7
    8000676e:	078e                	slli	a5,a5,0x3
    80006770:	97ba                	add	a5,a5,a4
    80006772:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006774:	00278713          	addi	a4,a5,2
    80006778:	0712                	slli	a4,a4,0x4
    8000677a:	9726                	add	a4,a4,s1
    8000677c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006780:	e721                	bnez	a4,800067c8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006782:	0789                	addi	a5,a5,2
    80006784:	0792                	slli	a5,a5,0x4
    80006786:	97a6                	add	a5,a5,s1
    80006788:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000678a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000678e:	ffffc097          	auipc	ra,0xffffc
    80006792:	caa080e7          	jalr	-854(ra) # 80002438 <wakeup>

    disk.used_idx += 1;
    80006796:	0204d783          	lhu	a5,32(s1)
    8000679a:	2785                	addiw	a5,a5,1
    8000679c:	17c2                	slli	a5,a5,0x30
    8000679e:	93c1                	srli	a5,a5,0x30
    800067a0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067a4:	6898                	ld	a4,16(s1)
    800067a6:	00275703          	lhu	a4,2(a4)
    800067aa:	faf71ce3          	bne	a4,a5,80006762 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800067ae:	0023b517          	auipc	a0,0x23b
    800067b2:	70a50513          	addi	a0,a0,1802 # 80241eb8 <disk+0x128>
    800067b6:	ffffa097          	auipc	ra,0xffffa
    800067ba:	62c080e7          	jalr	1580(ra) # 80000de2 <release>
}
    800067be:	60e2                	ld	ra,24(sp)
    800067c0:	6442                	ld	s0,16(sp)
    800067c2:	64a2                	ld	s1,8(sp)
    800067c4:	6105                	addi	sp,sp,32
    800067c6:	8082                	ret
      panic("virtio_disk_intr status");
    800067c8:	00002517          	auipc	a0,0x2
    800067cc:	19050513          	addi	a0,a0,400 # 80008958 <syscalls+0x400>
    800067d0:	ffffa097          	auipc	ra,0xffffa
    800067d4:	d70080e7          	jalr	-656(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
