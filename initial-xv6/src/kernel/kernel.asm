
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a6010113          	addi	sp,sp,-1440 # 80008a60 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8ce70713          	addi	a4,a4,-1842 # 80008920 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	3ec78793          	addi	a5,a5,1004 # 80006450 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb46f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	692080e7          	jalr	1682(ra) # 800027be <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
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
    8000018e:	8d650513          	addi	a0,a0,-1834 # 80010a60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8c648493          	addi	s1,s1,-1850 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	95690913          	addi	s2,s2,-1706 # 80010af8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	440080e7          	jalr	1088(ra) # 80002608 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	17e080e7          	jalr	382(ra) # 80002354 <sleep>
    while(cons.r == cons.w){
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
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	556080e7          	jalr	1366(ra) # 80002768 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	83a50513          	addi	a0,a0,-1990 # 80010a60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	82450513          	addi	a0,a0,-2012 # 80010a60 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
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
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	88f72323          	sw	a5,-1914(a4) # 80010af8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	79450513          	addi	a0,a0,1940 # 80010a60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	522080e7          	jalr	1314(ra) # 80002814 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	76650513          	addi	a0,a0,1894 # 80010a60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	74270713          	addi	a4,a4,1858 # 80010a60 <cons>
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
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	71878793          	addi	a5,a5,1816 # 80010a60 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7827a783          	lw	a5,1922(a5) # 80010af8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6d670713          	addi	a4,a4,1750 # 80010a60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6c648493          	addi	s1,s1,1734 # 80010a60 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	68a70713          	addi	a4,a4,1674 # 80010a60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72a23          	sw	a5,1812(a4) # 80010b00 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	64e78793          	addi	a5,a5,1614 # 80010a60 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6cc7a323          	sw	a2,1734(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ba50513          	addi	a0,a0,1722 # 80010af8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f72080e7          	jalr	-142(ra) # 800023b8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	60050513          	addi	a0,a0,1536 # 80010a60 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	d8078793          	addi	a5,a5,-640 # 800221f8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
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

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
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
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5c07ab23          	sw	zero,1494(a5) # 80010b20 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	36f72123          	sw	a5,866(a4) # 800088e0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	566dad83          	lw	s11,1382(s11) # 80010b20 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	51050513          	addi	a0,a0,1296 # 80010b08 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3b250513          	addi	a0,a0,946 # 80010b08 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	39648493          	addi	s1,s1,918 # 80010b08 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	35650513          	addi	a0,a0,854 # 80010b28 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0e27a783          	lw	a5,226(a5) # 800088e0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0b27b783          	ld	a5,178(a5) # 800088e8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0b273703          	ld	a4,178(a4) # 800088f0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2c8a0a13          	addi	s4,s4,712 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	08048493          	addi	s1,s1,128 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	08098993          	addi	s3,s3,128 # 800088f0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	b26080e7          	jalr	-1242(ra) # 800023b8 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	25a50513          	addi	a0,a0,602 # 80010b28 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0027a783          	lw	a5,2(a5) # 800088e0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	00873703          	ld	a4,8(a4) # 800088f0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	ff87b783          	ld	a5,-8(a5) # 800088e8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	22c98993          	addi	s3,s3,556 # 80010b28 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fe448493          	addi	s1,s1,-28 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fe490913          	addi	s2,s2,-28 # 800088f0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	a38080e7          	jalr	-1480(ra) # 80002354 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1f648493          	addi	s1,s1,502 # 80010b28 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fae7b523          	sd	a4,-86(a5) # 800088f0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	16c48493          	addi	s1,s1,364 # 80010b28 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00023797          	auipc	a5,0x23
    80000a02:	99278793          	addi	a5,a5,-1646 # 80023390 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	14290913          	addi	s2,s2,322 # 80010b60 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0a650513          	addi	a0,a0,166 # 80010b60 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00023517          	auipc	a0,0x23
    80000ad2:	8c250513          	addi	a0,a0,-1854 # 80023390 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	07048493          	addi	s1,s1,112 # 80010b60 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	05850513          	addi	a0,a0,88 # 80010b60 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	02c50513          	addi	a0,a0,44 # 80010b60 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a7070713          	addi	a4,a4,-1424 # 800088f8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	c40080e7          	jalr	-960(ra) # 80002afe <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	5ca080e7          	jalr	1482(ra) # 80006490 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	01c080e7          	jalr	28(ra) # 80001eea <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	ba0080e7          	jalr	-1120(ra) # 80002ad6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	bc0080e7          	jalr	-1088(ra) # 80002afe <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	534080e7          	jalr	1332(ra) # 8000647a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	542080e7          	jalr	1346(ra) # 80006490 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	622080e7          	jalr	1570(ra) # 80003578 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	cc6080e7          	jalr	-826(ra) # 80003c24 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	c64080e7          	jalr	-924(ra) # 80004bca <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	62a080e7          	jalr	1578(ra) # 80006598 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d56080e7          	jalr	-682(ra) # 80001ccc <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72a23          	sw	a5,-1676(a4) # 800088f8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9687b783          	ld	a5,-1688(a5) # 80008900 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6aa7b623          	sd	a0,1708(a5) # 80008900 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	76448493          	addi	s1,s1,1892 # 80010fb0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	74aa0a13          	addi	s4,s4,1866 # 80017fb0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8599                	srai	a1,a1,0x6
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	1c048493          	addi	s1,s1,448
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	29850513          	addi	a0,a0,664 # 80010b80 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	29850513          	addi	a0,a0,664 # 80010b98 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6a048493          	addi	s1,s1,1696 # 80010fb0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	67e98993          	addi	s3,s3,1662 # 80017fb0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8799                	srai	a5,a5,0x6
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	1c048493          	addi	s1,s1,448
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	21450513          	addi	a0,a0,532 # 80010bb0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1bc70713          	addi	a4,a4,444 # 80010b80 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e947a783          	lw	a5,-364(a5) # 80008890 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	206080e7          	jalr	518(ra) # 80002c0c <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e607ad23          	sw	zero,-390(a5) # 80008890 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	184080e7          	jalr	388(ra) # 80003ba4 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	14a90913          	addi	s2,s2,330 # 80010b80 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e4c78793          	addi	a5,a5,-436 # 80008894 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a52080e7          	jalr	-1454(ra) # 8000152c <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2c080e7          	jalr	-1492(ra) # 8000152c <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e2080e7          	jalr	-1566(ra) # 8000152c <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7c080e7          	jalr	-388(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3ee48493          	addi	s1,s1,1006 # 80010fb0 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	3e690913          	addi	s2,s2,998 # 80017fb0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	1c048493          	addi	s1,s1,448
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a869                	j	80001c8e <allocproc+0xd8>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  p->cur_ticks = 0;
    80001c04:	1804a223          	sw	zero,388(s1)
  p->kernelornot = 0;
    80001c08:	1804aa23          	sw	zero,404(s1)
  p->creation_time = ticks;
    80001c0c:	00007717          	auipc	a4,0x7
    80001c10:	d0472703          	lw	a4,-764(a4) # 80008910 <ticks>
    80001c14:	18e4ac23          	sw	a4,408(s1)
  p->priority = 0;
    80001c18:	1804ae23          	sw	zero,412(s1)
  p->queticks = 1;
    80001c1c:	1af4a023          	sw	a5,416(s1)
  p->prevticks = 1;
    80001c20:	1af4a423          	sw	a5,424(s1)
  p->wait_time = 0;
    80001c24:	1a04a223          	sw	zero,420(s1)
  p->que0time = ticks;
    80001c28:	1ae4a623          	sw	a4,428(s1)
  p->que1time = 0;
    80001c2c:	1a04a823          	sw	zero,432(s1)
  p->que2time = 0;
    80001c30:	1a04aa23          	sw	zero,436(s1)
  p->que3time = 0;
    80001c34:	1a04ac23          	sw	zero,440(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	eae080e7          	jalr	-338(ra) # 80000ae6 <kalloc>
    80001c40:	892a                	mv	s2,a0
    80001c42:	eca8                	sd	a0,88(s1)
    80001c44:	cd21                	beqz	a0,80001c9c <allocproc+0xe6>
  p->pagetable = proc_pagetable(p);
    80001c46:	8526                	mv	a0,s1
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	e28080e7          	jalr	-472(ra) # 80001a70 <proc_pagetable>
    80001c50:	892a                	mv	s2,a0
    80001c52:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c54:	c125                	beqz	a0,80001cb4 <allocproc+0xfe>
  memset(&p->context, 0, sizeof(p->context));
    80001c56:	07000613          	li	a2,112
    80001c5a:	4581                	li	a1,0
    80001c5c:	06048513          	addi	a0,s1,96
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	072080e7          	jalr	114(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c68:	00000797          	auipc	a5,0x0
    80001c6c:	d7c78793          	addi	a5,a5,-644 # 800019e4 <forkret>
    80001c70:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c72:	60bc                	ld	a5,64(s1)
    80001c74:	6705                	lui	a4,0x1
    80001c76:	97ba                	add	a5,a5,a4
    80001c78:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c7a:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c7e:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c82:	00007797          	auipc	a5,0x7
    80001c86:	c8e7a783          	lw	a5,-882(a5) # 80008910 <ticks>
    80001c8a:	16f4a623          	sw	a5,364(s1)
}
    80001c8e:	8526                	mv	a0,s1
    80001c90:	60e2                	ld	ra,24(sp)
    80001c92:	6442                	ld	s0,16(sp)
    80001c94:	64a2                	ld	s1,8(sp)
    80001c96:	6902                	ld	s2,0(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret
    freeproc(p);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	ec0080e7          	jalr	-320(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	fe2080e7          	jalr	-30(ra) # 80000c8a <release>
    return 0;
    80001cb0:	84ca                	mv	s1,s2
    80001cb2:	bff1                	j	80001c8e <allocproc+0xd8>
    freeproc(p);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	ea8080e7          	jalr	-344(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	fca080e7          	jalr	-54(ra) # 80000c8a <release>
    return 0;
    80001cc8:	84ca                	mv	s1,s2
    80001cca:	b7d1                	j	80001c8e <allocproc+0xd8>

0000000080001ccc <userinit>:
{
    80001ccc:	1101                	addi	sp,sp,-32
    80001cce:	ec06                	sd	ra,24(sp)
    80001cd0:	e822                	sd	s0,16(sp)
    80001cd2:	e426                	sd	s1,8(sp)
    80001cd4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	ee0080e7          	jalr	-288(ra) # 80001bb6 <allocproc>
    80001cde:	84aa                	mv	s1,a0
  initproc = p;
    80001ce0:	00007797          	auipc	a5,0x7
    80001ce4:	c2a7b423          	sd	a0,-984(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ce8:	03400613          	li	a2,52
    80001cec:	00007597          	auipc	a1,0x7
    80001cf0:	bb458593          	addi	a1,a1,-1100 # 800088a0 <initcode>
    80001cf4:	6928                	ld	a0,80(a0)
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	660080e7          	jalr	1632(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cfe:	6785                	lui	a5,0x1
    80001d00:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d02:	6cb8                	ld	a4,88(s1)
    80001d04:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d08:	6cb8                	ld	a4,88(s1)
    80001d0a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d0c:	4641                	li	a2,16
    80001d0e:	00006597          	auipc	a1,0x6
    80001d12:	4f258593          	addi	a1,a1,1266 # 80008200 <digits+0x1c0>
    80001d16:	15848513          	addi	a0,s1,344
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	102080e7          	jalr	258(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d22:	00006517          	auipc	a0,0x6
    80001d26:	4ee50513          	addi	a0,a0,1262 # 80008210 <digits+0x1d0>
    80001d2a:	00003097          	auipc	ra,0x3
    80001d2e:	89c080e7          	jalr	-1892(ra) # 800045c6 <namei>
    80001d32:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d36:	478d                	li	a5,3
    80001d38:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	f4e080e7          	jalr	-178(ra) # 80000c8a <release>
}
    80001d44:	60e2                	ld	ra,24(sp)
    80001d46:	6442                	ld	s0,16(sp)
    80001d48:	64a2                	ld	s1,8(sp)
    80001d4a:	6105                	addi	sp,sp,32
    80001d4c:	8082                	ret

0000000080001d4e <growproc>:
{
    80001d4e:	1101                	addi	sp,sp,-32
    80001d50:	ec06                	sd	ra,24(sp)
    80001d52:	e822                	sd	s0,16(sp)
    80001d54:	e426                	sd	s1,8(sp)
    80001d56:	e04a                	sd	s2,0(sp)
    80001d58:	1000                	addi	s0,sp,32
    80001d5a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	c50080e7          	jalr	-944(ra) # 800019ac <myproc>
    80001d64:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d66:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d68:	01204c63          	bgtz	s2,80001d80 <growproc+0x32>
  else if (n < 0)
    80001d6c:	02094663          	bltz	s2,80001d98 <growproc+0x4a>
  p->sz = sz;
    80001d70:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d72:	4501                	li	a0,0
}
    80001d74:	60e2                	ld	ra,24(sp)
    80001d76:	6442                	ld	s0,16(sp)
    80001d78:	64a2                	ld	s1,8(sp)
    80001d7a:	6902                	ld	s2,0(sp)
    80001d7c:	6105                	addi	sp,sp,32
    80001d7e:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d80:	4691                	li	a3,4
    80001d82:	00b90633          	add	a2,s2,a1
    80001d86:	6928                	ld	a0,80(a0)
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	688080e7          	jalr	1672(ra) # 80001410 <uvmalloc>
    80001d90:	85aa                	mv	a1,a0
    80001d92:	fd79                	bnez	a0,80001d70 <growproc+0x22>
      return -1;
    80001d94:	557d                	li	a0,-1
    80001d96:	bff9                	j	80001d74 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d98:	00b90633          	add	a2,s2,a1
    80001d9c:	6928                	ld	a0,80(a0)
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	62a080e7          	jalr	1578(ra) # 800013c8 <uvmdealloc>
    80001da6:	85aa                	mv	a1,a0
    80001da8:	b7e1                	j	80001d70 <growproc+0x22>

0000000080001daa <fork>:
{
    80001daa:	7139                	addi	sp,sp,-64
    80001dac:	fc06                	sd	ra,56(sp)
    80001dae:	f822                	sd	s0,48(sp)
    80001db0:	f426                	sd	s1,40(sp)
    80001db2:	f04a                	sd	s2,32(sp)
    80001db4:	ec4e                	sd	s3,24(sp)
    80001db6:	e852                	sd	s4,16(sp)
    80001db8:	e456                	sd	s5,8(sp)
    80001dba:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	bf0080e7          	jalr	-1040(ra) # 800019ac <myproc>
    80001dc4:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dc6:	00000097          	auipc	ra,0x0
    80001dca:	df0080e7          	jalr	-528(ra) # 80001bb6 <allocproc>
    80001dce:	10050c63          	beqz	a0,80001ee6 <fork+0x13c>
    80001dd2:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dd4:	048ab603          	ld	a2,72(s5)
    80001dd8:	692c                	ld	a1,80(a0)
    80001dda:	050ab503          	ld	a0,80(s5)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	786080e7          	jalr	1926(ra) # 80001564 <uvmcopy>
    80001de6:	04054863          	bltz	a0,80001e36 <fork+0x8c>
  np->sz = p->sz;
    80001dea:	048ab783          	ld	a5,72(s5)
    80001dee:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001df2:	058ab683          	ld	a3,88(s5)
    80001df6:	87b6                	mv	a5,a3
    80001df8:	058a3703          	ld	a4,88(s4)
    80001dfc:	12068693          	addi	a3,a3,288
    80001e00:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e04:	6788                	ld	a0,8(a5)
    80001e06:	6b8c                	ld	a1,16(a5)
    80001e08:	6f90                	ld	a2,24(a5)
    80001e0a:	01073023          	sd	a6,0(a4)
    80001e0e:	e708                	sd	a0,8(a4)
    80001e10:	eb0c                	sd	a1,16(a4)
    80001e12:	ef10                	sd	a2,24(a4)
    80001e14:	02078793          	addi	a5,a5,32
    80001e18:	02070713          	addi	a4,a4,32
    80001e1c:	fed792e3          	bne	a5,a3,80001e00 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e20:	058a3783          	ld	a5,88(s4)
    80001e24:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e28:	0d0a8493          	addi	s1,s5,208
    80001e2c:	0d0a0913          	addi	s2,s4,208
    80001e30:	150a8993          	addi	s3,s5,336
    80001e34:	a00d                	j	80001e56 <fork+0xac>
    freeproc(np);
    80001e36:	8552                	mv	a0,s4
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	d26080e7          	jalr	-730(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e40:	8552                	mv	a0,s4
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	e48080e7          	jalr	-440(ra) # 80000c8a <release>
    return -1;
    80001e4a:	597d                	li	s2,-1
    80001e4c:	a059                	j	80001ed2 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e4e:	04a1                	addi	s1,s1,8
    80001e50:	0921                	addi	s2,s2,8
    80001e52:	01348b63          	beq	s1,s3,80001e68 <fork+0xbe>
    if (p->ofile[i])
    80001e56:	6088                	ld	a0,0(s1)
    80001e58:	d97d                	beqz	a0,80001e4e <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e5a:	00003097          	auipc	ra,0x3
    80001e5e:	e02080e7          	jalr	-510(ra) # 80004c5c <filedup>
    80001e62:	00a93023          	sd	a0,0(s2)
    80001e66:	b7e5                	j	80001e4e <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e68:	150ab503          	ld	a0,336(s5)
    80001e6c:	00002097          	auipc	ra,0x2
    80001e70:	f76080e7          	jalr	-138(ra) # 80003de2 <idup>
    80001e74:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e78:	4641                	li	a2,16
    80001e7a:	158a8593          	addi	a1,s5,344
    80001e7e:	158a0513          	addi	a0,s4,344
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	f9a080e7          	jalr	-102(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e8a:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e8e:	8552                	mv	a0,s4
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	dfa080e7          	jalr	-518(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e98:	0000f497          	auipc	s1,0xf
    80001e9c:	d0048493          	addi	s1,s1,-768 # 80010b98 <wait_lock>
    80001ea0:	8526                	mv	a0,s1
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	d34080e7          	jalr	-716(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001eaa:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001eae:	8526                	mv	a0,s1
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	dda080e7          	jalr	-550(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001eb8:	8552                	mv	a0,s4
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	d1c080e7          	jalr	-740(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001ec2:	478d                	li	a5,3
    80001ec4:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ec8:	8552                	mv	a0,s4
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	dc0080e7          	jalr	-576(ra) # 80000c8a <release>
}
    80001ed2:	854a                	mv	a0,s2
    80001ed4:	70e2                	ld	ra,56(sp)
    80001ed6:	7442                	ld	s0,48(sp)
    80001ed8:	74a2                	ld	s1,40(sp)
    80001eda:	7902                	ld	s2,32(sp)
    80001edc:	69e2                	ld	s3,24(sp)
    80001ede:	6a42                	ld	s4,16(sp)
    80001ee0:	6aa2                	ld	s5,8(sp)
    80001ee2:	6121                	addi	sp,sp,64
    80001ee4:	8082                	ret
    return -1;
    80001ee6:	597d                	li	s2,-1
    80001ee8:	b7ed                	j	80001ed2 <fork+0x128>

0000000080001eea <scheduler>:
{
    80001eea:	711d                	addi	sp,sp,-96
    80001eec:	ec86                	sd	ra,88(sp)
    80001eee:	e8a2                	sd	s0,80(sp)
    80001ef0:	e4a6                	sd	s1,72(sp)
    80001ef2:	e0ca                	sd	s2,64(sp)
    80001ef4:	fc4e                	sd	s3,56(sp)
    80001ef6:	f852                	sd	s4,48(sp)
    80001ef8:	f456                	sd	s5,40(sp)
    80001efa:	f05a                	sd	s6,32(sp)
    80001efc:	ec5e                	sd	s7,24(sp)
    80001efe:	e862                	sd	s8,16(sp)
    80001f00:	e466                	sd	s9,8(sp)
    80001f02:	e06a                	sd	s10,0(sp)
    80001f04:	1080                	addi	s0,sp,96
    80001f06:	8792                	mv	a5,tp
  int id = r_tp();
    80001f08:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f0a:	00779c13          	slli	s8,a5,0x7
    80001f0e:	0000f717          	auipc	a4,0xf
    80001f12:	c7270713          	addi	a4,a4,-910 # 80010b80 <pid_lock>
    80001f16:	9762                	add	a4,a4,s8
    80001f18:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &p->context);
    80001f1c:	0000f717          	auipc	a4,0xf
    80001f20:	c9c70713          	addi	a4,a4,-868 # 80010bb8 <cpus+0x8>
    80001f24:	9c3a                	add	s8,s8,a4
        if (p->state == RUNNABLE && p->priority == 0)
    80001f26:	490d                	li	s2,3
          if(p->wait_time>2)
    80001f28:	4b09                	li	s6,2
            c->proc = p;
    80001f2a:	079e                	slli	a5,a5,0x7
    80001f2c:	0000fb97          	auipc	s7,0xf
    80001f30:	c54b8b93          	addi	s7,s7,-940 # 80010b80 <pid_lock>
    80001f34:	9bbe                	add	s7,s7,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f36:	00016997          	auipc	s3,0x16
    80001f3a:	07a98993          	addi	s3,s3,122 # 80017fb0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f3e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f42:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f46:	10079073          	csrw	sstatus,a5
    80001f4a:	0000fa97          	auipc	s5,0xf
    80001f4e:	0c6a8a93          	addi	s5,s5,198 # 80011010 <proc+0x60>
    80001f52:	8a56                	mv	s4,s5
    80001f54:	0000f497          	auipc	s1,0xf
    80001f58:	05c48493          	addi	s1,s1,92 # 80010fb0 <proc>
            printf("1. HIIII");
    80001f5c:	00006d17          	auipc	s10,0x6
    80001f60:	2bcd0d13          	addi	s10,s10,700 # 80008218 <digits+0x1d8>
            if (p->queticks == 15)
    80001f64:	4cbd                	li	s9,15
    80001f66:	a815                	j	80001f9a <scheduler+0xb0>
          p->wait_time = 0;
    80001f68:	1a04a223          	sw	zero,420(s1)
          p->state = RUNNING;
    80001f6c:	4791                	li	a5,4
    80001f6e:	cc9c                	sw	a5,24(s1)
          c->proc = p;
    80001f70:	029bb823          	sd	s1,48(s7)
          swtch(&c->context, &p->context);
    80001f74:	85d2                	mv	a1,s4
    80001f76:	8562                	mv	a0,s8
    80001f78:	00001097          	auipc	ra,0x1
    80001f7c:	af4080e7          	jalr	-1292(ra) # 80002a6c <swtch>
          c->proc = 0;
    80001f80:	020bb823          	sd	zero,48(s7)
        release(&p->lock);
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d04080e7          	jalr	-764(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f8e:	1c048493          	addi	s1,s1,448
    80001f92:	1c0a0a13          	addi	s4,s4,448
    80001f96:	09348c63          	beq	s1,s3,8000202e <scheduler+0x144>
        acquire(&p->lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	c3a080e7          	jalr	-966(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE && p->priority == 0)
    80001fa4:	4c9c                	lw	a5,24(s1)
    80001fa6:	fd279fe3          	bne	a5,s2,80001f84 <scheduler+0x9a>
    80001faa:	19c4a783          	lw	a5,412(s1)
    80001fae:	dfcd                	beqz	a5,80001f68 <scheduler+0x7e>
        else  if (p->state == RUNNABLE && p->priority > 0)
    80001fb0:	fcf05ae3          	blez	a5,80001f84 <scheduler+0x9a>
          if(p->wait_time>2)
    80001fb4:	1a44a783          	lw	a5,420(s1)
    80001fb8:	00fb4663          	blt	s6,a5,80001fc4 <scheduler+0xda>
          p->wait_time++;
    80001fbc:	2785                	addiw	a5,a5,1
    80001fbe:	1af4a223          	sw	a5,420(s1)
    80001fc2:	b7c9                	j	80001f84 <scheduler+0x9a>
            printf("1. HIIII");
    80001fc4:	856a                	mv	a0,s10
    80001fc6:	ffffe097          	auipc	ra,0xffffe
    80001fca:	5c2080e7          	jalr	1474(ra) # 80000588 <printf>
            p->priority--;
    80001fce:	19c4a783          	lw	a5,412(s1)
    80001fd2:	37fd                	addiw	a5,a5,-1
    80001fd4:	0007871b          	sext.w	a4,a5
    80001fd8:	18f4ae23          	sw	a5,412(s1)
            if (p->queticks == 15)
    80001fdc:	1a04a783          	lw	a5,416(s1)
    80001fe0:	01978d63          	beq	a5,s9,80001ffa <scheduler+0x110>
            else if (p->queticks == 9)
    80001fe4:	46a5                	li	a3,9
    80001fe6:	02d78f63          	beq	a5,a3,80002024 <scheduler+0x13a>
            else if (p->queticks == 3)
    80001fea:	01279d63          	bne	a5,s2,80002004 <scheduler+0x11a>
              p->queticks = 1;
    80001fee:	4785                	li	a5,1
    80001ff0:	1af4a023          	sw	a5,416(s1)
              p->prevticks = 1;
    80001ff4:	1af4a423          	sw	a5,424(s1)
    80001ff8:	a031                	j	80002004 <scheduler+0x11a>
              p->queticks = 9;
    80001ffa:	47a5                	li	a5,9
    80001ffc:	1af4a023          	sw	a5,416(s1)
              p->prevticks = 9;
    80002000:	1af4a423          	sw	a5,424(s1)
            p->wait_time = 0;
    80002004:	1a04a223          	sw	zero,420(s1)
            if(p->priority==0)
    80002008:	ff35                	bnez	a4,80001f84 <scheduler+0x9a>
            p->state = RUNNING;
    8000200a:	4791                	li	a5,4
    8000200c:	cc9c                	sw	a5,24(s1)
            c->proc = p;
    8000200e:	029bb823          	sd	s1,48(s7)
            swtch(&c->context, &p->context);
    80002012:	85d2                	mv	a1,s4
    80002014:	8562                	mv	a0,s8
    80002016:	00001097          	auipc	ra,0x1
    8000201a:	a56080e7          	jalr	-1450(ra) # 80002a6c <swtch>
            c->proc = 0;
    8000201e:	020bb823          	sd	zero,48(s7)
    80002022:	b78d                	j	80001f84 <scheduler+0x9a>
              p->queticks = 3;
    80002024:	1b24a023          	sw	s2,416(s1)
              p->prevticks = 3;
    80002028:	1b24a423          	sw	s2,424(s1)
    8000202c:	bfe1                	j	80002004 <scheduler+0x11a>
    8000202e:	8a56                	mv	s4,s5
      for (p = proc; p < &proc[NPROC]; p++)
    80002030:	0000f497          	auipc	s1,0xf
    80002034:	f8048493          	addi	s1,s1,-128 # 80010fb0 <proc>
        if (p->state == RUNNABLE && p->priority == 1)
    80002038:	4c85                	li	s9,1
            printf("2. HIIII");
    8000203a:	00006d17          	auipc	s10,0x6
    8000203e:	1eed0d13          	addi	s10,s10,494 # 80008228 <digits+0x1e8>
    80002042:	a815                	j	80002076 <scheduler+0x18c>
          p->wait_time = 0;
    80002044:	1a04a223          	sw	zero,420(s1)
          p->state = RUNNING;
    80002048:	4791                	li	a5,4
    8000204a:	cc9c                	sw	a5,24(s1)
          c->proc = p;
    8000204c:	029bb823          	sd	s1,48(s7)
          swtch(&c->context, &p->context);
    80002050:	85d2                	mv	a1,s4
    80002052:	8562                	mv	a0,s8
    80002054:	00001097          	auipc	ra,0x1
    80002058:	a18080e7          	jalr	-1512(ra) # 80002a6c <swtch>
          c->proc = 0;
    8000205c:	020bb823          	sd	zero,48(s7)
        release(&p->lock);
    80002060:	8526                	mv	a0,s1
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	c28080e7          	jalr	-984(ra) # 80000c8a <release>
      for (p = proc; p < &proc[NPROC]; p++)
    8000206a:	1c048493          	addi	s1,s1,448
    8000206e:	1c0a0a13          	addi	s4,s4,448
    80002072:	09348e63          	beq	s1,s3,8000210e <scheduler+0x224>
        acquire(&p->lock);
    80002076:	8526                	mv	a0,s1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	b5e080e7          	jalr	-1186(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE && p->priority == 1)
    80002080:	4c9c                	lw	a5,24(s1)
    80002082:	fd279fe3          	bne	a5,s2,80002060 <scheduler+0x176>
    80002086:	19c4a783          	lw	a5,412(s1)
    8000208a:	fb978de3          	beq	a5,s9,80002044 <scheduler+0x15a>
        else  if (p->state == RUNNABLE && p->priority > 1)
    8000208e:	fcfcd9e3          	bge	s9,a5,80002060 <scheduler+0x176>
          if(p->wait_time>2)
    80002092:	1a44a783          	lw	a5,420(s1)
    80002096:	00fb4663          	blt	s6,a5,800020a2 <scheduler+0x1b8>
          p->wait_time++;
    8000209a:	2785                	addiw	a5,a5,1
    8000209c:	1af4a223          	sw	a5,420(s1)
    800020a0:	b7c1                	j	80002060 <scheduler+0x176>
            printf("2. HIIII");
    800020a2:	856a                	mv	a0,s10
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	4e4080e7          	jalr	1252(ra) # 80000588 <printf>
            p->priority--;
    800020ac:	19c4a783          	lw	a5,412(s1)
    800020b0:	37fd                	addiw	a5,a5,-1
    800020b2:	0007871b          	sext.w	a4,a5
    800020b6:	18f4ae23          	sw	a5,412(s1)
            if (p->queticks == 15)
    800020ba:	1a04a783          	lw	a5,416(s1)
    800020be:	46bd                	li	a3,15
    800020c0:	00d78c63          	beq	a5,a3,800020d8 <scheduler+0x1ee>
            else if (p->queticks == 9)
    800020c4:	46a5                	li	a3,9
    800020c6:	02d78f63          	beq	a5,a3,80002104 <scheduler+0x21a>
            else if (p->queticks == 3)
    800020ca:	01279c63          	bne	a5,s2,800020e2 <scheduler+0x1f8>
              p->queticks = 1;
    800020ce:	1b94a023          	sw	s9,416(s1)
              p->prevticks = 1;
    800020d2:	1b94a423          	sw	s9,424(s1)
    800020d6:	a031                	j	800020e2 <scheduler+0x1f8>
              p->queticks = 9;
    800020d8:	47a5                	li	a5,9
    800020da:	1af4a023          	sw	a5,416(s1)
              p->prevticks = 9;
    800020de:	1af4a423          	sw	a5,424(s1)
            p->wait_time = 0;
    800020e2:	1a04a223          	sw	zero,420(s1)
            if(p->priority==1)
    800020e6:	f7971de3          	bne	a4,s9,80002060 <scheduler+0x176>
            p->state = RUNNING;
    800020ea:	4791                	li	a5,4
    800020ec:	cc9c                	sw	a5,24(s1)
            c->proc = p;
    800020ee:	029bb823          	sd	s1,48(s7)
            swtch(&c->context, &p->context);
    800020f2:	85d2                	mv	a1,s4
    800020f4:	8562                	mv	a0,s8
    800020f6:	00001097          	auipc	ra,0x1
    800020fa:	976080e7          	jalr	-1674(ra) # 80002a6c <swtch>
            c->proc = 0;
    800020fe:	020bb823          	sd	zero,48(s7)
    80002102:	bfb9                	j	80002060 <scheduler+0x176>
              p->queticks = 3;
    80002104:	1b24a023          	sw	s2,416(s1)
              p->prevticks = 3;
    80002108:	1b24a423          	sw	s2,424(s1)
    8000210c:	bfd9                	j	800020e2 <scheduler+0x1f8>
      for (p = proc; p < &proc[NPROC]; p++)
    8000210e:	0000f497          	auipc	s1,0xf
    80002112:	ea248493          	addi	s1,s1,-350 # 80010fb0 <proc>
            printf("3. HIIII");
    80002116:	00006c97          	auipc	s9,0x6
    8000211a:	122c8c93          	addi	s9,s9,290 # 80008238 <digits+0x1f8>
            if (p->queticks == 15)
    8000211e:	4a3d                	li	s4,15
    80002120:	a815                	j	80002154 <scheduler+0x26a>
          p->wait_time = 0;
    80002122:	1a04a223          	sw	zero,420(s1)
          p->state = RUNNING;
    80002126:	4791                	li	a5,4
    80002128:	cc9c                	sw	a5,24(s1)
          c->proc = p;
    8000212a:	029bb823          	sd	s1,48(s7)
          swtch(&c->context, &p->context);
    8000212e:	85d6                	mv	a1,s5
    80002130:	8562                	mv	a0,s8
    80002132:	00001097          	auipc	ra,0x1
    80002136:	93a080e7          	jalr	-1734(ra) # 80002a6c <swtch>
          c->proc = 0;
    8000213a:	020bb823          	sd	zero,48(s7)
        release(&p->lock);
    8000213e:	8526                	mv	a0,s1
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b4a080e7          	jalr	-1206(ra) # 80000c8a <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80002148:	1c048493          	addi	s1,s1,448
    8000214c:	1c0a8a93          	addi	s5,s5,448
    80002150:	09348e63          	beq	s1,s3,800021ec <scheduler+0x302>
        acquire(&p->lock);
    80002154:	8526                	mv	a0,s1
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	a80080e7          	jalr	-1408(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE && p->priority == 2)
    8000215e:	4c9c                	lw	a5,24(s1)
    80002160:	fd279fe3          	bne	a5,s2,8000213e <scheduler+0x254>
    80002164:	19c4a783          	lw	a5,412(s1)
    80002168:	fb678de3          	beq	a5,s6,80002122 <scheduler+0x238>
        else  if (p->state == RUNNABLE && p->priority > 2)
    8000216c:	fcfb59e3          	bge	s6,a5,8000213e <scheduler+0x254>
          if(p->wait_time>2)
    80002170:	1a44a783          	lw	a5,420(s1)
    80002174:	00fb4663          	blt	s6,a5,80002180 <scheduler+0x296>
          p->wait_time++;
    80002178:	2785                	addiw	a5,a5,1
    8000217a:	1af4a223          	sw	a5,420(s1)
    8000217e:	b7c1                	j	8000213e <scheduler+0x254>
            printf("3. HIIII");
    80002180:	8566                	mv	a0,s9
    80002182:	ffffe097          	auipc	ra,0xffffe
    80002186:	406080e7          	jalr	1030(ra) # 80000588 <printf>
            p->priority--;
    8000218a:	19c4a783          	lw	a5,412(s1)
    8000218e:	37fd                	addiw	a5,a5,-1
    80002190:	0007871b          	sext.w	a4,a5
    80002194:	18f4ae23          	sw	a5,412(s1)
            if (p->queticks == 15)
    80002198:	1a04a783          	lw	a5,416(s1)
    8000219c:	01478d63          	beq	a5,s4,800021b6 <scheduler+0x2cc>
            else if (p->queticks == 9)
    800021a0:	46a5                	li	a3,9
    800021a2:	04d78063          	beq	a5,a3,800021e2 <scheduler+0x2f8>
            else if (p->queticks == 3)
    800021a6:	01279d63          	bne	a5,s2,800021c0 <scheduler+0x2d6>
              p->queticks = 1;
    800021aa:	4785                	li	a5,1
    800021ac:	1af4a023          	sw	a5,416(s1)
              p->prevticks = 1;
    800021b0:	1af4a423          	sw	a5,424(s1)
    800021b4:	a031                	j	800021c0 <scheduler+0x2d6>
              p->queticks = 9;
    800021b6:	47a5                	li	a5,9
    800021b8:	1af4a023          	sw	a5,416(s1)
              p->prevticks = 9;
    800021bc:	1af4a423          	sw	a5,424(s1)
            p->wait_time = 0;
    800021c0:	1a04a223          	sw	zero,420(s1)
            if(p->priority==2)
    800021c4:	f7671de3          	bne	a4,s6,8000213e <scheduler+0x254>
            p->state = RUNNING;
    800021c8:	4791                	li	a5,4
    800021ca:	cc9c                	sw	a5,24(s1)
            c->proc = p;
    800021cc:	029bb823          	sd	s1,48(s7)
            swtch(&c->context, &p->context);
    800021d0:	85d6                	mv	a1,s5
    800021d2:	8562                	mv	a0,s8
    800021d4:	00001097          	auipc	ra,0x1
    800021d8:	898080e7          	jalr	-1896(ra) # 80002a6c <swtch>
            c->proc = 0;
    800021dc:	020bb823          	sd	zero,48(s7)
    800021e0:	bfb9                	j	8000213e <scheduler+0x254>
              p->queticks = 3;
    800021e2:	1b24a023          	sw	s2,416(s1)
              p->prevticks = 3;
    800021e6:	1b24a423          	sw	s2,424(s1)
    800021ea:	bfd9                	j	800021c0 <scheduler+0x2d6>
      for (p = proc; p < &proc[NPROC]; p++)
    800021ec:	0000f497          	auipc	s1,0xf
    800021f0:	dc448493          	addi	s1,s1,-572 # 80010fb0 <proc>
          p->state = RUNNING;
    800021f4:	4a91                	li	s5,4
    800021f6:	a811                	j	8000220a <scheduler+0x320>
        release(&p->lock);
    800021f8:	8526                	mv	a0,s1
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	a90080e7          	jalr	-1392(ra) # 80000c8a <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80002202:	1c048493          	addi	s1,s1,448
    80002206:	d3348ce3          	beq	s1,s3,80001f3e <scheduler+0x54>
        acquire(&p->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	9ca080e7          	jalr	-1590(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE && p->priority == 3)
    80002214:	4c9c                	lw	a5,24(s1)
    80002216:	ff2791e3          	bne	a5,s2,800021f8 <scheduler+0x30e>
    8000221a:	19c4a783          	lw	a5,412(s1)
    8000221e:	fd279de3          	bne	a5,s2,800021f8 <scheduler+0x30e>
          p->wait_time = 0;
    80002222:	1a04a223          	sw	zero,420(s1)
          p->state = RUNNING;
    80002226:	0154ac23          	sw	s5,24(s1)
          c->proc = p;
    8000222a:	029bb823          	sd	s1,48(s7)
          swtch(&c->context, &p->context);
    8000222e:	06048593          	addi	a1,s1,96
    80002232:	8562                	mv	a0,s8
    80002234:	00001097          	auipc	ra,0x1
    80002238:	838080e7          	jalr	-1992(ra) # 80002a6c <swtch>
          c->proc = 0;
    8000223c:	020bb823          	sd	zero,48(s7)
    80002240:	bf65                	j	800021f8 <scheduler+0x30e>

0000000080002242 <sched>:
{
    80002242:	7179                	addi	sp,sp,-48
    80002244:	f406                	sd	ra,40(sp)
    80002246:	f022                	sd	s0,32(sp)
    80002248:	ec26                	sd	s1,24(sp)
    8000224a:	e84a                	sd	s2,16(sp)
    8000224c:	e44e                	sd	s3,8(sp)
    8000224e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	75c080e7          	jalr	1884(ra) # 800019ac <myproc>
    80002258:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	902080e7          	jalr	-1790(ra) # 80000b5c <holding>
    80002262:	c93d                	beqz	a0,800022d8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002264:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002266:	2781                	sext.w	a5,a5
    80002268:	079e                	slli	a5,a5,0x7
    8000226a:	0000f717          	auipc	a4,0xf
    8000226e:	91670713          	addi	a4,a4,-1770 # 80010b80 <pid_lock>
    80002272:	97ba                	add	a5,a5,a4
    80002274:	0a87a703          	lw	a4,168(a5)
    80002278:	4785                	li	a5,1
    8000227a:	06f71763          	bne	a4,a5,800022e8 <sched+0xa6>
  if (p->state == RUNNING)
    8000227e:	4c98                	lw	a4,24(s1)
    80002280:	4791                	li	a5,4
    80002282:	06f70b63          	beq	a4,a5,800022f8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002286:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000228a:	8b89                	andi	a5,a5,2
  if (intr_get())
    8000228c:	efb5                	bnez	a5,80002308 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000228e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002290:	0000f917          	auipc	s2,0xf
    80002294:	8f090913          	addi	s2,s2,-1808 # 80010b80 <pid_lock>
    80002298:	2781                	sext.w	a5,a5
    8000229a:	079e                	slli	a5,a5,0x7
    8000229c:	97ca                	add	a5,a5,s2
    8000229e:	0ac7a983          	lw	s3,172(a5)
    800022a2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022a4:	2781                	sext.w	a5,a5
    800022a6:	079e                	slli	a5,a5,0x7
    800022a8:	0000f597          	auipc	a1,0xf
    800022ac:	91058593          	addi	a1,a1,-1776 # 80010bb8 <cpus+0x8>
    800022b0:	95be                	add	a1,a1,a5
    800022b2:	06048513          	addi	a0,s1,96
    800022b6:	00000097          	auipc	ra,0x0
    800022ba:	7b6080e7          	jalr	1974(ra) # 80002a6c <swtch>
    800022be:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022c0:	2781                	sext.w	a5,a5
    800022c2:	079e                	slli	a5,a5,0x7
    800022c4:	97ca                	add	a5,a5,s2
    800022c6:	0b37a623          	sw	s3,172(a5)
}
    800022ca:	70a2                	ld	ra,40(sp)
    800022cc:	7402                	ld	s0,32(sp)
    800022ce:	64e2                	ld	s1,24(sp)
    800022d0:	6942                	ld	s2,16(sp)
    800022d2:	69a2                	ld	s3,8(sp)
    800022d4:	6145                	addi	sp,sp,48
    800022d6:	8082                	ret
    panic("sched p->lock");
    800022d8:	00006517          	auipc	a0,0x6
    800022dc:	f7050513          	addi	a0,a0,-144 # 80008248 <digits+0x208>
    800022e0:	ffffe097          	auipc	ra,0xffffe
    800022e4:	25e080e7          	jalr	606(ra) # 8000053e <panic>
    panic("sched locks");
    800022e8:	00006517          	auipc	a0,0x6
    800022ec:	f7050513          	addi	a0,a0,-144 # 80008258 <digits+0x218>
    800022f0:	ffffe097          	auipc	ra,0xffffe
    800022f4:	24e080e7          	jalr	590(ra) # 8000053e <panic>
    panic("sched running");
    800022f8:	00006517          	auipc	a0,0x6
    800022fc:	f7050513          	addi	a0,a0,-144 # 80008268 <digits+0x228>
    80002300:	ffffe097          	auipc	ra,0xffffe
    80002304:	23e080e7          	jalr	574(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002308:	00006517          	auipc	a0,0x6
    8000230c:	f7050513          	addi	a0,a0,-144 # 80008278 <digits+0x238>
    80002310:	ffffe097          	auipc	ra,0xffffe
    80002314:	22e080e7          	jalr	558(ra) # 8000053e <panic>

0000000080002318 <yield>:
{
    80002318:	1101                	addi	sp,sp,-32
    8000231a:	ec06                	sd	ra,24(sp)
    8000231c:	e822                	sd	s0,16(sp)
    8000231e:	e426                	sd	s1,8(sp)
    80002320:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	68a080e7          	jalr	1674(ra) # 800019ac <myproc>
    8000232a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	8aa080e7          	jalr	-1878(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002334:	478d                	li	a5,3
    80002336:	cc9c                	sw	a5,24(s1)
  sched();
    80002338:	00000097          	auipc	ra,0x0
    8000233c:	f0a080e7          	jalr	-246(ra) # 80002242 <sched>
  release(&p->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	948080e7          	jalr	-1720(ra) # 80000c8a <release>
}
    8000234a:	60e2                	ld	ra,24(sp)
    8000234c:	6442                	ld	s0,16(sp)
    8000234e:	64a2                	ld	s1,8(sp)
    80002350:	6105                	addi	sp,sp,32
    80002352:	8082                	ret

0000000080002354 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002354:	7179                	addi	sp,sp,-48
    80002356:	f406                	sd	ra,40(sp)
    80002358:	f022                	sd	s0,32(sp)
    8000235a:	ec26                	sd	s1,24(sp)
    8000235c:	e84a                	sd	s2,16(sp)
    8000235e:	e44e                	sd	s3,8(sp)
    80002360:	1800                	addi	s0,sp,48
    80002362:	89aa                	mv	s3,a0
    80002364:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	646080e7          	jalr	1606(ra) # 800019ac <myproc>
    8000236e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	866080e7          	jalr	-1946(ra) # 80000bd6 <acquire>
  release(lk);
    80002378:	854a                	mv	a0,s2
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	910080e7          	jalr	-1776(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002382:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002386:	4789                	li	a5,2
    80002388:	cc9c                	sw	a5,24(s1)

  sched();
    8000238a:	00000097          	auipc	ra,0x0
    8000238e:	eb8080e7          	jalr	-328(ra) # 80002242 <sched>

  // Tidy up.
  p->chan = 0;
    80002392:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	8f2080e7          	jalr	-1806(ra) # 80000c8a <release>
  acquire(lk);
    800023a0:	854a                	mv	a0,s2
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	834080e7          	jalr	-1996(ra) # 80000bd6 <acquire>
}
    800023aa:	70a2                	ld	ra,40(sp)
    800023ac:	7402                	ld	s0,32(sp)
    800023ae:	64e2                	ld	s1,24(sp)
    800023b0:	6942                	ld	s2,16(sp)
    800023b2:	69a2                	ld	s3,8(sp)
    800023b4:	6145                	addi	sp,sp,48
    800023b6:	8082                	ret

00000000800023b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023b8:	7139                	addi	sp,sp,-64
    800023ba:	fc06                	sd	ra,56(sp)
    800023bc:	f822                	sd	s0,48(sp)
    800023be:	f426                	sd	s1,40(sp)
    800023c0:	f04a                	sd	s2,32(sp)
    800023c2:	ec4e                	sd	s3,24(sp)
    800023c4:	e852                	sd	s4,16(sp)
    800023c6:	e456                	sd	s5,8(sp)
    800023c8:	0080                	addi	s0,sp,64
    800023ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023cc:	0000f497          	auipc	s1,0xf
    800023d0:	be448493          	addi	s1,s1,-1052 # 80010fb0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800023d4:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800023d6:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800023d8:	00016917          	auipc	s2,0x16
    800023dc:	bd890913          	addi	s2,s2,-1064 # 80017fb0 <tickslock>
    800023e0:	a811                	j	800023f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8a6080e7          	jalr	-1882(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023ec:	1c048493          	addi	s1,s1,448
    800023f0:	03248663          	beq	s1,s2,8000241c <wakeup+0x64>
    if (p != myproc())
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	5b8080e7          	jalr	1464(ra) # 800019ac <myproc>
    800023fc:	fea488e3          	beq	s1,a0,800023ec <wakeup+0x34>
      acquire(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	7d4080e7          	jalr	2004(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000240a:	4c9c                	lw	a5,24(s1)
    8000240c:	fd379be3          	bne	a5,s3,800023e2 <wakeup+0x2a>
    80002410:	709c                	ld	a5,32(s1)
    80002412:	fd4798e3          	bne	a5,s4,800023e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002416:	0154ac23          	sw	s5,24(s1)
    8000241a:	b7e1                	j	800023e2 <wakeup+0x2a>
    }
  }
}
    8000241c:	70e2                	ld	ra,56(sp)
    8000241e:	7442                	ld	s0,48(sp)
    80002420:	74a2                	ld	s1,40(sp)
    80002422:	7902                	ld	s2,32(sp)
    80002424:	69e2                	ld	s3,24(sp)
    80002426:	6a42                	ld	s4,16(sp)
    80002428:	6aa2                	ld	s5,8(sp)
    8000242a:	6121                	addi	sp,sp,64
    8000242c:	8082                	ret

000000008000242e <reparent>:
{
    8000242e:	7179                	addi	sp,sp,-48
    80002430:	f406                	sd	ra,40(sp)
    80002432:	f022                	sd	s0,32(sp)
    80002434:	ec26                	sd	s1,24(sp)
    80002436:	e84a                	sd	s2,16(sp)
    80002438:	e44e                	sd	s3,8(sp)
    8000243a:	e052                	sd	s4,0(sp)
    8000243c:	1800                	addi	s0,sp,48
    8000243e:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002440:	0000f497          	auipc	s1,0xf
    80002444:	b7048493          	addi	s1,s1,-1168 # 80010fb0 <proc>
      pp->parent = initproc;
    80002448:	00006a17          	auipc	s4,0x6
    8000244c:	4c0a0a13          	addi	s4,s4,1216 # 80008908 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002450:	00016997          	auipc	s3,0x16
    80002454:	b6098993          	addi	s3,s3,-1184 # 80017fb0 <tickslock>
    80002458:	a029                	j	80002462 <reparent+0x34>
    8000245a:	1c048493          	addi	s1,s1,448
    8000245e:	01348d63          	beq	s1,s3,80002478 <reparent+0x4a>
    if (pp->parent == p)
    80002462:	7c9c                	ld	a5,56(s1)
    80002464:	ff279be3          	bne	a5,s2,8000245a <reparent+0x2c>
      pp->parent = initproc;
    80002468:	000a3503          	ld	a0,0(s4)
    8000246c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000246e:	00000097          	auipc	ra,0x0
    80002472:	f4a080e7          	jalr	-182(ra) # 800023b8 <wakeup>
    80002476:	b7d5                	j	8000245a <reparent+0x2c>
}
    80002478:	70a2                	ld	ra,40(sp)
    8000247a:	7402                	ld	s0,32(sp)
    8000247c:	64e2                	ld	s1,24(sp)
    8000247e:	6942                	ld	s2,16(sp)
    80002480:	69a2                	ld	s3,8(sp)
    80002482:	6a02                	ld	s4,0(sp)
    80002484:	6145                	addi	sp,sp,48
    80002486:	8082                	ret

0000000080002488 <exit>:
{
    80002488:	7179                	addi	sp,sp,-48
    8000248a:	f406                	sd	ra,40(sp)
    8000248c:	f022                	sd	s0,32(sp)
    8000248e:	ec26                	sd	s1,24(sp)
    80002490:	e84a                	sd	s2,16(sp)
    80002492:	e44e                	sd	s3,8(sp)
    80002494:	e052                	sd	s4,0(sp)
    80002496:	1800                	addi	s0,sp,48
    80002498:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	512080e7          	jalr	1298(ra) # 800019ac <myproc>
    800024a2:	89aa                	mv	s3,a0
  if (p == initproc)
    800024a4:	00006797          	auipc	a5,0x6
    800024a8:	4647b783          	ld	a5,1124(a5) # 80008908 <initproc>
    800024ac:	0d050493          	addi	s1,a0,208
    800024b0:	15050913          	addi	s2,a0,336
    800024b4:	02a79363          	bne	a5,a0,800024da <exit+0x52>
    panic("init exiting");
    800024b8:	00006517          	auipc	a0,0x6
    800024bc:	dd850513          	addi	a0,a0,-552 # 80008290 <digits+0x250>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	07e080e7          	jalr	126(ra) # 8000053e <panic>
      fileclose(f);
    800024c8:	00002097          	auipc	ra,0x2
    800024cc:	7e6080e7          	jalr	2022(ra) # 80004cae <fileclose>
      p->ofile[fd] = 0;
    800024d0:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800024d4:	04a1                	addi	s1,s1,8
    800024d6:	01248563          	beq	s1,s2,800024e0 <exit+0x58>
    if (p->ofile[fd])
    800024da:	6088                	ld	a0,0(s1)
    800024dc:	f575                	bnez	a0,800024c8 <exit+0x40>
    800024de:	bfdd                	j	800024d4 <exit+0x4c>
  begin_op();
    800024e0:	00002097          	auipc	ra,0x2
    800024e4:	302080e7          	jalr	770(ra) # 800047e2 <begin_op>
  iput(p->cwd);
    800024e8:	1509b503          	ld	a0,336(s3)
    800024ec:	00002097          	auipc	ra,0x2
    800024f0:	aee080e7          	jalr	-1298(ra) # 80003fda <iput>
  end_op();
    800024f4:	00002097          	auipc	ra,0x2
    800024f8:	36e080e7          	jalr	878(ra) # 80004862 <end_op>
  p->cwd = 0;
    800024fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002500:	0000e497          	auipc	s1,0xe
    80002504:	69848493          	addi	s1,s1,1688 # 80010b98 <wait_lock>
    80002508:	8526                	mv	a0,s1
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	6cc080e7          	jalr	1740(ra) # 80000bd6 <acquire>
  reparent(p);
    80002512:	854e                	mv	a0,s3
    80002514:	00000097          	auipc	ra,0x0
    80002518:	f1a080e7          	jalr	-230(ra) # 8000242e <reparent>
  wakeup(p->parent);
    8000251c:	0389b503          	ld	a0,56(s3)
    80002520:	00000097          	auipc	ra,0x0
    80002524:	e98080e7          	jalr	-360(ra) # 800023b8 <wakeup>
  acquire(&p->lock);
    80002528:	854e                	mv	a0,s3
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	6ac080e7          	jalr	1708(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002532:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002536:	4795                	li	a5,5
    80002538:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000253c:	00006797          	auipc	a5,0x6
    80002540:	3d47a783          	lw	a5,980(a5) # 80008910 <ticks>
    80002544:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002548:	8526                	mv	a0,s1
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	740080e7          	jalr	1856(ra) # 80000c8a <release>
  sched();
    80002552:	00000097          	auipc	ra,0x0
    80002556:	cf0080e7          	jalr	-784(ra) # 80002242 <sched>
  panic("zombie exit");
    8000255a:	00006517          	auipc	a0,0x6
    8000255e:	d4650513          	addi	a0,a0,-698 # 800082a0 <digits+0x260>
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	fdc080e7          	jalr	-36(ra) # 8000053e <panic>

000000008000256a <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000256a:	7179                	addi	sp,sp,-48
    8000256c:	f406                	sd	ra,40(sp)
    8000256e:	f022                	sd	s0,32(sp)
    80002570:	ec26                	sd	s1,24(sp)
    80002572:	e84a                	sd	s2,16(sp)
    80002574:	e44e                	sd	s3,8(sp)
    80002576:	1800                	addi	s0,sp,48
    80002578:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000257a:	0000f497          	auipc	s1,0xf
    8000257e:	a3648493          	addi	s1,s1,-1482 # 80010fb0 <proc>
    80002582:	00016997          	auipc	s3,0x16
    80002586:	a2e98993          	addi	s3,s3,-1490 # 80017fb0 <tickslock>
  {
    acquire(&p->lock);
    8000258a:	8526                	mv	a0,s1
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	64a080e7          	jalr	1610(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002594:	589c                	lw	a5,48(s1)
    80002596:	01278d63          	beq	a5,s2,800025b0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000259a:	8526                	mv	a0,s1
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	6ee080e7          	jalr	1774(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025a4:	1c048493          	addi	s1,s1,448
    800025a8:	ff3491e3          	bne	s1,s3,8000258a <kill+0x20>
  }
  return -1;
    800025ac:	557d                	li	a0,-1
    800025ae:	a829                	j	800025c8 <kill+0x5e>
      p->killed = 1;
    800025b0:	4785                	li	a5,1
    800025b2:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800025b4:	4c98                	lw	a4,24(s1)
    800025b6:	4789                	li	a5,2
    800025b8:	00f70f63          	beq	a4,a5,800025d6 <kill+0x6c>
      release(&p->lock);
    800025bc:	8526                	mv	a0,s1
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	6cc080e7          	jalr	1740(ra) # 80000c8a <release>
      return 0;
    800025c6:	4501                	li	a0,0
}
    800025c8:	70a2                	ld	ra,40(sp)
    800025ca:	7402                	ld	s0,32(sp)
    800025cc:	64e2                	ld	s1,24(sp)
    800025ce:	6942                	ld	s2,16(sp)
    800025d0:	69a2                	ld	s3,8(sp)
    800025d2:	6145                	addi	sp,sp,48
    800025d4:	8082                	ret
        p->state = RUNNABLE;
    800025d6:	478d                	li	a5,3
    800025d8:	cc9c                	sw	a5,24(s1)
    800025da:	b7cd                	j	800025bc <kill+0x52>

00000000800025dc <setkilled>:

void setkilled(struct proc *p)
{
    800025dc:	1101                	addi	sp,sp,-32
    800025de:	ec06                	sd	ra,24(sp)
    800025e0:	e822                	sd	s0,16(sp)
    800025e2:	e426                	sd	s1,8(sp)
    800025e4:	1000                	addi	s0,sp,32
    800025e6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	5ee080e7          	jalr	1518(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800025f0:	4785                	li	a5,1
    800025f2:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	694080e7          	jalr	1684(ra) # 80000c8a <release>
}
    800025fe:	60e2                	ld	ra,24(sp)
    80002600:	6442                	ld	s0,16(sp)
    80002602:	64a2                	ld	s1,8(sp)
    80002604:	6105                	addi	sp,sp,32
    80002606:	8082                	ret

0000000080002608 <killed>:

int killed(struct proc *p)
{
    80002608:	1101                	addi	sp,sp,-32
    8000260a:	ec06                	sd	ra,24(sp)
    8000260c:	e822                	sd	s0,16(sp)
    8000260e:	e426                	sd	s1,8(sp)
    80002610:	e04a                	sd	s2,0(sp)
    80002612:	1000                	addi	s0,sp,32
    80002614:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	5c0080e7          	jalr	1472(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000261e:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002622:	8526                	mv	a0,s1
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	666080e7          	jalr	1638(ra) # 80000c8a <release>
  return k;
}
    8000262c:	854a                	mv	a0,s2
    8000262e:	60e2                	ld	ra,24(sp)
    80002630:	6442                	ld	s0,16(sp)
    80002632:	64a2                	ld	s1,8(sp)
    80002634:	6902                	ld	s2,0(sp)
    80002636:	6105                	addi	sp,sp,32
    80002638:	8082                	ret

000000008000263a <wait>:
{
    8000263a:	715d                	addi	sp,sp,-80
    8000263c:	e486                	sd	ra,72(sp)
    8000263e:	e0a2                	sd	s0,64(sp)
    80002640:	fc26                	sd	s1,56(sp)
    80002642:	f84a                	sd	s2,48(sp)
    80002644:	f44e                	sd	s3,40(sp)
    80002646:	f052                	sd	s4,32(sp)
    80002648:	ec56                	sd	s5,24(sp)
    8000264a:	e85a                	sd	s6,16(sp)
    8000264c:	e45e                	sd	s7,8(sp)
    8000264e:	e062                	sd	s8,0(sp)
    80002650:	0880                	addi	s0,sp,80
    80002652:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002654:	fffff097          	auipc	ra,0xfffff
    80002658:	358080e7          	jalr	856(ra) # 800019ac <myproc>
    8000265c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000265e:	0000e517          	auipc	a0,0xe
    80002662:	53a50513          	addi	a0,a0,1338 # 80010b98 <wait_lock>
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	570080e7          	jalr	1392(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000266e:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002670:	4a15                	li	s4,5
        havekids = 1;
    80002672:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002674:	00016997          	auipc	s3,0x16
    80002678:	93c98993          	addi	s3,s3,-1732 # 80017fb0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000267c:	0000ec17          	auipc	s8,0xe
    80002680:	51cc0c13          	addi	s8,s8,1308 # 80010b98 <wait_lock>
    havekids = 0;
    80002684:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002686:	0000f497          	auipc	s1,0xf
    8000268a:	92a48493          	addi	s1,s1,-1750 # 80010fb0 <proc>
    8000268e:	a0bd                	j	800026fc <wait+0xc2>
          pid = pp->pid;
    80002690:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002694:	000b0e63          	beqz	s6,800026b0 <wait+0x76>
    80002698:	4691                	li	a3,4
    8000269a:	02c48613          	addi	a2,s1,44
    8000269e:	85da                	mv	a1,s6
    800026a0:	05093503          	ld	a0,80(s2)
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	fc4080e7          	jalr	-60(ra) # 80001668 <copyout>
    800026ac:	02054563          	bltz	a0,800026d6 <wait+0x9c>
          freeproc(pp);
    800026b0:	8526                	mv	a0,s1
    800026b2:	fffff097          	auipc	ra,0xfffff
    800026b6:	4ac080e7          	jalr	1196(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800026ba:	8526                	mv	a0,s1
    800026bc:	ffffe097          	auipc	ra,0xffffe
    800026c0:	5ce080e7          	jalr	1486(ra) # 80000c8a <release>
          release(&wait_lock);
    800026c4:	0000e517          	auipc	a0,0xe
    800026c8:	4d450513          	addi	a0,a0,1236 # 80010b98 <wait_lock>
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	5be080e7          	jalr	1470(ra) # 80000c8a <release>
          return pid;
    800026d4:	a0b5                	j	80002740 <wait+0x106>
            release(&pp->lock);
    800026d6:	8526                	mv	a0,s1
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	5b2080e7          	jalr	1458(ra) # 80000c8a <release>
            release(&wait_lock);
    800026e0:	0000e517          	auipc	a0,0xe
    800026e4:	4b850513          	addi	a0,a0,1208 # 80010b98 <wait_lock>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	5a2080e7          	jalr	1442(ra) # 80000c8a <release>
            return -1;
    800026f0:	59fd                	li	s3,-1
    800026f2:	a0b9                	j	80002740 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026f4:	1c048493          	addi	s1,s1,448
    800026f8:	03348463          	beq	s1,s3,80002720 <wait+0xe6>
      if (pp->parent == p)
    800026fc:	7c9c                	ld	a5,56(s1)
    800026fe:	ff279be3          	bne	a5,s2,800026f4 <wait+0xba>
        acquire(&pp->lock);
    80002702:	8526                	mv	a0,s1
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	4d2080e7          	jalr	1234(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    8000270c:	4c9c                	lw	a5,24(s1)
    8000270e:	f94781e3          	beq	a5,s4,80002690 <wait+0x56>
        release(&pp->lock);
    80002712:	8526                	mv	a0,s1
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	576080e7          	jalr	1398(ra) # 80000c8a <release>
        havekids = 1;
    8000271c:	8756                	mv	a4,s5
    8000271e:	bfd9                	j	800026f4 <wait+0xba>
    if (!havekids || killed(p))
    80002720:	c719                	beqz	a4,8000272e <wait+0xf4>
    80002722:	854a                	mv	a0,s2
    80002724:	00000097          	auipc	ra,0x0
    80002728:	ee4080e7          	jalr	-284(ra) # 80002608 <killed>
    8000272c:	c51d                	beqz	a0,8000275a <wait+0x120>
      release(&wait_lock);
    8000272e:	0000e517          	auipc	a0,0xe
    80002732:	46a50513          	addi	a0,a0,1130 # 80010b98 <wait_lock>
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	554080e7          	jalr	1364(ra) # 80000c8a <release>
      return -1;
    8000273e:	59fd                	li	s3,-1
}
    80002740:	854e                	mv	a0,s3
    80002742:	60a6                	ld	ra,72(sp)
    80002744:	6406                	ld	s0,64(sp)
    80002746:	74e2                	ld	s1,56(sp)
    80002748:	7942                	ld	s2,48(sp)
    8000274a:	79a2                	ld	s3,40(sp)
    8000274c:	7a02                	ld	s4,32(sp)
    8000274e:	6ae2                	ld	s5,24(sp)
    80002750:	6b42                	ld	s6,16(sp)
    80002752:	6ba2                	ld	s7,8(sp)
    80002754:	6c02                	ld	s8,0(sp)
    80002756:	6161                	addi	sp,sp,80
    80002758:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000275a:	85e2                	mv	a1,s8
    8000275c:	854a                	mv	a0,s2
    8000275e:	00000097          	auipc	ra,0x0
    80002762:	bf6080e7          	jalr	-1034(ra) # 80002354 <sleep>
    havekids = 0;
    80002766:	bf39                	j	80002684 <wait+0x4a>

0000000080002768 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002768:	7179                	addi	sp,sp,-48
    8000276a:	f406                	sd	ra,40(sp)
    8000276c:	f022                	sd	s0,32(sp)
    8000276e:	ec26                	sd	s1,24(sp)
    80002770:	e84a                	sd	s2,16(sp)
    80002772:	e44e                	sd	s3,8(sp)
    80002774:	e052                	sd	s4,0(sp)
    80002776:	1800                	addi	s0,sp,48
    80002778:	84aa                	mv	s1,a0
    8000277a:	892e                	mv	s2,a1
    8000277c:	89b2                	mv	s3,a2
    8000277e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002780:	fffff097          	auipc	ra,0xfffff
    80002784:	22c080e7          	jalr	556(ra) # 800019ac <myproc>
  if (user_dst)
    80002788:	c08d                	beqz	s1,800027aa <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000278a:	86d2                	mv	a3,s4
    8000278c:	864e                	mv	a2,s3
    8000278e:	85ca                	mv	a1,s2
    80002790:	6928                	ld	a0,80(a0)
    80002792:	fffff097          	auipc	ra,0xfffff
    80002796:	ed6080e7          	jalr	-298(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000279a:	70a2                	ld	ra,40(sp)
    8000279c:	7402                	ld	s0,32(sp)
    8000279e:	64e2                	ld	s1,24(sp)
    800027a0:	6942                	ld	s2,16(sp)
    800027a2:	69a2                	ld	s3,8(sp)
    800027a4:	6a02                	ld	s4,0(sp)
    800027a6:	6145                	addi	sp,sp,48
    800027a8:	8082                	ret
    memmove((char *)dst, src, len);
    800027aa:	000a061b          	sext.w	a2,s4
    800027ae:	85ce                	mv	a1,s3
    800027b0:	854a                	mv	a0,s2
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	57c080e7          	jalr	1404(ra) # 80000d2e <memmove>
    return 0;
    800027ba:	8526                	mv	a0,s1
    800027bc:	bff9                	j	8000279a <either_copyout+0x32>

00000000800027be <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027be:	7179                	addi	sp,sp,-48
    800027c0:	f406                	sd	ra,40(sp)
    800027c2:	f022                	sd	s0,32(sp)
    800027c4:	ec26                	sd	s1,24(sp)
    800027c6:	e84a                	sd	s2,16(sp)
    800027c8:	e44e                	sd	s3,8(sp)
    800027ca:	e052                	sd	s4,0(sp)
    800027cc:	1800                	addi	s0,sp,48
    800027ce:	892a                	mv	s2,a0
    800027d0:	84ae                	mv	s1,a1
    800027d2:	89b2                	mv	s3,a2
    800027d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027d6:	fffff097          	auipc	ra,0xfffff
    800027da:	1d6080e7          	jalr	470(ra) # 800019ac <myproc>
  if (user_src)
    800027de:	c08d                	beqz	s1,80002800 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800027e0:	86d2                	mv	a3,s4
    800027e2:	864e                	mv	a2,s3
    800027e4:	85ca                	mv	a1,s2
    800027e6:	6928                	ld	a0,80(a0)
    800027e8:	fffff097          	auipc	ra,0xfffff
    800027ec:	f0c080e7          	jalr	-244(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800027f0:	70a2                	ld	ra,40(sp)
    800027f2:	7402                	ld	s0,32(sp)
    800027f4:	64e2                	ld	s1,24(sp)
    800027f6:	6942                	ld	s2,16(sp)
    800027f8:	69a2                	ld	s3,8(sp)
    800027fa:	6a02                	ld	s4,0(sp)
    800027fc:	6145                	addi	sp,sp,48
    800027fe:	8082                	ret
    memmove(dst, (char *)src, len);
    80002800:	000a061b          	sext.w	a2,s4
    80002804:	85ce                	mv	a1,s3
    80002806:	854a                	mv	a0,s2
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	526080e7          	jalr	1318(ra) # 80000d2e <memmove>
    return 0;
    80002810:	8526                	mv	a0,s1
    80002812:	bff9                	j	800027f0 <either_copyin+0x32>

0000000080002814 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002814:	715d                	addi	sp,sp,-80
    80002816:	e486                	sd	ra,72(sp)
    80002818:	e0a2                	sd	s0,64(sp)
    8000281a:	fc26                	sd	s1,56(sp)
    8000281c:	f84a                	sd	s2,48(sp)
    8000281e:	f44e                	sd	s3,40(sp)
    80002820:	f052                	sd	s4,32(sp)
    80002822:	ec56                	sd	s5,24(sp)
    80002824:	e85a                	sd	s6,16(sp)
    80002826:	e45e                	sd	s7,8(sp)
    80002828:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000282a:	00006517          	auipc	a0,0x6
    8000282e:	89e50513          	addi	a0,a0,-1890 # 800080c8 <digits+0x88>
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	d56080e7          	jalr	-682(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000283a:	0000f497          	auipc	s1,0xf
    8000283e:	8ce48493          	addi	s1,s1,-1842 # 80011108 <proc+0x158>
    80002842:	00016917          	auipc	s2,0x16
    80002846:	8c690913          	addi	s2,s2,-1850 # 80018108 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000284a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000284c:	00006997          	auipc	s3,0x6
    80002850:	a6498993          	addi	s3,s3,-1436 # 800082b0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    80002854:	00006a97          	auipc	s5,0x6
    80002858:	a64a8a93          	addi	s5,s5,-1436 # 800082b8 <digits+0x278>
    printf("\n");
    8000285c:	00006a17          	auipc	s4,0x6
    80002860:	86ca0a13          	addi	s4,s4,-1940 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002864:	00006b97          	auipc	s7,0x6
    80002868:	a94b8b93          	addi	s7,s7,-1388 # 800082f8 <states.0>
    8000286c:	a00d                	j	8000288e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000286e:	ed86a583          	lw	a1,-296(a3)
    80002872:	8556                	mv	a0,s5
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	d14080e7          	jalr	-748(ra) # 80000588 <printf>
    printf("\n");
    8000287c:	8552                	mv	a0,s4
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	d0a080e7          	jalr	-758(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002886:	1c048493          	addi	s1,s1,448
    8000288a:	03248163          	beq	s1,s2,800028ac <procdump+0x98>
    if (p->state == UNUSED)
    8000288e:	86a6                	mv	a3,s1
    80002890:	ec04a783          	lw	a5,-320(s1)
    80002894:	dbed                	beqz	a5,80002886 <procdump+0x72>
      state = "???";
    80002896:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002898:	fcfb6be3          	bltu	s6,a5,8000286e <procdump+0x5a>
    8000289c:	1782                	slli	a5,a5,0x20
    8000289e:	9381                	srli	a5,a5,0x20
    800028a0:	078e                	slli	a5,a5,0x3
    800028a2:	97de                	add	a5,a5,s7
    800028a4:	6390                	ld	a2,0(a5)
    800028a6:	f661                	bnez	a2,8000286e <procdump+0x5a>
      state = "???";
    800028a8:	864e                	mv	a2,s3
    800028aa:	b7d1                	j	8000286e <procdump+0x5a>
  }
}
    800028ac:	60a6                	ld	ra,72(sp)
    800028ae:	6406                	ld	s0,64(sp)
    800028b0:	74e2                	ld	s1,56(sp)
    800028b2:	7942                	ld	s2,48(sp)
    800028b4:	79a2                	ld	s3,40(sp)
    800028b6:	7a02                	ld	s4,32(sp)
    800028b8:	6ae2                	ld	s5,24(sp)
    800028ba:	6b42                	ld	s6,16(sp)
    800028bc:	6ba2                	ld	s7,8(sp)
    800028be:	6161                	addi	sp,sp,80
    800028c0:	8082                	ret

00000000800028c2 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800028c2:	711d                	addi	sp,sp,-96
    800028c4:	ec86                	sd	ra,88(sp)
    800028c6:	e8a2                	sd	s0,80(sp)
    800028c8:	e4a6                	sd	s1,72(sp)
    800028ca:	e0ca                	sd	s2,64(sp)
    800028cc:	fc4e                	sd	s3,56(sp)
    800028ce:	f852                	sd	s4,48(sp)
    800028d0:	f456                	sd	s5,40(sp)
    800028d2:	f05a                	sd	s6,32(sp)
    800028d4:	ec5e                	sd	s7,24(sp)
    800028d6:	e862                	sd	s8,16(sp)
    800028d8:	e466                	sd	s9,8(sp)
    800028da:	e06a                	sd	s10,0(sp)
    800028dc:	1080                	addi	s0,sp,96
    800028de:	8b2a                	mv	s6,a0
    800028e0:	8bae                	mv	s7,a1
    800028e2:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800028e4:	fffff097          	auipc	ra,0xfffff
    800028e8:	0c8080e7          	jalr	200(ra) # 800019ac <myproc>
    800028ec:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800028ee:	0000e517          	auipc	a0,0xe
    800028f2:	2aa50513          	addi	a0,a0,682 # 80010b98 <wait_lock>
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	2e0080e7          	jalr	736(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800028fe:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002900:	4a15                	li	s4,5
        havekids = 1;
    80002902:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002904:	00015997          	auipc	s3,0x15
    80002908:	6ac98993          	addi	s3,s3,1708 # 80017fb0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000290c:	0000ed17          	auipc	s10,0xe
    80002910:	28cd0d13          	addi	s10,s10,652 # 80010b98 <wait_lock>
    havekids = 0;
    80002914:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002916:	0000e497          	auipc	s1,0xe
    8000291a:	69a48493          	addi	s1,s1,1690 # 80010fb0 <proc>
    8000291e:	a059                	j	800029a4 <waitx+0xe2>
          pid = np->pid;
    80002920:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002924:	1684a703          	lw	a4,360(s1)
    80002928:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000292c:	16c4a783          	lw	a5,364(s1)
    80002930:	9f3d                	addw	a4,a4,a5
    80002932:	1704a783          	lw	a5,368(s1)
    80002936:	9f99                	subw	a5,a5,a4
    80002938:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000293c:	000b0e63          	beqz	s6,80002958 <waitx+0x96>
    80002940:	4691                	li	a3,4
    80002942:	02c48613          	addi	a2,s1,44
    80002946:	85da                	mv	a1,s6
    80002948:	05093503          	ld	a0,80(s2)
    8000294c:	fffff097          	auipc	ra,0xfffff
    80002950:	d1c080e7          	jalr	-740(ra) # 80001668 <copyout>
    80002954:	02054563          	bltz	a0,8000297e <waitx+0xbc>
          freeproc(np);
    80002958:	8526                	mv	a0,s1
    8000295a:	fffff097          	auipc	ra,0xfffff
    8000295e:	204080e7          	jalr	516(ra) # 80001b5e <freeproc>
          release(&np->lock);
    80002962:	8526                	mv	a0,s1
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	326080e7          	jalr	806(ra) # 80000c8a <release>
          release(&wait_lock);
    8000296c:	0000e517          	auipc	a0,0xe
    80002970:	22c50513          	addi	a0,a0,556 # 80010b98 <wait_lock>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	316080e7          	jalr	790(ra) # 80000c8a <release>
          return pid;
    8000297c:	a09d                	j	800029e2 <waitx+0x120>
            release(&np->lock);
    8000297e:	8526                	mv	a0,s1
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	30a080e7          	jalr	778(ra) # 80000c8a <release>
            release(&wait_lock);
    80002988:	0000e517          	auipc	a0,0xe
    8000298c:	21050513          	addi	a0,a0,528 # 80010b98 <wait_lock>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	2fa080e7          	jalr	762(ra) # 80000c8a <release>
            return -1;
    80002998:	59fd                	li	s3,-1
    8000299a:	a0a1                	j	800029e2 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    8000299c:	1c048493          	addi	s1,s1,448
    800029a0:	03348463          	beq	s1,s3,800029c8 <waitx+0x106>
      if (np->parent == p)
    800029a4:	7c9c                	ld	a5,56(s1)
    800029a6:	ff279be3          	bne	a5,s2,8000299c <waitx+0xda>
        acquire(&np->lock);
    800029aa:	8526                	mv	a0,s1
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	22a080e7          	jalr	554(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    800029b4:	4c9c                	lw	a5,24(s1)
    800029b6:	f74785e3          	beq	a5,s4,80002920 <waitx+0x5e>
        release(&np->lock);
    800029ba:	8526                	mv	a0,s1
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	2ce080e7          	jalr	718(ra) # 80000c8a <release>
        havekids = 1;
    800029c4:	8756                	mv	a4,s5
    800029c6:	bfd9                	j	8000299c <waitx+0xda>
    if (!havekids || p->killed)
    800029c8:	c701                	beqz	a4,800029d0 <waitx+0x10e>
    800029ca:	02892783          	lw	a5,40(s2)
    800029ce:	cb8d                	beqz	a5,80002a00 <waitx+0x13e>
      release(&wait_lock);
    800029d0:	0000e517          	auipc	a0,0xe
    800029d4:	1c850513          	addi	a0,a0,456 # 80010b98 <wait_lock>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
      return -1;
    800029e0:	59fd                	li	s3,-1
  }
}
    800029e2:	854e                	mv	a0,s3
    800029e4:	60e6                	ld	ra,88(sp)
    800029e6:	6446                	ld	s0,80(sp)
    800029e8:	64a6                	ld	s1,72(sp)
    800029ea:	6906                	ld	s2,64(sp)
    800029ec:	79e2                	ld	s3,56(sp)
    800029ee:	7a42                	ld	s4,48(sp)
    800029f0:	7aa2                	ld	s5,40(sp)
    800029f2:	7b02                	ld	s6,32(sp)
    800029f4:	6be2                	ld	s7,24(sp)
    800029f6:	6c42                	ld	s8,16(sp)
    800029f8:	6ca2                	ld	s9,8(sp)
    800029fa:	6d02                	ld	s10,0(sp)
    800029fc:	6125                	addi	sp,sp,96
    800029fe:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a00:	85ea                	mv	a1,s10
    80002a02:	854a                	mv	a0,s2
    80002a04:	00000097          	auipc	ra,0x0
    80002a08:	950080e7          	jalr	-1712(ra) # 80002354 <sleep>
    havekids = 0;
    80002a0c:	b721                	j	80002914 <waitx+0x52>

0000000080002a0e <update_time>:

void update_time()
{
    80002a0e:	7179                	addi	sp,sp,-48
    80002a10:	f406                	sd	ra,40(sp)
    80002a12:	f022                	sd	s0,32(sp)
    80002a14:	ec26                	sd	s1,24(sp)
    80002a16:	e84a                	sd	s2,16(sp)
    80002a18:	e44e                	sd	s3,8(sp)
    80002a1a:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002a1c:	0000e497          	auipc	s1,0xe
    80002a20:	59448493          	addi	s1,s1,1428 # 80010fb0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002a24:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002a26:	00015917          	auipc	s2,0x15
    80002a2a:	58a90913          	addi	s2,s2,1418 # 80017fb0 <tickslock>
    80002a2e:	a811                	j	80002a42 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002a30:	8526                	mv	a0,s1
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	258080e7          	jalr	600(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a3a:	1c048493          	addi	s1,s1,448
    80002a3e:	03248063          	beq	s1,s2,80002a5e <update_time+0x50>
    acquire(&p->lock);
    80002a42:	8526                	mv	a0,s1
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	192080e7          	jalr	402(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80002a4c:	4c9c                	lw	a5,24(s1)
    80002a4e:	ff3791e3          	bne	a5,s3,80002a30 <update_time+0x22>
      p->rtime++;
    80002a52:	1684a783          	lw	a5,360(s1)
    80002a56:	2785                	addiw	a5,a5,1
    80002a58:	16f4a423          	sw	a5,360(s1)
    80002a5c:	bfd1                	j	80002a30 <update_time+0x22>
  }
    80002a5e:	70a2                	ld	ra,40(sp)
    80002a60:	7402                	ld	s0,32(sp)
    80002a62:	64e2                	ld	s1,24(sp)
    80002a64:	6942                	ld	s2,16(sp)
    80002a66:	69a2                	ld	s3,8(sp)
    80002a68:	6145                	addi	sp,sp,48
    80002a6a:	8082                	ret

0000000080002a6c <swtch>:
    80002a6c:	00153023          	sd	ra,0(a0)
    80002a70:	00253423          	sd	sp,8(a0)
    80002a74:	e900                	sd	s0,16(a0)
    80002a76:	ed04                	sd	s1,24(a0)
    80002a78:	03253023          	sd	s2,32(a0)
    80002a7c:	03353423          	sd	s3,40(a0)
    80002a80:	03453823          	sd	s4,48(a0)
    80002a84:	03553c23          	sd	s5,56(a0)
    80002a88:	05653023          	sd	s6,64(a0)
    80002a8c:	05753423          	sd	s7,72(a0)
    80002a90:	05853823          	sd	s8,80(a0)
    80002a94:	05953c23          	sd	s9,88(a0)
    80002a98:	07a53023          	sd	s10,96(a0)
    80002a9c:	07b53423          	sd	s11,104(a0)
    80002aa0:	0005b083          	ld	ra,0(a1)
    80002aa4:	0085b103          	ld	sp,8(a1)
    80002aa8:	6980                	ld	s0,16(a1)
    80002aaa:	6d84                	ld	s1,24(a1)
    80002aac:	0205b903          	ld	s2,32(a1)
    80002ab0:	0285b983          	ld	s3,40(a1)
    80002ab4:	0305ba03          	ld	s4,48(a1)
    80002ab8:	0385ba83          	ld	s5,56(a1)
    80002abc:	0405bb03          	ld	s6,64(a1)
    80002ac0:	0485bb83          	ld	s7,72(a1)
    80002ac4:	0505bc03          	ld	s8,80(a1)
    80002ac8:	0585bc83          	ld	s9,88(a1)
    80002acc:	0605bd03          	ld	s10,96(a1)
    80002ad0:	0685bd83          	ld	s11,104(a1)
    80002ad4:	8082                	ret

0000000080002ad6 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002ad6:	1141                	addi	sp,sp,-16
    80002ad8:	e406                	sd	ra,8(sp)
    80002ada:	e022                	sd	s0,0(sp)
    80002adc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ade:	00006597          	auipc	a1,0x6
    80002ae2:	84a58593          	addi	a1,a1,-1974 # 80008328 <states.0+0x30>
    80002ae6:	00015517          	auipc	a0,0x15
    80002aea:	4ca50513          	addi	a0,a0,1226 # 80017fb0 <tickslock>
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	058080e7          	jalr	88(ra) # 80000b46 <initlock>
}
    80002af6:	60a2                	ld	ra,8(sp)
    80002af8:	6402                	ld	s0,0(sp)
    80002afa:	0141                	addi	sp,sp,16
    80002afc:	8082                	ret

0000000080002afe <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002afe:	1141                	addi	sp,sp,-16
    80002b00:	e422                	sd	s0,8(sp)
    80002b02:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b04:	00004797          	auipc	a5,0x4
    80002b08:	8bc78793          	addi	a5,a5,-1860 # 800063c0 <kernelvec>
    80002b0c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b10:	6422                	ld	s0,8(sp)
    80002b12:	0141                	addi	sp,sp,16
    80002b14:	8082                	ret

0000000080002b16 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	e04a                	sd	s2,0(sp)
    80002b20:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b22:	00015917          	auipc	s2,0x15
    80002b26:	48e90913          	addi	s2,s2,1166 # 80017fb0 <tickslock>
    80002b2a:	854a                	mv	a0,s2
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	0aa080e7          	jalr	170(ra) # 80000bd6 <acquire>
  ticks++;
    80002b34:	00006497          	auipc	s1,0x6
    80002b38:	ddc48493          	addi	s1,s1,-548 # 80008910 <ticks>
    80002b3c:	409c                	lw	a5,0(s1)
    80002b3e:	2785                	addiw	a5,a5,1
    80002b40:	c09c                	sw	a5,0(s1)
  update_time();
    80002b42:	00000097          	auipc	ra,0x0
    80002b46:	ecc080e7          	jalr	-308(ra) # 80002a0e <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	00000097          	auipc	ra,0x0
    80002b50:	86c080e7          	jalr	-1940(ra) # 800023b8 <wakeup>
  release(&tickslock);
    80002b54:	854a                	mv	a0,s2
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	134080e7          	jalr	308(ra) # 80000c8a <release>
}
    80002b5e:	60e2                	ld	ra,24(sp)
    80002b60:	6442                	ld	s0,16(sp)
    80002b62:	64a2                	ld	s1,8(sp)
    80002b64:	6902                	ld	s2,0(sp)
    80002b66:	6105                	addi	sp,sp,32
    80002b68:	8082                	ret

0000000080002b6a <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002b6a:	1101                	addi	sp,sp,-32
    80002b6c:	ec06                	sd	ra,24(sp)
    80002b6e:	e822                	sd	s0,16(sp)
    80002b70:	e426                	sd	s1,8(sp)
    80002b72:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b74:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002b78:	00074d63          	bltz	a4,80002b92 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002b7c:	57fd                	li	a5,-1
    80002b7e:	17fe                	slli	a5,a5,0x3f
    80002b80:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002b82:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002b84:	06f70363          	beq	a4,a5,80002bea <devintr+0x80>
  }
}
    80002b88:	60e2                	ld	ra,24(sp)
    80002b8a:	6442                	ld	s0,16(sp)
    80002b8c:	64a2                	ld	s1,8(sp)
    80002b8e:	6105                	addi	sp,sp,32
    80002b90:	8082                	ret
      (scause & 0xff) == 9)
    80002b92:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002b96:	46a5                	li	a3,9
    80002b98:	fed792e3          	bne	a5,a3,80002b7c <devintr+0x12>
    int irq = plic_claim();
    80002b9c:	00004097          	auipc	ra,0x4
    80002ba0:	92c080e7          	jalr	-1748(ra) # 800064c8 <plic_claim>
    80002ba4:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ba6:	47a9                	li	a5,10
    80002ba8:	02f50763          	beq	a0,a5,80002bd6 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002bac:	4785                	li	a5,1
    80002bae:	02f50963          	beq	a0,a5,80002be0 <devintr+0x76>
    return 1;
    80002bb2:	4505                	li	a0,1
    else if (irq)
    80002bb4:	d8f1                	beqz	s1,80002b88 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bb6:	85a6                	mv	a1,s1
    80002bb8:	00005517          	auipc	a0,0x5
    80002bbc:	77850513          	addi	a0,a0,1912 # 80008330 <states.0+0x38>
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	9c8080e7          	jalr	-1592(ra) # 80000588 <printf>
      plic_complete(irq);
    80002bc8:	8526                	mv	a0,s1
    80002bca:	00004097          	auipc	ra,0x4
    80002bce:	922080e7          	jalr	-1758(ra) # 800064ec <plic_complete>
    return 1;
    80002bd2:	4505                	li	a0,1
    80002bd4:	bf55                	j	80002b88 <devintr+0x1e>
      uartintr();
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	dc4080e7          	jalr	-572(ra) # 8000099a <uartintr>
    80002bde:	b7ed                	j	80002bc8 <devintr+0x5e>
      virtio_disk_intr();
    80002be0:	00004097          	auipc	ra,0x4
    80002be4:	dd8080e7          	jalr	-552(ra) # 800069b8 <virtio_disk_intr>
    80002be8:	b7c5                	j	80002bc8 <devintr+0x5e>
    if (cpuid() == 0)
    80002bea:	fffff097          	auipc	ra,0xfffff
    80002bee:	d96080e7          	jalr	-618(ra) # 80001980 <cpuid>
    80002bf2:	c901                	beqz	a0,80002c02 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002bf4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002bf8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002bfa:	14479073          	csrw	sip,a5
    return 2;
    80002bfe:	4509                	li	a0,2
    80002c00:	b761                	j	80002b88 <devintr+0x1e>
      clockintr();
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	f14080e7          	jalr	-236(ra) # 80002b16 <clockintr>
    80002c0a:	b7ed                	j	80002bf4 <devintr+0x8a>

0000000080002c0c <usertrapret>:
{
    80002c0c:	7179                	addi	sp,sp,-48
    80002c0e:	f406                	sd	ra,40(sp)
    80002c10:	f022                	sd	s0,32(sp)
    80002c12:	ec26                	sd	s1,24(sp)
    80002c14:	e84a                	sd	s2,16(sp)
    80002c16:	e44e                	sd	s3,8(sp)
    80002c18:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002c1a:	fffff097          	auipc	ra,0xfffff
    80002c1e:	d92080e7          	jalr	-622(ra) # 800019ac <myproc>
    80002c22:	84aa                	mv	s1,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c24:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c2a:	10079073          	csrw	sstatus,a5
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c2e:	00004617          	auipc	a2,0x4
    80002c32:	3d260613          	addi	a2,a2,978 # 80007000 <_trampoline>
    80002c36:	00004697          	auipc	a3,0x4
    80002c3a:	3ca68693          	addi	a3,a3,970 # 80007000 <_trampoline>
    80002c3e:	8e91                	sub	a3,a3,a2
    80002c40:	040007b7          	lui	a5,0x4000
    80002c44:	17fd                	addi	a5,a5,-1
    80002c46:	07b2                	slli	a5,a5,0xc
    80002c48:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c4a:	10569073          	csrw	stvec,a3
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c4e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c50:	180026f3          	csrr	a3,satp
    80002c54:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c56:	6d38                	ld	a4,88(a0)
    80002c58:	6134                	ld	a3,64(a0)
    80002c5a:	6585                	lui	a1,0x1
    80002c5c:	96ae                	add	a3,a3,a1
    80002c5e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c60:	6d38                	ld	a4,88(a0)
    80002c62:	00000697          	auipc	a3,0x0
    80002c66:	0a668693          	addi	a3,a3,166 # 80002d08 <usertrap>
    80002c6a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002c6c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c6e:	8692                	mv	a3,tp
    80002c70:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c72:	100026f3          	csrr	a3,sstatus
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c76:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c7a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c7e:	10069073          	csrw	sstatus,a3
  w_sepc(p->trapframe->epc);
    80002c82:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c84:	6f18                	ld	a4,24(a4)
    80002c86:	14171073          	csrw	sepc,a4
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c8a:	6928                	ld	a0,80(a0)
    80002c8c:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c8e:	00004717          	auipc	a4,0x4
    80002c92:	40e70713          	addi	a4,a4,1038 # 8000709c <userret>
    80002c96:	8f11                	sub	a4,a4,a2
    80002c98:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c9a:	577d                	li	a4,-1
    80002c9c:	177e                	slli	a4,a4,0x3f
    80002c9e:	8d59                	or	a0,a0,a4
    80002ca0:	9782                	jalr	a5
  int which_dev = devintr();
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	ec8080e7          	jalr	-312(ra) # 80002b6a <devintr>
    if (which_dev == 2)
    80002caa:	4789                	li	a5,2
    80002cac:	00f50963          	beq	a0,a5,80002cbe <usertrapret+0xb2>
}
    80002cb0:	70a2                	ld	ra,40(sp)
    80002cb2:	7402                	ld	s0,32(sp)
    80002cb4:	64e2                	ld	s1,24(sp)
    80002cb6:	6942                	ld	s2,16(sp)
    80002cb8:	69a2                	ld	s3,8(sp)
    80002cba:	6145                	addi	sp,sp,48
    80002cbc:	8082                	ret
      if (p->alarm_on == 0)
    80002cbe:	1904a783          	lw	a5,400(s1)
    80002cc2:	f7fd                	bnez	a5,80002cb0 <usertrapret+0xa4>
        p->alarm_on=1;
    80002cc4:	4985                	li	s3,1
    80002cc6:	1934a823          	sw	s3,400(s1)
        struct trapframe *tf = kalloc();   // allocate mem for new trapframe
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	e1c080e7          	jalr	-484(ra) # 80000ae6 <kalloc>
    80002cd2:	892a                	mv	s2,a0
        memmove(tf, p->trapframe, PGSIZE); // copies current trapframe contents to allocated tf, saving current CPU state
    80002cd4:	6605                	lui	a2,0x1
    80002cd6:	6cac                	ld	a1,88(s1)
    80002cd8:	ffffe097          	auipc	ra,0xffffe
    80002cdc:	056080e7          	jalr	86(ra) # 80000d2e <memmove>
        p->alarm_tf = tf;
    80002ce0:	1924b423          	sd	s2,392(s1)
        p->alarm_on = 1;
    80002ce4:	1934a823          	sw	s3,400(s1)
        p->cur_ticks++;
    80002ce8:	1844a783          	lw	a5,388(s1)
    80002cec:	2785                	addiw	a5,a5,1
    80002cee:	0007871b          	sext.w	a4,a5
    80002cf2:	18f4a223          	sw	a5,388(s1)
        if (p->cur_ticks >= p->ticks)
    80002cf6:	1804a783          	lw	a5,384(s1)
    80002cfa:	faf74be3          	blt	a4,a5,80002cb0 <usertrapret+0xa4>
          p->trapframe->epc = p->handler; // updates epc (Exception Program Counter) to the next instruction when an interrupt occurs
    80002cfe:	6cbc                	ld	a5,88(s1)
    80002d00:	1784b703          	ld	a4,376(s1)
    80002d04:	ef98                	sd	a4,24(a5)
}
    80002d06:	b76d                	j	80002cb0 <usertrapret+0xa4>

0000000080002d08 <usertrap>:
{
    80002d08:	7179                	addi	sp,sp,-48
    80002d0a:	f406                	sd	ra,40(sp)
    80002d0c:	f022                	sd	s0,32(sp)
    80002d0e:	ec26                	sd	s1,24(sp)
    80002d10:	e84a                	sd	s2,16(sp)
    80002d12:	e44e                	sd	s3,8(sp)
    80002d14:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d16:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d1a:	1007f793          	andi	a5,a5,256
    80002d1e:	efb1                	bnez	a5,80002d7a <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d20:	00003797          	auipc	a5,0x3
    80002d24:	6a078793          	addi	a5,a5,1696 # 800063c0 <kernelvec>
    80002d28:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	c80080e7          	jalr	-896(ra) # 800019ac <myproc>
    80002d34:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d36:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d38:	14102773          	csrr	a4,sepc
    80002d3c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d3e:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002d42:	47a1                	li	a5,8
    80002d44:	04f70363          	beq	a4,a5,80002d8a <usertrap+0x82>
  else if ((which_dev = devintr()) != 0)
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	e22080e7          	jalr	-478(ra) # 80002b6a <devintr>
    80002d50:	892a                	mv	s2,a0
    80002d52:	12050163          	beqz	a0,80002e74 <usertrap+0x16c>
    if (which_dev == 2 && p->alarm_on == 0)
    80002d56:	4789                	li	a5,2
    80002d58:	08f50363          	beq	a0,a5,80002dde <usertrap+0xd6>
  if (killed(p))
    80002d5c:	8526                	mv	a0,s1
    80002d5e:	00000097          	auipc	ra,0x0
    80002d62:	8aa080e7          	jalr	-1878(ra) # 80002608 <killed>
    80002d66:	14051563          	bnez	a0,80002eb0 <usertrap+0x1a8>
    if (which_dev == 1) //I/O call
    80002d6a:	4785                	li	a5,1
    80002d6c:	04f91863          	bne	s2,a5,80002dbc <usertrap+0xb4>
        yield();}
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	5a8080e7          	jalr	1448(ra) # 80002318 <yield>
    80002d78:	a091                	j	80002dbc <usertrap+0xb4>
    panic("usertrap: not from user mode");
    80002d7a:	00005517          	auipc	a0,0x5
    80002d7e:	5d650513          	addi	a0,a0,1494 # 80008350 <states.0+0x58>
    80002d82:	ffffd097          	auipc	ra,0xffffd
    80002d86:	7bc080e7          	jalr	1980(ra) # 8000053e <panic>
    if (killed(p))
    80002d8a:	00000097          	auipc	ra,0x0
    80002d8e:	87e080e7          	jalr	-1922(ra) # 80002608 <killed>
    80002d92:	e121                	bnez	a0,80002dd2 <usertrap+0xca>
    p->trapframe->epc += 4;
    80002d94:	6cb8                	ld	a4,88(s1)
    80002d96:	6f1c                	ld	a5,24(a4)
    80002d98:	0791                	addi	a5,a5,4
    80002d9a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002da0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002da4:	10079073          	csrw	sstatus,a5
    syscall();
    80002da8:	00000097          	auipc	ra,0x0
    80002dac:	4c4080e7          	jalr	1220(ra) # 8000326c <syscall>
  if (killed(p))
    80002db0:	8526                	mv	a0,s1
    80002db2:	00000097          	auipc	ra,0x0
    80002db6:	856080e7          	jalr	-1962(ra) # 80002608 <killed>
    80002dba:	e975                	bnez	a0,80002eae <usertrap+0x1a6>
  usertrapret();
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	e50080e7          	jalr	-432(ra) # 80002c0c <usertrapret>
}
    80002dc4:	70a2                	ld	ra,40(sp)
    80002dc6:	7402                	ld	s0,32(sp)
    80002dc8:	64e2                	ld	s1,24(sp)
    80002dca:	6942                	ld	s2,16(sp)
    80002dcc:	69a2                	ld	s3,8(sp)
    80002dce:	6145                	addi	sp,sp,48
    80002dd0:	8082                	ret
      exit(-1);
    80002dd2:	557d                	li	a0,-1
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	6b4080e7          	jalr	1716(ra) # 80002488 <exit>
    80002ddc:	bf65                	j	80002d94 <usertrap+0x8c>
    if (which_dev == 2 && p->alarm_on == 0)
    80002dde:	1904a783          	lw	a5,400(s1)
    80002de2:	cba9                	beqz	a5,80002e34 <usertrap+0x12c>
  if (killed(p))
    80002de4:	8526                	mv	a0,s1
    80002de6:	00000097          	auipc	ra,0x0
    80002dea:	822080e7          	jalr	-2014(ra) # 80002608 <killed>
    80002dee:	e169                	bnez	a0,80002eb0 <usertrap+0x1a8>
      struct proc *p = myproc();
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	bbc080e7          	jalr	-1092(ra) # 800019ac <myproc>
      if(p->queticks==0)
    80002df8:	1a052783          	lw	a5,416(a0)
    80002dfc:	12079463          	bnez	a5,80002f24 <usertrap+0x21c>
       if(p->priority!=3)
    80002e00:	19c52783          	lw	a5,412(a0)
    80002e04:	470d                	li	a4,3
    80002e06:	02e78063          	beq	a5,a4,80002e26 <usertrap+0x11e>
            p->priority++;
    80002e0a:	2785                	addiw	a5,a5,1
    80002e0c:	0007871b          	sext.w	a4,a5
    80002e10:	18f52e23          	sw	a5,412(a0)
        if(p->priority==1)
    80002e14:	4785                	li	a5,1
    80002e16:	0af70963          	beq	a4,a5,80002ec8 <usertrap+0x1c0>
          else if(p->priority==2)
    80002e1a:	4789                	li	a5,2
    80002e1c:	0cf70d63          	beq	a4,a5,80002ef6 <usertrap+0x1ee>
          else if(p->priority==3)
    80002e20:	478d                	li	a5,3
    80002e22:	0af71963          	bne	a4,a5,80002ed4 <usertrap+0x1cc>
          p->que3time=ticks;
    80002e26:	00006797          	auipc	a5,0x6
    80002e2a:	aea7a783          	lw	a5,-1302(a5) # 80008910 <ticks>
    80002e2e:	1af52c23          	sw	a5,440(a0)
    80002e32:	a04d                	j	80002ed4 <usertrap+0x1cc>
      p->alarm_on = 1;
    80002e34:	4785                	li	a5,1
    80002e36:	18f4a823          	sw	a5,400(s1)
      struct trapframe *tf = kalloc();
    80002e3a:	ffffe097          	auipc	ra,0xffffe
    80002e3e:	cac080e7          	jalr	-852(ra) # 80000ae6 <kalloc>
    80002e42:	89aa                	mv	s3,a0
      memmove(tf, p->trapframe, PGSIZE);
    80002e44:	6605                	lui	a2,0x1
    80002e46:	6cac                	ld	a1,88(s1)
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	ee6080e7          	jalr	-282(ra) # 80000d2e <memmove>
      p->alarm_tf = tf;
    80002e50:	1934b423          	sd	s3,392(s1)
      p->cur_ticks+=2;
    80002e54:	1844a783          	lw	a5,388(s1)
    80002e58:	2789                	addiw	a5,a5,2
    80002e5a:	0007871b          	sext.w	a4,a5
    80002e5e:	18f4a223          	sw	a5,388(s1)
      if (p->cur_ticks >= p->ticks)
    80002e62:	1804a783          	lw	a5,384(s1)
    80002e66:	f6f74fe3          	blt	a4,a5,80002de4 <usertrap+0xdc>
        p->trapframe->epc = p->handler;
    80002e6a:	6cbc                	ld	a5,88(s1)
    80002e6c:	1784b703          	ld	a4,376(s1)
    80002e70:	ef98                	sd	a4,24(a5)
    80002e72:	bf8d                	j	80002de4 <usertrap+0xdc>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e74:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e78:	5890                	lw	a2,48(s1)
    80002e7a:	00005517          	auipc	a0,0x5
    80002e7e:	4f650513          	addi	a0,a0,1270 # 80008370 <states.0+0x78>
    80002e82:	ffffd097          	auipc	ra,0xffffd
    80002e86:	706080e7          	jalr	1798(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e8a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e8e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e92:	00005517          	auipc	a0,0x5
    80002e96:	50e50513          	addi	a0,a0,1294 # 800083a0 <states.0+0xa8>
    80002e9a:	ffffd097          	auipc	ra,0xffffd
    80002e9e:	6ee080e7          	jalr	1774(ra) # 80000588 <printf>
    setkilled(p);
    80002ea2:	8526                	mv	a0,s1
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	738080e7          	jalr	1848(ra) # 800025dc <setkilled>
    80002eac:	b711                	j	80002db0 <usertrap+0xa8>
  if (killed(p))
    80002eae:	4901                	li	s2,0
    exit(-1);
    80002eb0:	557d                	li	a0,-1
    80002eb2:	fffff097          	auipc	ra,0xfffff
    80002eb6:	5d6080e7          	jalr	1494(ra) # 80002488 <exit>
    if (which_dev == 1) //I/O call
    80002eba:	4785                	li	a5,1
    80002ebc:	eaf90ae3          	beq	s2,a5,80002d70 <usertrap+0x68>
    else if(which_dev==2){
    80002ec0:	4789                	li	a5,2
    80002ec2:	eef91de3          	bne	s2,a5,80002dbc <usertrap+0xb4>
    80002ec6:	b72d                	j	80002df0 <usertrap+0xe8>
          p->que1time=ticks;
    80002ec8:	00006797          	auipc	a5,0x6
    80002ecc:	a487a783          	lw	a5,-1464(a5) # 80008910 <ticks>
    80002ed0:	1af52823          	sw	a5,432(a0)
       if(p->prevticks==1)
    80002ed4:	1a852783          	lw	a5,424(a0)
    80002ed8:	4705                	li	a4,1
    80002eda:	02e78563          	beq	a5,a4,80002f04 <usertrap+0x1fc>
       else if(p->prevticks==3)
    80002ede:	470d                	li	a4,3
    80002ee0:	02e78c63          	beq	a5,a4,80002f18 <usertrap+0x210>
       else if(p->prevticks==9)
    80002ee4:	4725                	li	a4,9
    80002ee6:	02e79463          	bne	a5,a4,80002f0e <usertrap+0x206>
          p->queticks=15;
    80002eea:	47bd                	li	a5,15
    80002eec:	1af52023          	sw	a5,416(a0)
          p->prevticks=15;
    80002ef0:	1af52423          	sw	a5,424(a0)
    80002ef4:	a829                	j	80002f0e <usertrap+0x206>
          p->que2time=ticks;
    80002ef6:	00006797          	auipc	a5,0x6
    80002efa:	a1a7a783          	lw	a5,-1510(a5) # 80008910 <ticks>
    80002efe:	1af52a23          	sw	a5,436(a0)
    80002f02:	bfc9                	j	80002ed4 <usertrap+0x1cc>
          p->queticks=3;
    80002f04:	478d                	li	a5,3
    80002f06:	1af52023          	sw	a5,416(a0)
          p->prevticks=3;
    80002f0a:	1af52423          	sw	a5,424(a0)
        yield();
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	40a080e7          	jalr	1034(ra) # 80002318 <yield>
    80002f16:	b55d                	j	80002dbc <usertrap+0xb4>
          p->queticks=9;
    80002f18:	47a5                	li	a5,9
    80002f1a:	1af52023          	sw	a5,416(a0)
          p->prevticks=9;
    80002f1e:	1af52423          	sw	a5,424(a0)
    80002f22:	b7f5                	j	80002f0e <usertrap+0x206>
      else if(p->queticks>0)
    80002f24:	e8f05ce3          	blez	a5,80002dbc <usertrap+0xb4>
          p->queticks--;
    80002f28:	37fd                	addiw	a5,a5,-1
    80002f2a:	1af52023          	sw	a5,416(a0)
    80002f2e:	b579                	j	80002dbc <usertrap+0xb4>

0000000080002f30 <kerneltrap>:
{
    80002f30:	7179                	addi	sp,sp,-48
    80002f32:	f406                	sd	ra,40(sp)
    80002f34:	f022                	sd	s0,32(sp)
    80002f36:	ec26                	sd	s1,24(sp)
    80002f38:	e84a                	sd	s2,16(sp)
    80002f3a:	e44e                	sd	s3,8(sp)
    80002f3c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f3e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f42:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f46:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002f4a:	1004f793          	andi	a5,s1,256
    80002f4e:	cb9d                	beqz	a5,80002f84 <kerneltrap+0x54>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f50:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f54:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002f56:	ef9d                	bnez	a5,80002f94 <kerneltrap+0x64>
  if ((which_dev = devintr()) == 0)
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	c12080e7          	jalr	-1006(ra) # 80002b6a <devintr>
    80002f60:	c131                	beqz	a0,80002fa4 <kerneltrap+0x74>
   if (which_dev == 2 && myproc() != 0 && myproc()->state != RUNNING)
    80002f62:	4789                	li	a5,2
    80002f64:	06f50d63          	beq	a0,a5,80002fde <kerneltrap+0xae>
  if (which_dev == 1 && myproc() != 0 && myproc()->state == RUNNING) // I/O interrupt
    80002f68:	4785                	li	a5,1
    80002f6a:	14f50563          	beq	a0,a5,800030b4 <kerneltrap+0x184>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f6e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f72:	10049073          	csrw	sstatus,s1
}
    80002f76:	70a2                	ld	ra,40(sp)
    80002f78:	7402                	ld	s0,32(sp)
    80002f7a:	64e2                	ld	s1,24(sp)
    80002f7c:	6942                	ld	s2,16(sp)
    80002f7e:	69a2                	ld	s3,8(sp)
    80002f80:	6145                	addi	sp,sp,48
    80002f82:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f84:	00005517          	auipc	a0,0x5
    80002f88:	43c50513          	addi	a0,a0,1084 # 800083c0 <states.0+0xc8>
    80002f8c:	ffffd097          	auipc	ra,0xffffd
    80002f90:	5b2080e7          	jalr	1458(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002f94:	00005517          	auipc	a0,0x5
    80002f98:	45450513          	addi	a0,a0,1108 # 800083e8 <states.0+0xf0>
    80002f9c:	ffffd097          	auipc	ra,0xffffd
    80002fa0:	5a2080e7          	jalr	1442(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002fa4:	85ce                	mv	a1,s3
    80002fa6:	00005517          	auipc	a0,0x5
    80002faa:	46250513          	addi	a0,a0,1122 # 80008408 <states.0+0x110>
    80002fae:	ffffd097          	auipc	ra,0xffffd
    80002fb2:	5da080e7          	jalr	1498(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fb6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fba:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fbe:	00005517          	auipc	a0,0x5
    80002fc2:	45a50513          	addi	a0,a0,1114 # 80008418 <states.0+0x120>
    80002fc6:	ffffd097          	auipc	ra,0xffffd
    80002fca:	5c2080e7          	jalr	1474(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002fce:	00005517          	auipc	a0,0x5
    80002fd2:	46250513          	addi	a0,a0,1122 # 80008430 <states.0+0x138>
    80002fd6:	ffffd097          	auipc	ra,0xffffd
    80002fda:	568080e7          	jalr	1384(ra) # 8000053e <panic>
   if (which_dev == 2 && myproc() != 0 && myproc()->state != RUNNING)
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	9ce080e7          	jalr	-1586(ra) # 800019ac <myproc>
    80002fe6:	c509                	beqz	a0,80002ff0 <kerneltrap+0xc0>
    80002fe8:	fffff097          	auipc	ra,0xfffff
    80002fec:	9c4080e7          	jalr	-1596(ra) # 800019ac <myproc>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	9bc080e7          	jalr	-1604(ra) # 800019ac <myproc>
    80002ff8:	d93d                	beqz	a0,80002f6e <kerneltrap+0x3e>
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	9b2080e7          	jalr	-1614(ra) # 800019ac <myproc>
    80003002:	4d18                	lw	a4,24(a0)
    80003004:	4791                	li	a5,4
    80003006:	f6f714e3          	bne	a4,a5,80002f6e <kerneltrap+0x3e>
    struct proc *p = myproc();
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	9a2080e7          	jalr	-1630(ra) # 800019ac <myproc>
      if(p->queticks==0)
    80003012:	1a052783          	lw	a5,416(a0)
    80003016:	ebc9                	bnez	a5,800030a8 <kerneltrap+0x178>
       if(p->priority!=3)
    80003018:	19c52783          	lw	a5,412(a0)
    8000301c:	470d                	li	a4,3
    8000301e:	02e78063          	beq	a5,a4,8000303e <kerneltrap+0x10e>
            p->priority++;
    80003022:	2785                	addiw	a5,a5,1
    80003024:	0007871b          	sext.w	a4,a5
    80003028:	18f52e23          	sw	a5,412(a0)
        if(p->priority==1)
    8000302c:	4785                	li	a5,1
    8000302e:	00f70f63          	beq	a4,a5,8000304c <kerneltrap+0x11c>
          else if(p->priority==2)
    80003032:	4789                	li	a5,2
    80003034:	04f70363          	beq	a4,a5,8000307a <kerneltrap+0x14a>
          else if(p->priority==3)
    80003038:	478d                	li	a5,3
    8000303a:	00f71f63          	bne	a4,a5,80003058 <kerneltrap+0x128>
          p->que3time=ticks;
    8000303e:	00006797          	auipc	a5,0x6
    80003042:	8d27a783          	lw	a5,-1838(a5) # 80008910 <ticks>
    80003046:	1af52c23          	sw	a5,440(a0)
    8000304a:	a039                	j	80003058 <kerneltrap+0x128>
          p->que1time=ticks;
    8000304c:	00006797          	auipc	a5,0x6
    80003050:	8c47a783          	lw	a5,-1852(a5) # 80008910 <ticks>
    80003054:	1af52823          	sw	a5,432(a0)
       if(p->prevticks==1)
    80003058:	1a852783          	lw	a5,424(a0)
    8000305c:	4705                	li	a4,1
    8000305e:	02e78563          	beq	a5,a4,80003088 <kerneltrap+0x158>
       else if(p->prevticks==3)
    80003062:	470d                	li	a4,3
    80003064:	02e78c63          	beq	a5,a4,8000309c <kerneltrap+0x16c>
       else if(p->prevticks==9)
    80003068:	4725                	li	a4,9
    8000306a:	02e79463          	bne	a5,a4,80003092 <kerneltrap+0x162>
          p->queticks=15;
    8000306e:	47bd                	li	a5,15
    80003070:	1af52023          	sw	a5,416(a0)
          p->prevticks=15;
    80003074:	1af52423          	sw	a5,424(a0)
    80003078:	a829                	j	80003092 <kerneltrap+0x162>
          p->que2time=ticks;
    8000307a:	00006797          	auipc	a5,0x6
    8000307e:	8967a783          	lw	a5,-1898(a5) # 80008910 <ticks>
    80003082:	1af52a23          	sw	a5,436(a0)
    80003086:	bfc9                	j	80003058 <kerneltrap+0x128>
          p->queticks=3;
    80003088:	478d                	li	a5,3
    8000308a:	1af52023          	sw	a5,416(a0)
          p->prevticks=3;
    8000308e:	1af52423          	sw	a5,424(a0)
        yield();
    80003092:	fffff097          	auipc	ra,0xfffff
    80003096:	286080e7          	jalr	646(ra) # 80002318 <yield>
    8000309a:	bdd1                	j	80002f6e <kerneltrap+0x3e>
          p->queticks=9;
    8000309c:	47a5                	li	a5,9
    8000309e:	1af52023          	sw	a5,416(a0)
          p->prevticks=9;
    800030a2:	1af52423          	sw	a5,424(a0)
    800030a6:	b7f5                	j	80003092 <kerneltrap+0x162>
      else if(p->queticks>0)
    800030a8:	ecf053e3          	blez	a5,80002f6e <kerneltrap+0x3e>
        p->queticks--;
    800030ac:	37fd                	addiw	a5,a5,-1
    800030ae:	1af52023          	sw	a5,416(a0)
    800030b2:	bd75                	j	80002f6e <kerneltrap+0x3e>
  if (which_dev == 1 && myproc() != 0 && myproc()->state == RUNNING) // I/O interrupt
    800030b4:	fffff097          	auipc	ra,0xfffff
    800030b8:	8f8080e7          	jalr	-1800(ra) # 800019ac <myproc>
    800030bc:	c909                	beqz	a0,800030ce <kerneltrap+0x19e>
    800030be:	fffff097          	auipc	ra,0xfffff
    800030c2:	8ee080e7          	jalr	-1810(ra) # 800019ac <myproc>
    800030c6:	4d18                	lw	a4,24(a0)
    800030c8:	4791                	li	a5,4
    800030ca:	00f70d63          	beq	a4,a5,800030e4 <kerneltrap+0x1b4>
  if (which_dev == 1 && myproc() != 0 && myproc()->state != RUNNING)
    800030ce:	fffff097          	auipc	ra,0xfffff
    800030d2:	8de080e7          	jalr	-1826(ra) # 800019ac <myproc>
    800030d6:	e8050ce3          	beqz	a0,80002f6e <kerneltrap+0x3e>
    800030da:	fffff097          	auipc	ra,0xfffff
    800030de:	8d2080e7          	jalr	-1838(ra) # 800019ac <myproc>
    800030e2:	b571                	j	80002f6e <kerneltrap+0x3e>
    yield();
    800030e4:	fffff097          	auipc	ra,0xfffff
    800030e8:	234080e7          	jalr	564(ra) # 80002318 <yield>
    800030ec:	b7cd                	j	800030ce <kerneltrap+0x19e>

00000000800030ee <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800030ee:	1101                	addi	sp,sp,-32
    800030f0:	ec06                	sd	ra,24(sp)
    800030f2:	e822                	sd	s0,16(sp)
    800030f4:	e426                	sd	s1,8(sp)
    800030f6:	1000                	addi	s0,sp,32
    800030f8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030fa:	fffff097          	auipc	ra,0xfffff
    800030fe:	8b2080e7          	jalr	-1870(ra) # 800019ac <myproc>
  switch (n) {
    80003102:	4795                	li	a5,5
    80003104:	0497e163          	bltu	a5,s1,80003146 <argraw+0x58>
    80003108:	048a                	slli	s1,s1,0x2
    8000310a:	00005717          	auipc	a4,0x5
    8000310e:	35e70713          	addi	a4,a4,862 # 80008468 <states.0+0x170>
    80003112:	94ba                	add	s1,s1,a4
    80003114:	409c                	lw	a5,0(s1)
    80003116:	97ba                	add	a5,a5,a4
    80003118:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000311a:	6d3c                	ld	a5,88(a0)
    8000311c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000311e:	60e2                	ld	ra,24(sp)
    80003120:	6442                	ld	s0,16(sp)
    80003122:	64a2                	ld	s1,8(sp)
    80003124:	6105                	addi	sp,sp,32
    80003126:	8082                	ret
    return p->trapframe->a1;
    80003128:	6d3c                	ld	a5,88(a0)
    8000312a:	7fa8                	ld	a0,120(a5)
    8000312c:	bfcd                	j	8000311e <argraw+0x30>
    return p->trapframe->a2;
    8000312e:	6d3c                	ld	a5,88(a0)
    80003130:	63c8                	ld	a0,128(a5)
    80003132:	b7f5                	j	8000311e <argraw+0x30>
    return p->trapframe->a3;
    80003134:	6d3c                	ld	a5,88(a0)
    80003136:	67c8                	ld	a0,136(a5)
    80003138:	b7dd                	j	8000311e <argraw+0x30>
    return p->trapframe->a4;
    8000313a:	6d3c                	ld	a5,88(a0)
    8000313c:	6bc8                	ld	a0,144(a5)
    8000313e:	b7c5                	j	8000311e <argraw+0x30>
    return p->trapframe->a5;
    80003140:	6d3c                	ld	a5,88(a0)
    80003142:	6fc8                	ld	a0,152(a5)
    80003144:	bfe9                	j	8000311e <argraw+0x30>
  panic("argraw");
    80003146:	00005517          	auipc	a0,0x5
    8000314a:	2fa50513          	addi	a0,a0,762 # 80008440 <states.0+0x148>
    8000314e:	ffffd097          	auipc	ra,0xffffd
    80003152:	3f0080e7          	jalr	1008(ra) # 8000053e <panic>

0000000080003156 <fetchaddr>:
{
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	e426                	sd	s1,8(sp)
    8000315e:	e04a                	sd	s2,0(sp)
    80003160:	1000                	addi	s0,sp,32
    80003162:	84aa                	mv	s1,a0
    80003164:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	846080e7          	jalr	-1978(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000316e:	653c                	ld	a5,72(a0)
    80003170:	02f4f863          	bgeu	s1,a5,800031a0 <fetchaddr+0x4a>
    80003174:	00848713          	addi	a4,s1,8
    80003178:	02e7e663          	bltu	a5,a4,800031a4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000317c:	46a1                	li	a3,8
    8000317e:	8626                	mv	a2,s1
    80003180:	85ca                	mv	a1,s2
    80003182:	6928                	ld	a0,80(a0)
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	570080e7          	jalr	1392(ra) # 800016f4 <copyin>
    8000318c:	00a03533          	snez	a0,a0
    80003190:	40a00533          	neg	a0,a0
}
    80003194:	60e2                	ld	ra,24(sp)
    80003196:	6442                	ld	s0,16(sp)
    80003198:	64a2                	ld	s1,8(sp)
    8000319a:	6902                	ld	s2,0(sp)
    8000319c:	6105                	addi	sp,sp,32
    8000319e:	8082                	ret
    return -1;
    800031a0:	557d                	li	a0,-1
    800031a2:	bfcd                	j	80003194 <fetchaddr+0x3e>
    800031a4:	557d                	li	a0,-1
    800031a6:	b7fd                	j	80003194 <fetchaddr+0x3e>

00000000800031a8 <fetchstr>:
{
    800031a8:	7179                	addi	sp,sp,-48
    800031aa:	f406                	sd	ra,40(sp)
    800031ac:	f022                	sd	s0,32(sp)
    800031ae:	ec26                	sd	s1,24(sp)
    800031b0:	e84a                	sd	s2,16(sp)
    800031b2:	e44e                	sd	s3,8(sp)
    800031b4:	1800                	addi	s0,sp,48
    800031b6:	892a                	mv	s2,a0
    800031b8:	84ae                	mv	s1,a1
    800031ba:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800031bc:	ffffe097          	auipc	ra,0xffffe
    800031c0:	7f0080e7          	jalr	2032(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800031c4:	86ce                	mv	a3,s3
    800031c6:	864a                	mv	a2,s2
    800031c8:	85a6                	mv	a1,s1
    800031ca:	6928                	ld	a0,80(a0)
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	5b6080e7          	jalr	1462(ra) # 80001782 <copyinstr>
    800031d4:	00054e63          	bltz	a0,800031f0 <fetchstr+0x48>
  return strlen(buf);
    800031d8:	8526                	mv	a0,s1
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	c74080e7          	jalr	-908(ra) # 80000e4e <strlen>
}
    800031e2:	70a2                	ld	ra,40(sp)
    800031e4:	7402                	ld	s0,32(sp)
    800031e6:	64e2                	ld	s1,24(sp)
    800031e8:	6942                	ld	s2,16(sp)
    800031ea:	69a2                	ld	s3,8(sp)
    800031ec:	6145                	addi	sp,sp,48
    800031ee:	8082                	ret
    return -1;
    800031f0:	557d                	li	a0,-1
    800031f2:	bfc5                	j	800031e2 <fetchstr+0x3a>

00000000800031f4 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800031f4:	1101                	addi	sp,sp,-32
    800031f6:	ec06                	sd	ra,24(sp)
    800031f8:	e822                	sd	s0,16(sp)
    800031fa:	e426                	sd	s1,8(sp)
    800031fc:	1000                	addi	s0,sp,32
    800031fe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003200:	00000097          	auipc	ra,0x0
    80003204:	eee080e7          	jalr	-274(ra) # 800030ee <argraw>
    80003208:	c088                	sw	a0,0(s1)
}
    8000320a:	60e2                	ld	ra,24(sp)
    8000320c:	6442                	ld	s0,16(sp)
    8000320e:	64a2                	ld	s1,8(sp)
    80003210:	6105                	addi	sp,sp,32
    80003212:	8082                	ret

0000000080003214 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003214:	1101                	addi	sp,sp,-32
    80003216:	ec06                	sd	ra,24(sp)
    80003218:	e822                	sd	s0,16(sp)
    8000321a:	e426                	sd	s1,8(sp)
    8000321c:	1000                	addi	s0,sp,32
    8000321e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003220:	00000097          	auipc	ra,0x0
    80003224:	ece080e7          	jalr	-306(ra) # 800030ee <argraw>
    80003228:	e088                	sd	a0,0(s1)
}
    8000322a:	60e2                	ld	ra,24(sp)
    8000322c:	6442                	ld	s0,16(sp)
    8000322e:	64a2                	ld	s1,8(sp)
    80003230:	6105                	addi	sp,sp,32
    80003232:	8082                	ret

0000000080003234 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003234:	7179                	addi	sp,sp,-48
    80003236:	f406                	sd	ra,40(sp)
    80003238:	f022                	sd	s0,32(sp)
    8000323a:	ec26                	sd	s1,24(sp)
    8000323c:	e84a                	sd	s2,16(sp)
    8000323e:	1800                	addi	s0,sp,48
    80003240:	84ae                	mv	s1,a1
    80003242:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003244:	fd840593          	addi	a1,s0,-40
    80003248:	00000097          	auipc	ra,0x0
    8000324c:	fcc080e7          	jalr	-52(ra) # 80003214 <argaddr>
  return fetchstr(addr, buf, max);
    80003250:	864a                	mv	a2,s2
    80003252:	85a6                	mv	a1,s1
    80003254:	fd843503          	ld	a0,-40(s0)
    80003258:	00000097          	auipc	ra,0x0
    8000325c:	f50080e7          	jalr	-176(ra) # 800031a8 <fetchstr>
}
    80003260:	70a2                	ld	ra,40(sp)
    80003262:	7402                	ld	s0,32(sp)
    80003264:	64e2                	ld	s1,24(sp)
    80003266:	6942                	ld	s2,16(sp)
    80003268:	6145                	addi	sp,sp,48
    8000326a:	8082                	ret

000000008000326c <syscall>:
[SYS_sigreturn] sys_sigreturn
};

void
syscall(void)
{
    8000326c:	1101                	addi	sp,sp,-32
    8000326e:	ec06                	sd	ra,24(sp)
    80003270:	e822                	sd	s0,16(sp)
    80003272:	e426                	sd	s1,8(sp)
    80003274:	e04a                	sd	s2,0(sp)
    80003276:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003278:	ffffe097          	auipc	ra,0xffffe
    8000327c:	734080e7          	jalr	1844(ra) # 800019ac <myproc>
    80003280:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003282:	05853903          	ld	s2,88(a0)
    80003286:	0a893783          	ld	a5,168(s2)
    8000328a:	0007869b          	sext.w	a3,a5
  if(num==5)
    8000328e:	4715                	li	a4,5
    80003290:	02e68363          	beq	a3,a4,800032b6 <syscall+0x4a>
  readcount++;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003294:	37fd                	addiw	a5,a5,-1
    80003296:	4761                	li	a4,24
    80003298:	02f76e63          	bltu	a4,a5,800032d4 <syscall+0x68>
    8000329c:	00369713          	slli	a4,a3,0x3
    800032a0:	00005797          	auipc	a5,0x5
    800032a4:	1e078793          	addi	a5,a5,480 # 80008480 <syscalls>
    800032a8:	97ba                	add	a5,a5,a4
    800032aa:	6398                	ld	a4,0(a5)
    800032ac:	c705                	beqz	a4,800032d4 <syscall+0x68>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    800032ae:	9702                	jalr	a4
    800032b0:	06a93823          	sd	a0,112(s2)
    800032b4:	a835                	j	800032f0 <syscall+0x84>
  readcount++;
    800032b6:	00005617          	auipc	a2,0x5
    800032ba:	65e60613          	addi	a2,a2,1630 # 80008914 <readcount>
    800032be:	4218                	lw	a4,0(a2)
    800032c0:	2705                	addiw	a4,a4,1
    800032c2:	c218                	sw	a4,0(a2)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800032c4:	37fd                	addiw	a5,a5,-1
    800032c6:	4661                	li	a2,24
    800032c8:	00002717          	auipc	a4,0x2
    800032cc:	69a70713          	addi	a4,a4,1690 # 80005962 <sys_read>
    800032d0:	fcf67fe3          	bgeu	a2,a5,800032ae <syscall+0x42>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800032d4:	15848613          	addi	a2,s1,344
    800032d8:	588c                	lw	a1,48(s1)
    800032da:	00005517          	auipc	a0,0x5
    800032de:	16e50513          	addi	a0,a0,366 # 80008448 <states.0+0x150>
    800032e2:	ffffd097          	auipc	ra,0xffffd
    800032e6:	2a6080e7          	jalr	678(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800032ea:	6cbc                	ld	a5,88(s1)
    800032ec:	577d                	li	a4,-1
    800032ee:	fbb8                	sd	a4,112(a5)
  }
}
    800032f0:	60e2                	ld	ra,24(sp)
    800032f2:	6442                	ld	s0,16(sp)
    800032f4:	64a2                	ld	s1,8(sp)
    800032f6:	6902                	ld	s2,0(sp)
    800032f8:	6105                	addi	sp,sp,32
    800032fa:	8082                	ret

00000000800032fc <sys_exit>:
//#include "../user/user.h"


uint64
sys_exit(void)
{
    800032fc:	1101                	addi	sp,sp,-32
    800032fe:	ec06                	sd	ra,24(sp)
    80003300:	e822                	sd	s0,16(sp)
    80003302:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003304:	fec40593          	addi	a1,s0,-20
    80003308:	4501                	li	a0,0
    8000330a:	00000097          	auipc	ra,0x0
    8000330e:	eea080e7          	jalr	-278(ra) # 800031f4 <argint>
  exit(n);
    80003312:	fec42503          	lw	a0,-20(s0)
    80003316:	fffff097          	auipc	ra,0xfffff
    8000331a:	172080e7          	jalr	370(ra) # 80002488 <exit>
  return 0; // not reached
}
    8000331e:	4501                	li	a0,0
    80003320:	60e2                	ld	ra,24(sp)
    80003322:	6442                	ld	s0,16(sp)
    80003324:	6105                	addi	sp,sp,32
    80003326:	8082                	ret

0000000080003328 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003328:	1141                	addi	sp,sp,-16
    8000332a:	e406                	sd	ra,8(sp)
    8000332c:	e022                	sd	s0,0(sp)
    8000332e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	67c080e7          	jalr	1660(ra) # 800019ac <myproc>
}
    80003338:	5908                	lw	a0,48(a0)
    8000333a:	60a2                	ld	ra,8(sp)
    8000333c:	6402                	ld	s0,0(sp)
    8000333e:	0141                	addi	sp,sp,16
    80003340:	8082                	ret

0000000080003342 <sys_fork>:

uint64
sys_fork(void)
{
    80003342:	1141                	addi	sp,sp,-16
    80003344:	e406                	sd	ra,8(sp)
    80003346:	e022                	sd	s0,0(sp)
    80003348:	0800                	addi	s0,sp,16
  return fork();
    8000334a:	fffff097          	auipc	ra,0xfffff
    8000334e:	a60080e7          	jalr	-1440(ra) # 80001daa <fork>
}
    80003352:	60a2                	ld	ra,8(sp)
    80003354:	6402                	ld	s0,0(sp)
    80003356:	0141                	addi	sp,sp,16
    80003358:	8082                	ret

000000008000335a <sys_wait>:

uint64
sys_wait(void)
{
    8000335a:	1101                	addi	sp,sp,-32
    8000335c:	ec06                	sd	ra,24(sp)
    8000335e:	e822                	sd	s0,16(sp)
    80003360:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003362:	fe840593          	addi	a1,s0,-24
    80003366:	4501                	li	a0,0
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	eac080e7          	jalr	-340(ra) # 80003214 <argaddr>
  return wait(p);
    80003370:	fe843503          	ld	a0,-24(s0)
    80003374:	fffff097          	auipc	ra,0xfffff
    80003378:	2c6080e7          	jalr	710(ra) # 8000263a <wait>
}
    8000337c:	60e2                	ld	ra,24(sp)
    8000337e:	6442                	ld	s0,16(sp)
    80003380:	6105                	addi	sp,sp,32
    80003382:	8082                	ret

0000000080003384 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003384:	7179                	addi	sp,sp,-48
    80003386:	f406                	sd	ra,40(sp)
    80003388:	f022                	sd	s0,32(sp)
    8000338a:	ec26                	sd	s1,24(sp)
    8000338c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000338e:	fdc40593          	addi	a1,s0,-36
    80003392:	4501                	li	a0,0
    80003394:	00000097          	auipc	ra,0x0
    80003398:	e60080e7          	jalr	-416(ra) # 800031f4 <argint>
  addr = myproc()->sz;
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	610080e7          	jalr	1552(ra) # 800019ac <myproc>
    800033a4:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800033a6:	fdc42503          	lw	a0,-36(s0)
    800033aa:	fffff097          	auipc	ra,0xfffff
    800033ae:	9a4080e7          	jalr	-1628(ra) # 80001d4e <growproc>
    800033b2:	00054863          	bltz	a0,800033c2 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800033b6:	8526                	mv	a0,s1
    800033b8:	70a2                	ld	ra,40(sp)
    800033ba:	7402                	ld	s0,32(sp)
    800033bc:	64e2                	ld	s1,24(sp)
    800033be:	6145                	addi	sp,sp,48
    800033c0:	8082                	ret
    return -1;
    800033c2:	54fd                	li	s1,-1
    800033c4:	bfcd                	j	800033b6 <sys_sbrk+0x32>

00000000800033c6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800033c6:	7139                	addi	sp,sp,-64
    800033c8:	fc06                	sd	ra,56(sp)
    800033ca:	f822                	sd	s0,48(sp)
    800033cc:	f426                	sd	s1,40(sp)
    800033ce:	f04a                	sd	s2,32(sp)
    800033d0:	ec4e                	sd	s3,24(sp)
    800033d2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800033d4:	fcc40593          	addi	a1,s0,-52
    800033d8:	4501                	li	a0,0
    800033da:	00000097          	auipc	ra,0x0
    800033de:	e1a080e7          	jalr	-486(ra) # 800031f4 <argint>
  acquire(&tickslock);
    800033e2:	00015517          	auipc	a0,0x15
    800033e6:	bce50513          	addi	a0,a0,-1074 # 80017fb0 <tickslock>
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	7ec080e7          	jalr	2028(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800033f2:	00005917          	auipc	s2,0x5
    800033f6:	51e92903          	lw	s2,1310(s2) # 80008910 <ticks>
  while (ticks - ticks0 < n)
    800033fa:	fcc42783          	lw	a5,-52(s0)
    800033fe:	cf9d                	beqz	a5,8000343c <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003400:	00015997          	auipc	s3,0x15
    80003404:	bb098993          	addi	s3,s3,-1104 # 80017fb0 <tickslock>
    80003408:	00005497          	auipc	s1,0x5
    8000340c:	50848493          	addi	s1,s1,1288 # 80008910 <ticks>
    if (killed(myproc()))
    80003410:	ffffe097          	auipc	ra,0xffffe
    80003414:	59c080e7          	jalr	1436(ra) # 800019ac <myproc>
    80003418:	fffff097          	auipc	ra,0xfffff
    8000341c:	1f0080e7          	jalr	496(ra) # 80002608 <killed>
    80003420:	ed15                	bnez	a0,8000345c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003422:	85ce                	mv	a1,s3
    80003424:	8526                	mv	a0,s1
    80003426:	fffff097          	auipc	ra,0xfffff
    8000342a:	f2e080e7          	jalr	-210(ra) # 80002354 <sleep>
  while (ticks - ticks0 < n)
    8000342e:	409c                	lw	a5,0(s1)
    80003430:	412787bb          	subw	a5,a5,s2
    80003434:	fcc42703          	lw	a4,-52(s0)
    80003438:	fce7ece3          	bltu	a5,a4,80003410 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000343c:	00015517          	auipc	a0,0x15
    80003440:	b7450513          	addi	a0,a0,-1164 # 80017fb0 <tickslock>
    80003444:	ffffe097          	auipc	ra,0xffffe
    80003448:	846080e7          	jalr	-1978(ra) # 80000c8a <release>
  return 0;
    8000344c:	4501                	li	a0,0
}
    8000344e:	70e2                	ld	ra,56(sp)
    80003450:	7442                	ld	s0,48(sp)
    80003452:	74a2                	ld	s1,40(sp)
    80003454:	7902                	ld	s2,32(sp)
    80003456:	69e2                	ld	s3,24(sp)
    80003458:	6121                	addi	sp,sp,64
    8000345a:	8082                	ret
      release(&tickslock);
    8000345c:	00015517          	auipc	a0,0x15
    80003460:	b5450513          	addi	a0,a0,-1196 # 80017fb0 <tickslock>
    80003464:	ffffe097          	auipc	ra,0xffffe
    80003468:	826080e7          	jalr	-2010(ra) # 80000c8a <release>
      return -1;
    8000346c:	557d                	li	a0,-1
    8000346e:	b7c5                	j	8000344e <sys_sleep+0x88>

0000000080003470 <sys_kill>:

uint64
sys_kill(void)
{
    80003470:	1101                	addi	sp,sp,-32
    80003472:	ec06                	sd	ra,24(sp)
    80003474:	e822                	sd	s0,16(sp)
    80003476:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003478:	fec40593          	addi	a1,s0,-20
    8000347c:	4501                	li	a0,0
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	d76080e7          	jalr	-650(ra) # 800031f4 <argint>
  return kill(pid);
    80003486:	fec42503          	lw	a0,-20(s0)
    8000348a:	fffff097          	auipc	ra,0xfffff
    8000348e:	0e0080e7          	jalr	224(ra) # 8000256a <kill>
}
    80003492:	60e2                	ld	ra,24(sp)
    80003494:	6442                	ld	s0,16(sp)
    80003496:	6105                	addi	sp,sp,32
    80003498:	8082                	ret

000000008000349a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000349a:	1101                	addi	sp,sp,-32
    8000349c:	ec06                	sd	ra,24(sp)
    8000349e:	e822                	sd	s0,16(sp)
    800034a0:	e426                	sd	s1,8(sp)
    800034a2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800034a4:	00015517          	auipc	a0,0x15
    800034a8:	b0c50513          	addi	a0,a0,-1268 # 80017fb0 <tickslock>
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	72a080e7          	jalr	1834(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800034b4:	00005497          	auipc	s1,0x5
    800034b8:	45c4a483          	lw	s1,1116(s1) # 80008910 <ticks>
  release(&tickslock);
    800034bc:	00015517          	auipc	a0,0x15
    800034c0:	af450513          	addi	a0,a0,-1292 # 80017fb0 <tickslock>
    800034c4:	ffffd097          	auipc	ra,0xffffd
    800034c8:	7c6080e7          	jalr	1990(ra) # 80000c8a <release>
  return xticks;
}
    800034cc:	02049513          	slli	a0,s1,0x20
    800034d0:	9101                	srli	a0,a0,0x20
    800034d2:	60e2                	ld	ra,24(sp)
    800034d4:	6442                	ld	s0,16(sp)
    800034d6:	64a2                	ld	s1,8(sp)
    800034d8:	6105                	addi	sp,sp,32
    800034da:	8082                	ret

00000000800034dc <sys_waitx>:

uint64
sys_waitx(void)
{
    800034dc:	7139                	addi	sp,sp,-64
    800034de:	fc06                	sd	ra,56(sp)
    800034e0:	f822                	sd	s0,48(sp)
    800034e2:	f426                	sd	s1,40(sp)
    800034e4:	f04a                	sd	s2,32(sp)
    800034e6:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800034e8:	fd840593          	addi	a1,s0,-40
    800034ec:	4501                	li	a0,0
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	d26080e7          	jalr	-730(ra) # 80003214 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800034f6:	fd040593          	addi	a1,s0,-48
    800034fa:	4505                	li	a0,1
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	d18080e7          	jalr	-744(ra) # 80003214 <argaddr>
  argaddr(2, &addr2);
    80003504:	fc840593          	addi	a1,s0,-56
    80003508:	4509                	li	a0,2
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	d0a080e7          	jalr	-758(ra) # 80003214 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003512:	fc040613          	addi	a2,s0,-64
    80003516:	fc440593          	addi	a1,s0,-60
    8000351a:	fd843503          	ld	a0,-40(s0)
    8000351e:	fffff097          	auipc	ra,0xfffff
    80003522:	3a4080e7          	jalr	932(ra) # 800028c2 <waitx>
    80003526:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003528:	ffffe097          	auipc	ra,0xffffe
    8000352c:	484080e7          	jalr	1156(ra) # 800019ac <myproc>
    80003530:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003532:	4691                	li	a3,4
    80003534:	fc440613          	addi	a2,s0,-60
    80003538:	fd043583          	ld	a1,-48(s0)
    8000353c:	6928                	ld	a0,80(a0)
    8000353e:	ffffe097          	auipc	ra,0xffffe
    80003542:	12a080e7          	jalr	298(ra) # 80001668 <copyout>
    return -1;
    80003546:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003548:	00054f63          	bltz	a0,80003566 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000354c:	4691                	li	a3,4
    8000354e:	fc040613          	addi	a2,s0,-64
    80003552:	fc843583          	ld	a1,-56(s0)
    80003556:	68a8                	ld	a0,80(s1)
    80003558:	ffffe097          	auipc	ra,0xffffe
    8000355c:	110080e7          	jalr	272(ra) # 80001668 <copyout>
    80003560:	00054a63          	bltz	a0,80003574 <sys_waitx+0x98>
    return -1;
  return ret;
    80003564:	87ca                	mv	a5,s2
}
    80003566:	853e                	mv	a0,a5
    80003568:	70e2                	ld	ra,56(sp)
    8000356a:	7442                	ld	s0,48(sp)
    8000356c:	74a2                	ld	s1,40(sp)
    8000356e:	7902                	ld	s2,32(sp)
    80003570:	6121                	addi	sp,sp,64
    80003572:	8082                	ret
    return -1;
    80003574:	57fd                	li	a5,-1
    80003576:	bfc5                	j	80003566 <sys_waitx+0x8a>

0000000080003578 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003578:	7179                	addi	sp,sp,-48
    8000357a:	f406                	sd	ra,40(sp)
    8000357c:	f022                	sd	s0,32(sp)
    8000357e:	ec26                	sd	s1,24(sp)
    80003580:	e84a                	sd	s2,16(sp)
    80003582:	e44e                	sd	s3,8(sp)
    80003584:	e052                	sd	s4,0(sp)
    80003586:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003588:	00005597          	auipc	a1,0x5
    8000358c:	fc858593          	addi	a1,a1,-56 # 80008550 <syscalls+0xd0>
    80003590:	00015517          	auipc	a0,0x15
    80003594:	a3850513          	addi	a0,a0,-1480 # 80017fc8 <bcache>
    80003598:	ffffd097          	auipc	ra,0xffffd
    8000359c:	5ae080e7          	jalr	1454(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035a0:	0001d797          	auipc	a5,0x1d
    800035a4:	a2878793          	addi	a5,a5,-1496 # 8001ffc8 <bcache+0x8000>
    800035a8:	0001d717          	auipc	a4,0x1d
    800035ac:	c8870713          	addi	a4,a4,-888 # 80020230 <bcache+0x8268>
    800035b0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035b4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035b8:	00015497          	auipc	s1,0x15
    800035bc:	a2848493          	addi	s1,s1,-1496 # 80017fe0 <bcache+0x18>
    b->next = bcache.head.next;
    800035c0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800035c2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800035c4:	00005a17          	auipc	s4,0x5
    800035c8:	f94a0a13          	addi	s4,s4,-108 # 80008558 <syscalls+0xd8>
    b->next = bcache.head.next;
    800035cc:	2b893783          	ld	a5,696(s2)
    800035d0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035d2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035d6:	85d2                	mv	a1,s4
    800035d8:	01048513          	addi	a0,s1,16
    800035dc:	00001097          	auipc	ra,0x1
    800035e0:	4c4080e7          	jalr	1220(ra) # 80004aa0 <initsleeplock>
    bcache.head.next->prev = b;
    800035e4:	2b893783          	ld	a5,696(s2)
    800035e8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035ea:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035ee:	45848493          	addi	s1,s1,1112
    800035f2:	fd349de3          	bne	s1,s3,800035cc <binit+0x54>
  }
}
    800035f6:	70a2                	ld	ra,40(sp)
    800035f8:	7402                	ld	s0,32(sp)
    800035fa:	64e2                	ld	s1,24(sp)
    800035fc:	6942                	ld	s2,16(sp)
    800035fe:	69a2                	ld	s3,8(sp)
    80003600:	6a02                	ld	s4,0(sp)
    80003602:	6145                	addi	sp,sp,48
    80003604:	8082                	ret

0000000080003606 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003606:	7179                	addi	sp,sp,-48
    80003608:	f406                	sd	ra,40(sp)
    8000360a:	f022                	sd	s0,32(sp)
    8000360c:	ec26                	sd	s1,24(sp)
    8000360e:	e84a                	sd	s2,16(sp)
    80003610:	e44e                	sd	s3,8(sp)
    80003612:	1800                	addi	s0,sp,48
    80003614:	892a                	mv	s2,a0
    80003616:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003618:	00015517          	auipc	a0,0x15
    8000361c:	9b050513          	addi	a0,a0,-1616 # 80017fc8 <bcache>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	5b6080e7          	jalr	1462(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003628:	0001d497          	auipc	s1,0x1d
    8000362c:	c584b483          	ld	s1,-936(s1) # 80020280 <bcache+0x82b8>
    80003630:	0001d797          	auipc	a5,0x1d
    80003634:	c0078793          	addi	a5,a5,-1024 # 80020230 <bcache+0x8268>
    80003638:	02f48f63          	beq	s1,a5,80003676 <bread+0x70>
    8000363c:	873e                	mv	a4,a5
    8000363e:	a021                	j	80003646 <bread+0x40>
    80003640:	68a4                	ld	s1,80(s1)
    80003642:	02e48a63          	beq	s1,a4,80003676 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003646:	449c                	lw	a5,8(s1)
    80003648:	ff279ce3          	bne	a5,s2,80003640 <bread+0x3a>
    8000364c:	44dc                	lw	a5,12(s1)
    8000364e:	ff3799e3          	bne	a5,s3,80003640 <bread+0x3a>
      b->refcnt++;
    80003652:	40bc                	lw	a5,64(s1)
    80003654:	2785                	addiw	a5,a5,1
    80003656:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003658:	00015517          	auipc	a0,0x15
    8000365c:	97050513          	addi	a0,a0,-1680 # 80017fc8 <bcache>
    80003660:	ffffd097          	auipc	ra,0xffffd
    80003664:	62a080e7          	jalr	1578(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003668:	01048513          	addi	a0,s1,16
    8000366c:	00001097          	auipc	ra,0x1
    80003670:	46e080e7          	jalr	1134(ra) # 80004ada <acquiresleep>
      return b;
    80003674:	a8b9                	j	800036d2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003676:	0001d497          	auipc	s1,0x1d
    8000367a:	c024b483          	ld	s1,-1022(s1) # 80020278 <bcache+0x82b0>
    8000367e:	0001d797          	auipc	a5,0x1d
    80003682:	bb278793          	addi	a5,a5,-1102 # 80020230 <bcache+0x8268>
    80003686:	00f48863          	beq	s1,a5,80003696 <bread+0x90>
    8000368a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000368c:	40bc                	lw	a5,64(s1)
    8000368e:	cf81                	beqz	a5,800036a6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003690:	64a4                	ld	s1,72(s1)
    80003692:	fee49de3          	bne	s1,a4,8000368c <bread+0x86>
  panic("bget: no buffers");
    80003696:	00005517          	auipc	a0,0x5
    8000369a:	eca50513          	addi	a0,a0,-310 # 80008560 <syscalls+0xe0>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	ea0080e7          	jalr	-352(ra) # 8000053e <panic>
      b->dev = dev;
    800036a6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800036aa:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800036ae:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036b2:	4785                	li	a5,1
    800036b4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036b6:	00015517          	auipc	a0,0x15
    800036ba:	91250513          	addi	a0,a0,-1774 # 80017fc8 <bcache>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	5cc080e7          	jalr	1484(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800036c6:	01048513          	addi	a0,s1,16
    800036ca:	00001097          	auipc	ra,0x1
    800036ce:	410080e7          	jalr	1040(ra) # 80004ada <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036d2:	409c                	lw	a5,0(s1)
    800036d4:	cb89                	beqz	a5,800036e6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036d6:	8526                	mv	a0,s1
    800036d8:	70a2                	ld	ra,40(sp)
    800036da:	7402                	ld	s0,32(sp)
    800036dc:	64e2                	ld	s1,24(sp)
    800036de:	6942                	ld	s2,16(sp)
    800036e0:	69a2                	ld	s3,8(sp)
    800036e2:	6145                	addi	sp,sp,48
    800036e4:	8082                	ret
    virtio_disk_rw(b, 0);
    800036e6:	4581                	li	a1,0
    800036e8:	8526                	mv	a0,s1
    800036ea:	00003097          	auipc	ra,0x3
    800036ee:	09a080e7          	jalr	154(ra) # 80006784 <virtio_disk_rw>
    b->valid = 1;
    800036f2:	4785                	li	a5,1
    800036f4:	c09c                	sw	a5,0(s1)
  return b;
    800036f6:	b7c5                	j	800036d6 <bread+0xd0>

00000000800036f8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036f8:	1101                	addi	sp,sp,-32
    800036fa:	ec06                	sd	ra,24(sp)
    800036fc:	e822                	sd	s0,16(sp)
    800036fe:	e426                	sd	s1,8(sp)
    80003700:	1000                	addi	s0,sp,32
    80003702:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003704:	0541                	addi	a0,a0,16
    80003706:	00001097          	auipc	ra,0x1
    8000370a:	46e080e7          	jalr	1134(ra) # 80004b74 <holdingsleep>
    8000370e:	cd01                	beqz	a0,80003726 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003710:	4585                	li	a1,1
    80003712:	8526                	mv	a0,s1
    80003714:	00003097          	auipc	ra,0x3
    80003718:	070080e7          	jalr	112(ra) # 80006784 <virtio_disk_rw>
}
    8000371c:	60e2                	ld	ra,24(sp)
    8000371e:	6442                	ld	s0,16(sp)
    80003720:	64a2                	ld	s1,8(sp)
    80003722:	6105                	addi	sp,sp,32
    80003724:	8082                	ret
    panic("bwrite");
    80003726:	00005517          	auipc	a0,0x5
    8000372a:	e5250513          	addi	a0,a0,-430 # 80008578 <syscalls+0xf8>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	e10080e7          	jalr	-496(ra) # 8000053e <panic>

0000000080003736 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003736:	1101                	addi	sp,sp,-32
    80003738:	ec06                	sd	ra,24(sp)
    8000373a:	e822                	sd	s0,16(sp)
    8000373c:	e426                	sd	s1,8(sp)
    8000373e:	e04a                	sd	s2,0(sp)
    80003740:	1000                	addi	s0,sp,32
    80003742:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003744:	01050913          	addi	s2,a0,16
    80003748:	854a                	mv	a0,s2
    8000374a:	00001097          	auipc	ra,0x1
    8000374e:	42a080e7          	jalr	1066(ra) # 80004b74 <holdingsleep>
    80003752:	c92d                	beqz	a0,800037c4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003754:	854a                	mv	a0,s2
    80003756:	00001097          	auipc	ra,0x1
    8000375a:	3da080e7          	jalr	986(ra) # 80004b30 <releasesleep>

  acquire(&bcache.lock);
    8000375e:	00015517          	auipc	a0,0x15
    80003762:	86a50513          	addi	a0,a0,-1942 # 80017fc8 <bcache>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	470080e7          	jalr	1136(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000376e:	40bc                	lw	a5,64(s1)
    80003770:	37fd                	addiw	a5,a5,-1
    80003772:	0007871b          	sext.w	a4,a5
    80003776:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003778:	eb05                	bnez	a4,800037a8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000377a:	68bc                	ld	a5,80(s1)
    8000377c:	64b8                	ld	a4,72(s1)
    8000377e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003780:	64bc                	ld	a5,72(s1)
    80003782:	68b8                	ld	a4,80(s1)
    80003784:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003786:	0001d797          	auipc	a5,0x1d
    8000378a:	84278793          	addi	a5,a5,-1982 # 8001ffc8 <bcache+0x8000>
    8000378e:	2b87b703          	ld	a4,696(a5)
    80003792:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003794:	0001d717          	auipc	a4,0x1d
    80003798:	a9c70713          	addi	a4,a4,-1380 # 80020230 <bcache+0x8268>
    8000379c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000379e:	2b87b703          	ld	a4,696(a5)
    800037a2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037a4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037a8:	00015517          	auipc	a0,0x15
    800037ac:	82050513          	addi	a0,a0,-2016 # 80017fc8 <bcache>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	4da080e7          	jalr	1242(ra) # 80000c8a <release>
}
    800037b8:	60e2                	ld	ra,24(sp)
    800037ba:	6442                	ld	s0,16(sp)
    800037bc:	64a2                	ld	s1,8(sp)
    800037be:	6902                	ld	s2,0(sp)
    800037c0:	6105                	addi	sp,sp,32
    800037c2:	8082                	ret
    panic("brelse");
    800037c4:	00005517          	auipc	a0,0x5
    800037c8:	dbc50513          	addi	a0,a0,-580 # 80008580 <syscalls+0x100>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	d72080e7          	jalr	-654(ra) # 8000053e <panic>

00000000800037d4 <bpin>:

void
bpin(struct buf *b) {
    800037d4:	1101                	addi	sp,sp,-32
    800037d6:	ec06                	sd	ra,24(sp)
    800037d8:	e822                	sd	s0,16(sp)
    800037da:	e426                	sd	s1,8(sp)
    800037dc:	1000                	addi	s0,sp,32
    800037de:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037e0:	00014517          	auipc	a0,0x14
    800037e4:	7e850513          	addi	a0,a0,2024 # 80017fc8 <bcache>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	3ee080e7          	jalr	1006(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800037f0:	40bc                	lw	a5,64(s1)
    800037f2:	2785                	addiw	a5,a5,1
    800037f4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037f6:	00014517          	auipc	a0,0x14
    800037fa:	7d250513          	addi	a0,a0,2002 # 80017fc8 <bcache>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	48c080e7          	jalr	1164(ra) # 80000c8a <release>
}
    80003806:	60e2                	ld	ra,24(sp)
    80003808:	6442                	ld	s0,16(sp)
    8000380a:	64a2                	ld	s1,8(sp)
    8000380c:	6105                	addi	sp,sp,32
    8000380e:	8082                	ret

0000000080003810 <bunpin>:

void
bunpin(struct buf *b) {
    80003810:	1101                	addi	sp,sp,-32
    80003812:	ec06                	sd	ra,24(sp)
    80003814:	e822                	sd	s0,16(sp)
    80003816:	e426                	sd	s1,8(sp)
    80003818:	1000                	addi	s0,sp,32
    8000381a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000381c:	00014517          	auipc	a0,0x14
    80003820:	7ac50513          	addi	a0,a0,1964 # 80017fc8 <bcache>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	3b2080e7          	jalr	946(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000382c:	40bc                	lw	a5,64(s1)
    8000382e:	37fd                	addiw	a5,a5,-1
    80003830:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003832:	00014517          	auipc	a0,0x14
    80003836:	79650513          	addi	a0,a0,1942 # 80017fc8 <bcache>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	450080e7          	jalr	1104(ra) # 80000c8a <release>
}
    80003842:	60e2                	ld	ra,24(sp)
    80003844:	6442                	ld	s0,16(sp)
    80003846:	64a2                	ld	s1,8(sp)
    80003848:	6105                	addi	sp,sp,32
    8000384a:	8082                	ret

000000008000384c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000384c:	1101                	addi	sp,sp,-32
    8000384e:	ec06                	sd	ra,24(sp)
    80003850:	e822                	sd	s0,16(sp)
    80003852:	e426                	sd	s1,8(sp)
    80003854:	e04a                	sd	s2,0(sp)
    80003856:	1000                	addi	s0,sp,32
    80003858:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000385a:	00d5d59b          	srliw	a1,a1,0xd
    8000385e:	0001d797          	auipc	a5,0x1d
    80003862:	e467a783          	lw	a5,-442(a5) # 800206a4 <sb+0x1c>
    80003866:	9dbd                	addw	a1,a1,a5
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	d9e080e7          	jalr	-610(ra) # 80003606 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003870:	0074f713          	andi	a4,s1,7
    80003874:	4785                	li	a5,1
    80003876:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000387a:	14ce                	slli	s1,s1,0x33
    8000387c:	90d9                	srli	s1,s1,0x36
    8000387e:	00950733          	add	a4,a0,s1
    80003882:	05874703          	lbu	a4,88(a4)
    80003886:	00e7f6b3          	and	a3,a5,a4
    8000388a:	c69d                	beqz	a3,800038b8 <bfree+0x6c>
    8000388c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000388e:	94aa                	add	s1,s1,a0
    80003890:	fff7c793          	not	a5,a5
    80003894:	8ff9                	and	a5,a5,a4
    80003896:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000389a:	00001097          	auipc	ra,0x1
    8000389e:	120080e7          	jalr	288(ra) # 800049ba <log_write>
  brelse(bp);
    800038a2:	854a                	mv	a0,s2
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	e92080e7          	jalr	-366(ra) # 80003736 <brelse>
}
    800038ac:	60e2                	ld	ra,24(sp)
    800038ae:	6442                	ld	s0,16(sp)
    800038b0:	64a2                	ld	s1,8(sp)
    800038b2:	6902                	ld	s2,0(sp)
    800038b4:	6105                	addi	sp,sp,32
    800038b6:	8082                	ret
    panic("freeing free block");
    800038b8:	00005517          	auipc	a0,0x5
    800038bc:	cd050513          	addi	a0,a0,-816 # 80008588 <syscalls+0x108>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	c7e080e7          	jalr	-898(ra) # 8000053e <panic>

00000000800038c8 <balloc>:
{
    800038c8:	711d                	addi	sp,sp,-96
    800038ca:	ec86                	sd	ra,88(sp)
    800038cc:	e8a2                	sd	s0,80(sp)
    800038ce:	e4a6                	sd	s1,72(sp)
    800038d0:	e0ca                	sd	s2,64(sp)
    800038d2:	fc4e                	sd	s3,56(sp)
    800038d4:	f852                	sd	s4,48(sp)
    800038d6:	f456                	sd	s5,40(sp)
    800038d8:	f05a                	sd	s6,32(sp)
    800038da:	ec5e                	sd	s7,24(sp)
    800038dc:	e862                	sd	s8,16(sp)
    800038de:	e466                	sd	s9,8(sp)
    800038e0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038e2:	0001d797          	auipc	a5,0x1d
    800038e6:	daa7a783          	lw	a5,-598(a5) # 8002068c <sb+0x4>
    800038ea:	10078163          	beqz	a5,800039ec <balloc+0x124>
    800038ee:	8baa                	mv	s7,a0
    800038f0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038f2:	0001db17          	auipc	s6,0x1d
    800038f6:	d96b0b13          	addi	s6,s6,-618 # 80020688 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038fa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038fc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038fe:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003900:	6c89                	lui	s9,0x2
    80003902:	a061                	j	8000398a <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003904:	974a                	add	a4,a4,s2
    80003906:	8fd5                	or	a5,a5,a3
    80003908:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000390c:	854a                	mv	a0,s2
    8000390e:	00001097          	auipc	ra,0x1
    80003912:	0ac080e7          	jalr	172(ra) # 800049ba <log_write>
        brelse(bp);
    80003916:	854a                	mv	a0,s2
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	e1e080e7          	jalr	-482(ra) # 80003736 <brelse>
  bp = bread(dev, bno);
    80003920:	85a6                	mv	a1,s1
    80003922:	855e                	mv	a0,s7
    80003924:	00000097          	auipc	ra,0x0
    80003928:	ce2080e7          	jalr	-798(ra) # 80003606 <bread>
    8000392c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000392e:	40000613          	li	a2,1024
    80003932:	4581                	li	a1,0
    80003934:	05850513          	addi	a0,a0,88
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	39a080e7          	jalr	922(ra) # 80000cd2 <memset>
  log_write(bp);
    80003940:	854a                	mv	a0,s2
    80003942:	00001097          	auipc	ra,0x1
    80003946:	078080e7          	jalr	120(ra) # 800049ba <log_write>
  brelse(bp);
    8000394a:	854a                	mv	a0,s2
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	dea080e7          	jalr	-534(ra) # 80003736 <brelse>
}
    80003954:	8526                	mv	a0,s1
    80003956:	60e6                	ld	ra,88(sp)
    80003958:	6446                	ld	s0,80(sp)
    8000395a:	64a6                	ld	s1,72(sp)
    8000395c:	6906                	ld	s2,64(sp)
    8000395e:	79e2                	ld	s3,56(sp)
    80003960:	7a42                	ld	s4,48(sp)
    80003962:	7aa2                	ld	s5,40(sp)
    80003964:	7b02                	ld	s6,32(sp)
    80003966:	6be2                	ld	s7,24(sp)
    80003968:	6c42                	ld	s8,16(sp)
    8000396a:	6ca2                	ld	s9,8(sp)
    8000396c:	6125                	addi	sp,sp,96
    8000396e:	8082                	ret
    brelse(bp);
    80003970:	854a                	mv	a0,s2
    80003972:	00000097          	auipc	ra,0x0
    80003976:	dc4080e7          	jalr	-572(ra) # 80003736 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000397a:	015c87bb          	addw	a5,s9,s5
    8000397e:	00078a9b          	sext.w	s5,a5
    80003982:	004b2703          	lw	a4,4(s6)
    80003986:	06eaf363          	bgeu	s5,a4,800039ec <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000398a:	41fad79b          	sraiw	a5,s5,0x1f
    8000398e:	0137d79b          	srliw	a5,a5,0x13
    80003992:	015787bb          	addw	a5,a5,s5
    80003996:	40d7d79b          	sraiw	a5,a5,0xd
    8000399a:	01cb2583          	lw	a1,28(s6)
    8000399e:	9dbd                	addw	a1,a1,a5
    800039a0:	855e                	mv	a0,s7
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	c64080e7          	jalr	-924(ra) # 80003606 <bread>
    800039aa:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ac:	004b2503          	lw	a0,4(s6)
    800039b0:	000a849b          	sext.w	s1,s5
    800039b4:	8662                	mv	a2,s8
    800039b6:	faa4fde3          	bgeu	s1,a0,80003970 <balloc+0xa8>
      m = 1 << (bi % 8);
    800039ba:	41f6579b          	sraiw	a5,a2,0x1f
    800039be:	01d7d69b          	srliw	a3,a5,0x1d
    800039c2:	00c6873b          	addw	a4,a3,a2
    800039c6:	00777793          	andi	a5,a4,7
    800039ca:	9f95                	subw	a5,a5,a3
    800039cc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800039d0:	4037571b          	sraiw	a4,a4,0x3
    800039d4:	00e906b3          	add	a3,s2,a4
    800039d8:	0586c683          	lbu	a3,88(a3)
    800039dc:	00d7f5b3          	and	a1,a5,a3
    800039e0:	d195                	beqz	a1,80003904 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039e2:	2605                	addiw	a2,a2,1
    800039e4:	2485                	addiw	s1,s1,1
    800039e6:	fd4618e3          	bne	a2,s4,800039b6 <balloc+0xee>
    800039ea:	b759                	j	80003970 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800039ec:	00005517          	auipc	a0,0x5
    800039f0:	bb450513          	addi	a0,a0,-1100 # 800085a0 <syscalls+0x120>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	b94080e7          	jalr	-1132(ra) # 80000588 <printf>
  return 0;
    800039fc:	4481                	li	s1,0
    800039fe:	bf99                	j	80003954 <balloc+0x8c>

0000000080003a00 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a00:	7179                	addi	sp,sp,-48
    80003a02:	f406                	sd	ra,40(sp)
    80003a04:	f022                	sd	s0,32(sp)
    80003a06:	ec26                	sd	s1,24(sp)
    80003a08:	e84a                	sd	s2,16(sp)
    80003a0a:	e44e                	sd	s3,8(sp)
    80003a0c:	e052                	sd	s4,0(sp)
    80003a0e:	1800                	addi	s0,sp,48
    80003a10:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a12:	47ad                	li	a5,11
    80003a14:	02b7e763          	bltu	a5,a1,80003a42 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003a18:	02059493          	slli	s1,a1,0x20
    80003a1c:	9081                	srli	s1,s1,0x20
    80003a1e:	048a                	slli	s1,s1,0x2
    80003a20:	94aa                	add	s1,s1,a0
    80003a22:	0504a903          	lw	s2,80(s1)
    80003a26:	06091e63          	bnez	s2,80003aa2 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003a2a:	4108                	lw	a0,0(a0)
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	e9c080e7          	jalr	-356(ra) # 800038c8 <balloc>
    80003a34:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a38:	06090563          	beqz	s2,80003aa2 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003a3c:	0524a823          	sw	s2,80(s1)
    80003a40:	a08d                	j	80003aa2 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003a42:	ff45849b          	addiw	s1,a1,-12
    80003a46:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a4a:	0ff00793          	li	a5,255
    80003a4e:	08e7e563          	bltu	a5,a4,80003ad8 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003a52:	08052903          	lw	s2,128(a0)
    80003a56:	00091d63          	bnez	s2,80003a70 <bmap+0x70>
      addr = balloc(ip->dev);
    80003a5a:	4108                	lw	a0,0(a0)
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	e6c080e7          	jalr	-404(ra) # 800038c8 <balloc>
    80003a64:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a68:	02090d63          	beqz	s2,80003aa2 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a6c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a70:	85ca                	mv	a1,s2
    80003a72:	0009a503          	lw	a0,0(s3)
    80003a76:	00000097          	auipc	ra,0x0
    80003a7a:	b90080e7          	jalr	-1136(ra) # 80003606 <bread>
    80003a7e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a80:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a84:	02049593          	slli	a1,s1,0x20
    80003a88:	9181                	srli	a1,a1,0x20
    80003a8a:	058a                	slli	a1,a1,0x2
    80003a8c:	00b784b3          	add	s1,a5,a1
    80003a90:	0004a903          	lw	s2,0(s1)
    80003a94:	02090063          	beqz	s2,80003ab4 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003a98:	8552                	mv	a0,s4
    80003a9a:	00000097          	auipc	ra,0x0
    80003a9e:	c9c080e7          	jalr	-868(ra) # 80003736 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003aa2:	854a                	mv	a0,s2
    80003aa4:	70a2                	ld	ra,40(sp)
    80003aa6:	7402                	ld	s0,32(sp)
    80003aa8:	64e2                	ld	s1,24(sp)
    80003aaa:	6942                	ld	s2,16(sp)
    80003aac:	69a2                	ld	s3,8(sp)
    80003aae:	6a02                	ld	s4,0(sp)
    80003ab0:	6145                	addi	sp,sp,48
    80003ab2:	8082                	ret
      addr = balloc(ip->dev);
    80003ab4:	0009a503          	lw	a0,0(s3)
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	e10080e7          	jalr	-496(ra) # 800038c8 <balloc>
    80003ac0:	0005091b          	sext.w	s2,a0
      if(addr){
    80003ac4:	fc090ae3          	beqz	s2,80003a98 <bmap+0x98>
        a[bn] = addr;
    80003ac8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003acc:	8552                	mv	a0,s4
    80003ace:	00001097          	auipc	ra,0x1
    80003ad2:	eec080e7          	jalr	-276(ra) # 800049ba <log_write>
    80003ad6:	b7c9                	j	80003a98 <bmap+0x98>
  panic("bmap: out of range");
    80003ad8:	00005517          	auipc	a0,0x5
    80003adc:	ae050513          	addi	a0,a0,-1312 # 800085b8 <syscalls+0x138>
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	a5e080e7          	jalr	-1442(ra) # 8000053e <panic>

0000000080003ae8 <iget>:
{
    80003ae8:	7179                	addi	sp,sp,-48
    80003aea:	f406                	sd	ra,40(sp)
    80003aec:	f022                	sd	s0,32(sp)
    80003aee:	ec26                	sd	s1,24(sp)
    80003af0:	e84a                	sd	s2,16(sp)
    80003af2:	e44e                	sd	s3,8(sp)
    80003af4:	e052                	sd	s4,0(sp)
    80003af6:	1800                	addi	s0,sp,48
    80003af8:	89aa                	mv	s3,a0
    80003afa:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003afc:	0001d517          	auipc	a0,0x1d
    80003b00:	bac50513          	addi	a0,a0,-1108 # 800206a8 <itable>
    80003b04:	ffffd097          	auipc	ra,0xffffd
    80003b08:	0d2080e7          	jalr	210(ra) # 80000bd6 <acquire>
  empty = 0;
    80003b0c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b0e:	0001d497          	auipc	s1,0x1d
    80003b12:	bb248493          	addi	s1,s1,-1102 # 800206c0 <itable+0x18>
    80003b16:	0001e697          	auipc	a3,0x1e
    80003b1a:	63a68693          	addi	a3,a3,1594 # 80022150 <log>
    80003b1e:	a039                	j	80003b2c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b20:	02090b63          	beqz	s2,80003b56 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b24:	08848493          	addi	s1,s1,136
    80003b28:	02d48a63          	beq	s1,a3,80003b5c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b2c:	449c                	lw	a5,8(s1)
    80003b2e:	fef059e3          	blez	a5,80003b20 <iget+0x38>
    80003b32:	4098                	lw	a4,0(s1)
    80003b34:	ff3716e3          	bne	a4,s3,80003b20 <iget+0x38>
    80003b38:	40d8                	lw	a4,4(s1)
    80003b3a:	ff4713e3          	bne	a4,s4,80003b20 <iget+0x38>
      ip->ref++;
    80003b3e:	2785                	addiw	a5,a5,1
    80003b40:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b42:	0001d517          	auipc	a0,0x1d
    80003b46:	b6650513          	addi	a0,a0,-1178 # 800206a8 <itable>
    80003b4a:	ffffd097          	auipc	ra,0xffffd
    80003b4e:	140080e7          	jalr	320(ra) # 80000c8a <release>
      return ip;
    80003b52:	8926                	mv	s2,s1
    80003b54:	a03d                	j	80003b82 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b56:	f7f9                	bnez	a5,80003b24 <iget+0x3c>
    80003b58:	8926                	mv	s2,s1
    80003b5a:	b7e9                	j	80003b24 <iget+0x3c>
  if(empty == 0)
    80003b5c:	02090c63          	beqz	s2,80003b94 <iget+0xac>
  ip->dev = dev;
    80003b60:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b64:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b68:	4785                	li	a5,1
    80003b6a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b6e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b72:	0001d517          	auipc	a0,0x1d
    80003b76:	b3650513          	addi	a0,a0,-1226 # 800206a8 <itable>
    80003b7a:	ffffd097          	auipc	ra,0xffffd
    80003b7e:	110080e7          	jalr	272(ra) # 80000c8a <release>
}
    80003b82:	854a                	mv	a0,s2
    80003b84:	70a2                	ld	ra,40(sp)
    80003b86:	7402                	ld	s0,32(sp)
    80003b88:	64e2                	ld	s1,24(sp)
    80003b8a:	6942                	ld	s2,16(sp)
    80003b8c:	69a2                	ld	s3,8(sp)
    80003b8e:	6a02                	ld	s4,0(sp)
    80003b90:	6145                	addi	sp,sp,48
    80003b92:	8082                	ret
    panic("iget: no inodes");
    80003b94:	00005517          	auipc	a0,0x5
    80003b98:	a3c50513          	addi	a0,a0,-1476 # 800085d0 <syscalls+0x150>
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	9a2080e7          	jalr	-1630(ra) # 8000053e <panic>

0000000080003ba4 <fsinit>:
fsinit(int dev) {
    80003ba4:	7179                	addi	sp,sp,-48
    80003ba6:	f406                	sd	ra,40(sp)
    80003ba8:	f022                	sd	s0,32(sp)
    80003baa:	ec26                	sd	s1,24(sp)
    80003bac:	e84a                	sd	s2,16(sp)
    80003bae:	e44e                	sd	s3,8(sp)
    80003bb0:	1800                	addi	s0,sp,48
    80003bb2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003bb4:	4585                	li	a1,1
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	a50080e7          	jalr	-1456(ra) # 80003606 <bread>
    80003bbe:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bc0:	0001d997          	auipc	s3,0x1d
    80003bc4:	ac898993          	addi	s3,s3,-1336 # 80020688 <sb>
    80003bc8:	02000613          	li	a2,32
    80003bcc:	05850593          	addi	a1,a0,88
    80003bd0:	854e                	mv	a0,s3
    80003bd2:	ffffd097          	auipc	ra,0xffffd
    80003bd6:	15c080e7          	jalr	348(ra) # 80000d2e <memmove>
  brelse(bp);
    80003bda:	8526                	mv	a0,s1
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	b5a080e7          	jalr	-1190(ra) # 80003736 <brelse>
  if(sb.magic != FSMAGIC)
    80003be4:	0009a703          	lw	a4,0(s3)
    80003be8:	102037b7          	lui	a5,0x10203
    80003bec:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bf0:	02f71263          	bne	a4,a5,80003c14 <fsinit+0x70>
  initlog(dev, &sb);
    80003bf4:	0001d597          	auipc	a1,0x1d
    80003bf8:	a9458593          	addi	a1,a1,-1388 # 80020688 <sb>
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	00001097          	auipc	ra,0x1
    80003c02:	b40080e7          	jalr	-1216(ra) # 8000473e <initlog>
}
    80003c06:	70a2                	ld	ra,40(sp)
    80003c08:	7402                	ld	s0,32(sp)
    80003c0a:	64e2                	ld	s1,24(sp)
    80003c0c:	6942                	ld	s2,16(sp)
    80003c0e:	69a2                	ld	s3,8(sp)
    80003c10:	6145                	addi	sp,sp,48
    80003c12:	8082                	ret
    panic("invalid file system");
    80003c14:	00005517          	auipc	a0,0x5
    80003c18:	9cc50513          	addi	a0,a0,-1588 # 800085e0 <syscalls+0x160>
    80003c1c:	ffffd097          	auipc	ra,0xffffd
    80003c20:	922080e7          	jalr	-1758(ra) # 8000053e <panic>

0000000080003c24 <iinit>:
{
    80003c24:	7179                	addi	sp,sp,-48
    80003c26:	f406                	sd	ra,40(sp)
    80003c28:	f022                	sd	s0,32(sp)
    80003c2a:	ec26                	sd	s1,24(sp)
    80003c2c:	e84a                	sd	s2,16(sp)
    80003c2e:	e44e                	sd	s3,8(sp)
    80003c30:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c32:	00005597          	auipc	a1,0x5
    80003c36:	9c658593          	addi	a1,a1,-1594 # 800085f8 <syscalls+0x178>
    80003c3a:	0001d517          	auipc	a0,0x1d
    80003c3e:	a6e50513          	addi	a0,a0,-1426 # 800206a8 <itable>
    80003c42:	ffffd097          	auipc	ra,0xffffd
    80003c46:	f04080e7          	jalr	-252(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c4a:	0001d497          	auipc	s1,0x1d
    80003c4e:	a8648493          	addi	s1,s1,-1402 # 800206d0 <itable+0x28>
    80003c52:	0001e997          	auipc	s3,0x1e
    80003c56:	50e98993          	addi	s3,s3,1294 # 80022160 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c5a:	00005917          	auipc	s2,0x5
    80003c5e:	9a690913          	addi	s2,s2,-1626 # 80008600 <syscalls+0x180>
    80003c62:	85ca                	mv	a1,s2
    80003c64:	8526                	mv	a0,s1
    80003c66:	00001097          	auipc	ra,0x1
    80003c6a:	e3a080e7          	jalr	-454(ra) # 80004aa0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c6e:	08848493          	addi	s1,s1,136
    80003c72:	ff3498e3          	bne	s1,s3,80003c62 <iinit+0x3e>
}
    80003c76:	70a2                	ld	ra,40(sp)
    80003c78:	7402                	ld	s0,32(sp)
    80003c7a:	64e2                	ld	s1,24(sp)
    80003c7c:	6942                	ld	s2,16(sp)
    80003c7e:	69a2                	ld	s3,8(sp)
    80003c80:	6145                	addi	sp,sp,48
    80003c82:	8082                	ret

0000000080003c84 <ialloc>:
{
    80003c84:	715d                	addi	sp,sp,-80
    80003c86:	e486                	sd	ra,72(sp)
    80003c88:	e0a2                	sd	s0,64(sp)
    80003c8a:	fc26                	sd	s1,56(sp)
    80003c8c:	f84a                	sd	s2,48(sp)
    80003c8e:	f44e                	sd	s3,40(sp)
    80003c90:	f052                	sd	s4,32(sp)
    80003c92:	ec56                	sd	s5,24(sp)
    80003c94:	e85a                	sd	s6,16(sp)
    80003c96:	e45e                	sd	s7,8(sp)
    80003c98:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c9a:	0001d717          	auipc	a4,0x1d
    80003c9e:	9fa72703          	lw	a4,-1542(a4) # 80020694 <sb+0xc>
    80003ca2:	4785                	li	a5,1
    80003ca4:	04e7fa63          	bgeu	a5,a4,80003cf8 <ialloc+0x74>
    80003ca8:	8aaa                	mv	s5,a0
    80003caa:	8bae                	mv	s7,a1
    80003cac:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003cae:	0001da17          	auipc	s4,0x1d
    80003cb2:	9daa0a13          	addi	s4,s4,-1574 # 80020688 <sb>
    80003cb6:	00048b1b          	sext.w	s6,s1
    80003cba:	0044d793          	srli	a5,s1,0x4
    80003cbe:	018a2583          	lw	a1,24(s4)
    80003cc2:	9dbd                	addw	a1,a1,a5
    80003cc4:	8556                	mv	a0,s5
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	940080e7          	jalr	-1728(ra) # 80003606 <bread>
    80003cce:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003cd0:	05850993          	addi	s3,a0,88
    80003cd4:	00f4f793          	andi	a5,s1,15
    80003cd8:	079a                	slli	a5,a5,0x6
    80003cda:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003cdc:	00099783          	lh	a5,0(s3)
    80003ce0:	c3a1                	beqz	a5,80003d20 <ialloc+0x9c>
    brelse(bp);
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	a54080e7          	jalr	-1452(ra) # 80003736 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cea:	0485                	addi	s1,s1,1
    80003cec:	00ca2703          	lw	a4,12(s4)
    80003cf0:	0004879b          	sext.w	a5,s1
    80003cf4:	fce7e1e3          	bltu	a5,a4,80003cb6 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003cf8:	00005517          	auipc	a0,0x5
    80003cfc:	91050513          	addi	a0,a0,-1776 # 80008608 <syscalls+0x188>
    80003d00:	ffffd097          	auipc	ra,0xffffd
    80003d04:	888080e7          	jalr	-1912(ra) # 80000588 <printf>
  return 0;
    80003d08:	4501                	li	a0,0
}
    80003d0a:	60a6                	ld	ra,72(sp)
    80003d0c:	6406                	ld	s0,64(sp)
    80003d0e:	74e2                	ld	s1,56(sp)
    80003d10:	7942                	ld	s2,48(sp)
    80003d12:	79a2                	ld	s3,40(sp)
    80003d14:	7a02                	ld	s4,32(sp)
    80003d16:	6ae2                	ld	s5,24(sp)
    80003d18:	6b42                	ld	s6,16(sp)
    80003d1a:	6ba2                	ld	s7,8(sp)
    80003d1c:	6161                	addi	sp,sp,80
    80003d1e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003d20:	04000613          	li	a2,64
    80003d24:	4581                	li	a1,0
    80003d26:	854e                	mv	a0,s3
    80003d28:	ffffd097          	auipc	ra,0xffffd
    80003d2c:	faa080e7          	jalr	-86(ra) # 80000cd2 <memset>
      dip->type = type;
    80003d30:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d34:	854a                	mv	a0,s2
    80003d36:	00001097          	auipc	ra,0x1
    80003d3a:	c84080e7          	jalr	-892(ra) # 800049ba <log_write>
      brelse(bp);
    80003d3e:	854a                	mv	a0,s2
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	9f6080e7          	jalr	-1546(ra) # 80003736 <brelse>
      return iget(dev, inum);
    80003d48:	85da                	mv	a1,s6
    80003d4a:	8556                	mv	a0,s5
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	d9c080e7          	jalr	-612(ra) # 80003ae8 <iget>
    80003d54:	bf5d                	j	80003d0a <ialloc+0x86>

0000000080003d56 <iupdate>:
{
    80003d56:	1101                	addi	sp,sp,-32
    80003d58:	ec06                	sd	ra,24(sp)
    80003d5a:	e822                	sd	s0,16(sp)
    80003d5c:	e426                	sd	s1,8(sp)
    80003d5e:	e04a                	sd	s2,0(sp)
    80003d60:	1000                	addi	s0,sp,32
    80003d62:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d64:	415c                	lw	a5,4(a0)
    80003d66:	0047d79b          	srliw	a5,a5,0x4
    80003d6a:	0001d597          	auipc	a1,0x1d
    80003d6e:	9365a583          	lw	a1,-1738(a1) # 800206a0 <sb+0x18>
    80003d72:	9dbd                	addw	a1,a1,a5
    80003d74:	4108                	lw	a0,0(a0)
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	890080e7          	jalr	-1904(ra) # 80003606 <bread>
    80003d7e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d80:	05850793          	addi	a5,a0,88
    80003d84:	40c8                	lw	a0,4(s1)
    80003d86:	893d                	andi	a0,a0,15
    80003d88:	051a                	slli	a0,a0,0x6
    80003d8a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d8c:	04449703          	lh	a4,68(s1)
    80003d90:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d94:	04649703          	lh	a4,70(s1)
    80003d98:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d9c:	04849703          	lh	a4,72(s1)
    80003da0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003da4:	04a49703          	lh	a4,74(s1)
    80003da8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003dac:	44f8                	lw	a4,76(s1)
    80003dae:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003db0:	03400613          	li	a2,52
    80003db4:	05048593          	addi	a1,s1,80
    80003db8:	0531                	addi	a0,a0,12
    80003dba:	ffffd097          	auipc	ra,0xffffd
    80003dbe:	f74080e7          	jalr	-140(ra) # 80000d2e <memmove>
  log_write(bp);
    80003dc2:	854a                	mv	a0,s2
    80003dc4:	00001097          	auipc	ra,0x1
    80003dc8:	bf6080e7          	jalr	-1034(ra) # 800049ba <log_write>
  brelse(bp);
    80003dcc:	854a                	mv	a0,s2
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	968080e7          	jalr	-1688(ra) # 80003736 <brelse>
}
    80003dd6:	60e2                	ld	ra,24(sp)
    80003dd8:	6442                	ld	s0,16(sp)
    80003dda:	64a2                	ld	s1,8(sp)
    80003ddc:	6902                	ld	s2,0(sp)
    80003dde:	6105                	addi	sp,sp,32
    80003de0:	8082                	ret

0000000080003de2 <idup>:
{
    80003de2:	1101                	addi	sp,sp,-32
    80003de4:	ec06                	sd	ra,24(sp)
    80003de6:	e822                	sd	s0,16(sp)
    80003de8:	e426                	sd	s1,8(sp)
    80003dea:	1000                	addi	s0,sp,32
    80003dec:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dee:	0001d517          	auipc	a0,0x1d
    80003df2:	8ba50513          	addi	a0,a0,-1862 # 800206a8 <itable>
    80003df6:	ffffd097          	auipc	ra,0xffffd
    80003dfa:	de0080e7          	jalr	-544(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003dfe:	449c                	lw	a5,8(s1)
    80003e00:	2785                	addiw	a5,a5,1
    80003e02:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e04:	0001d517          	auipc	a0,0x1d
    80003e08:	8a450513          	addi	a0,a0,-1884 # 800206a8 <itable>
    80003e0c:	ffffd097          	auipc	ra,0xffffd
    80003e10:	e7e080e7          	jalr	-386(ra) # 80000c8a <release>
}
    80003e14:	8526                	mv	a0,s1
    80003e16:	60e2                	ld	ra,24(sp)
    80003e18:	6442                	ld	s0,16(sp)
    80003e1a:	64a2                	ld	s1,8(sp)
    80003e1c:	6105                	addi	sp,sp,32
    80003e1e:	8082                	ret

0000000080003e20 <ilock>:
{
    80003e20:	1101                	addi	sp,sp,-32
    80003e22:	ec06                	sd	ra,24(sp)
    80003e24:	e822                	sd	s0,16(sp)
    80003e26:	e426                	sd	s1,8(sp)
    80003e28:	e04a                	sd	s2,0(sp)
    80003e2a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e2c:	c115                	beqz	a0,80003e50 <ilock+0x30>
    80003e2e:	84aa                	mv	s1,a0
    80003e30:	451c                	lw	a5,8(a0)
    80003e32:	00f05f63          	blez	a5,80003e50 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e36:	0541                	addi	a0,a0,16
    80003e38:	00001097          	auipc	ra,0x1
    80003e3c:	ca2080e7          	jalr	-862(ra) # 80004ada <acquiresleep>
  if(ip->valid == 0){
    80003e40:	40bc                	lw	a5,64(s1)
    80003e42:	cf99                	beqz	a5,80003e60 <ilock+0x40>
}
    80003e44:	60e2                	ld	ra,24(sp)
    80003e46:	6442                	ld	s0,16(sp)
    80003e48:	64a2                	ld	s1,8(sp)
    80003e4a:	6902                	ld	s2,0(sp)
    80003e4c:	6105                	addi	sp,sp,32
    80003e4e:	8082                	ret
    panic("ilock");
    80003e50:	00004517          	auipc	a0,0x4
    80003e54:	7d050513          	addi	a0,a0,2000 # 80008620 <syscalls+0x1a0>
    80003e58:	ffffc097          	auipc	ra,0xffffc
    80003e5c:	6e6080e7          	jalr	1766(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e60:	40dc                	lw	a5,4(s1)
    80003e62:	0047d79b          	srliw	a5,a5,0x4
    80003e66:	0001d597          	auipc	a1,0x1d
    80003e6a:	83a5a583          	lw	a1,-1990(a1) # 800206a0 <sb+0x18>
    80003e6e:	9dbd                	addw	a1,a1,a5
    80003e70:	4088                	lw	a0,0(s1)
    80003e72:	fffff097          	auipc	ra,0xfffff
    80003e76:	794080e7          	jalr	1940(ra) # 80003606 <bread>
    80003e7a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e7c:	05850593          	addi	a1,a0,88
    80003e80:	40dc                	lw	a5,4(s1)
    80003e82:	8bbd                	andi	a5,a5,15
    80003e84:	079a                	slli	a5,a5,0x6
    80003e86:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e88:	00059783          	lh	a5,0(a1)
    80003e8c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e90:	00259783          	lh	a5,2(a1)
    80003e94:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e98:	00459783          	lh	a5,4(a1)
    80003e9c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ea0:	00659783          	lh	a5,6(a1)
    80003ea4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ea8:	459c                	lw	a5,8(a1)
    80003eaa:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003eac:	03400613          	li	a2,52
    80003eb0:	05b1                	addi	a1,a1,12
    80003eb2:	05048513          	addi	a0,s1,80
    80003eb6:	ffffd097          	auipc	ra,0xffffd
    80003eba:	e78080e7          	jalr	-392(ra) # 80000d2e <memmove>
    brelse(bp);
    80003ebe:	854a                	mv	a0,s2
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	876080e7          	jalr	-1930(ra) # 80003736 <brelse>
    ip->valid = 1;
    80003ec8:	4785                	li	a5,1
    80003eca:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ecc:	04449783          	lh	a5,68(s1)
    80003ed0:	fbb5                	bnez	a5,80003e44 <ilock+0x24>
      panic("ilock: no type");
    80003ed2:	00004517          	auipc	a0,0x4
    80003ed6:	75650513          	addi	a0,a0,1878 # 80008628 <syscalls+0x1a8>
    80003eda:	ffffc097          	auipc	ra,0xffffc
    80003ede:	664080e7          	jalr	1636(ra) # 8000053e <panic>

0000000080003ee2 <iunlock>:
{
    80003ee2:	1101                	addi	sp,sp,-32
    80003ee4:	ec06                	sd	ra,24(sp)
    80003ee6:	e822                	sd	s0,16(sp)
    80003ee8:	e426                	sd	s1,8(sp)
    80003eea:	e04a                	sd	s2,0(sp)
    80003eec:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003eee:	c905                	beqz	a0,80003f1e <iunlock+0x3c>
    80003ef0:	84aa                	mv	s1,a0
    80003ef2:	01050913          	addi	s2,a0,16
    80003ef6:	854a                	mv	a0,s2
    80003ef8:	00001097          	auipc	ra,0x1
    80003efc:	c7c080e7          	jalr	-900(ra) # 80004b74 <holdingsleep>
    80003f00:	cd19                	beqz	a0,80003f1e <iunlock+0x3c>
    80003f02:	449c                	lw	a5,8(s1)
    80003f04:	00f05d63          	blez	a5,80003f1e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f08:	854a                	mv	a0,s2
    80003f0a:	00001097          	auipc	ra,0x1
    80003f0e:	c26080e7          	jalr	-986(ra) # 80004b30 <releasesleep>
}
    80003f12:	60e2                	ld	ra,24(sp)
    80003f14:	6442                	ld	s0,16(sp)
    80003f16:	64a2                	ld	s1,8(sp)
    80003f18:	6902                	ld	s2,0(sp)
    80003f1a:	6105                	addi	sp,sp,32
    80003f1c:	8082                	ret
    panic("iunlock");
    80003f1e:	00004517          	auipc	a0,0x4
    80003f22:	71a50513          	addi	a0,a0,1818 # 80008638 <syscalls+0x1b8>
    80003f26:	ffffc097          	auipc	ra,0xffffc
    80003f2a:	618080e7          	jalr	1560(ra) # 8000053e <panic>

0000000080003f2e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f2e:	7179                	addi	sp,sp,-48
    80003f30:	f406                	sd	ra,40(sp)
    80003f32:	f022                	sd	s0,32(sp)
    80003f34:	ec26                	sd	s1,24(sp)
    80003f36:	e84a                	sd	s2,16(sp)
    80003f38:	e44e                	sd	s3,8(sp)
    80003f3a:	e052                	sd	s4,0(sp)
    80003f3c:	1800                	addi	s0,sp,48
    80003f3e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f40:	05050493          	addi	s1,a0,80
    80003f44:	08050913          	addi	s2,a0,128
    80003f48:	a021                	j	80003f50 <itrunc+0x22>
    80003f4a:	0491                	addi	s1,s1,4
    80003f4c:	01248d63          	beq	s1,s2,80003f66 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f50:	408c                	lw	a1,0(s1)
    80003f52:	dde5                	beqz	a1,80003f4a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f54:	0009a503          	lw	a0,0(s3)
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	8f4080e7          	jalr	-1804(ra) # 8000384c <bfree>
      ip->addrs[i] = 0;
    80003f60:	0004a023          	sw	zero,0(s1)
    80003f64:	b7dd                	j	80003f4a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f66:	0809a583          	lw	a1,128(s3)
    80003f6a:	e185                	bnez	a1,80003f8a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f6c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f70:	854e                	mv	a0,s3
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	de4080e7          	jalr	-540(ra) # 80003d56 <iupdate>
}
    80003f7a:	70a2                	ld	ra,40(sp)
    80003f7c:	7402                	ld	s0,32(sp)
    80003f7e:	64e2                	ld	s1,24(sp)
    80003f80:	6942                	ld	s2,16(sp)
    80003f82:	69a2                	ld	s3,8(sp)
    80003f84:	6a02                	ld	s4,0(sp)
    80003f86:	6145                	addi	sp,sp,48
    80003f88:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f8a:	0009a503          	lw	a0,0(s3)
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	678080e7          	jalr	1656(ra) # 80003606 <bread>
    80003f96:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f98:	05850493          	addi	s1,a0,88
    80003f9c:	45850913          	addi	s2,a0,1112
    80003fa0:	a021                	j	80003fa8 <itrunc+0x7a>
    80003fa2:	0491                	addi	s1,s1,4
    80003fa4:	01248b63          	beq	s1,s2,80003fba <itrunc+0x8c>
      if(a[j])
    80003fa8:	408c                	lw	a1,0(s1)
    80003faa:	dde5                	beqz	a1,80003fa2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003fac:	0009a503          	lw	a0,0(s3)
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	89c080e7          	jalr	-1892(ra) # 8000384c <bfree>
    80003fb8:	b7ed                	j	80003fa2 <itrunc+0x74>
    brelse(bp);
    80003fba:	8552                	mv	a0,s4
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	77a080e7          	jalr	1914(ra) # 80003736 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fc4:	0809a583          	lw	a1,128(s3)
    80003fc8:	0009a503          	lw	a0,0(s3)
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	880080e7          	jalr	-1920(ra) # 8000384c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003fd4:	0809a023          	sw	zero,128(s3)
    80003fd8:	bf51                	j	80003f6c <itrunc+0x3e>

0000000080003fda <iput>:
{
    80003fda:	1101                	addi	sp,sp,-32
    80003fdc:	ec06                	sd	ra,24(sp)
    80003fde:	e822                	sd	s0,16(sp)
    80003fe0:	e426                	sd	s1,8(sp)
    80003fe2:	e04a                	sd	s2,0(sp)
    80003fe4:	1000                	addi	s0,sp,32
    80003fe6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fe8:	0001c517          	auipc	a0,0x1c
    80003fec:	6c050513          	addi	a0,a0,1728 # 800206a8 <itable>
    80003ff0:	ffffd097          	auipc	ra,0xffffd
    80003ff4:	be6080e7          	jalr	-1050(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ff8:	4498                	lw	a4,8(s1)
    80003ffa:	4785                	li	a5,1
    80003ffc:	02f70363          	beq	a4,a5,80004022 <iput+0x48>
  ip->ref--;
    80004000:	449c                	lw	a5,8(s1)
    80004002:	37fd                	addiw	a5,a5,-1
    80004004:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004006:	0001c517          	auipc	a0,0x1c
    8000400a:	6a250513          	addi	a0,a0,1698 # 800206a8 <itable>
    8000400e:	ffffd097          	auipc	ra,0xffffd
    80004012:	c7c080e7          	jalr	-900(ra) # 80000c8a <release>
}
    80004016:	60e2                	ld	ra,24(sp)
    80004018:	6442                	ld	s0,16(sp)
    8000401a:	64a2                	ld	s1,8(sp)
    8000401c:	6902                	ld	s2,0(sp)
    8000401e:	6105                	addi	sp,sp,32
    80004020:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004022:	40bc                	lw	a5,64(s1)
    80004024:	dff1                	beqz	a5,80004000 <iput+0x26>
    80004026:	04a49783          	lh	a5,74(s1)
    8000402a:	fbf9                	bnez	a5,80004000 <iput+0x26>
    acquiresleep(&ip->lock);
    8000402c:	01048913          	addi	s2,s1,16
    80004030:	854a                	mv	a0,s2
    80004032:	00001097          	auipc	ra,0x1
    80004036:	aa8080e7          	jalr	-1368(ra) # 80004ada <acquiresleep>
    release(&itable.lock);
    8000403a:	0001c517          	auipc	a0,0x1c
    8000403e:	66e50513          	addi	a0,a0,1646 # 800206a8 <itable>
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
    itrunc(ip);
    8000404a:	8526                	mv	a0,s1
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	ee2080e7          	jalr	-286(ra) # 80003f2e <itrunc>
    ip->type = 0;
    80004054:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004058:	8526                	mv	a0,s1
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	cfc080e7          	jalr	-772(ra) # 80003d56 <iupdate>
    ip->valid = 0;
    80004062:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004066:	854a                	mv	a0,s2
    80004068:	00001097          	auipc	ra,0x1
    8000406c:	ac8080e7          	jalr	-1336(ra) # 80004b30 <releasesleep>
    acquire(&itable.lock);
    80004070:	0001c517          	auipc	a0,0x1c
    80004074:	63850513          	addi	a0,a0,1592 # 800206a8 <itable>
    80004078:	ffffd097          	auipc	ra,0xffffd
    8000407c:	b5e080e7          	jalr	-1186(ra) # 80000bd6 <acquire>
    80004080:	b741                	j	80004000 <iput+0x26>

0000000080004082 <iunlockput>:
{
    80004082:	1101                	addi	sp,sp,-32
    80004084:	ec06                	sd	ra,24(sp)
    80004086:	e822                	sd	s0,16(sp)
    80004088:	e426                	sd	s1,8(sp)
    8000408a:	1000                	addi	s0,sp,32
    8000408c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	e54080e7          	jalr	-428(ra) # 80003ee2 <iunlock>
  iput(ip);
    80004096:	8526                	mv	a0,s1
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	f42080e7          	jalr	-190(ra) # 80003fda <iput>
}
    800040a0:	60e2                	ld	ra,24(sp)
    800040a2:	6442                	ld	s0,16(sp)
    800040a4:	64a2                	ld	s1,8(sp)
    800040a6:	6105                	addi	sp,sp,32
    800040a8:	8082                	ret

00000000800040aa <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040aa:	1141                	addi	sp,sp,-16
    800040ac:	e422                	sd	s0,8(sp)
    800040ae:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040b0:	411c                	lw	a5,0(a0)
    800040b2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040b4:	415c                	lw	a5,4(a0)
    800040b6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040b8:	04451783          	lh	a5,68(a0)
    800040bc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040c0:	04a51783          	lh	a5,74(a0)
    800040c4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040c8:	04c56783          	lwu	a5,76(a0)
    800040cc:	e99c                	sd	a5,16(a1)
}
    800040ce:	6422                	ld	s0,8(sp)
    800040d0:	0141                	addi	sp,sp,16
    800040d2:	8082                	ret

00000000800040d4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040d4:	457c                	lw	a5,76(a0)
    800040d6:	0ed7e963          	bltu	a5,a3,800041c8 <readi+0xf4>
{
    800040da:	7159                	addi	sp,sp,-112
    800040dc:	f486                	sd	ra,104(sp)
    800040de:	f0a2                	sd	s0,96(sp)
    800040e0:	eca6                	sd	s1,88(sp)
    800040e2:	e8ca                	sd	s2,80(sp)
    800040e4:	e4ce                	sd	s3,72(sp)
    800040e6:	e0d2                	sd	s4,64(sp)
    800040e8:	fc56                	sd	s5,56(sp)
    800040ea:	f85a                	sd	s6,48(sp)
    800040ec:	f45e                	sd	s7,40(sp)
    800040ee:	f062                	sd	s8,32(sp)
    800040f0:	ec66                	sd	s9,24(sp)
    800040f2:	e86a                	sd	s10,16(sp)
    800040f4:	e46e                	sd	s11,8(sp)
    800040f6:	1880                	addi	s0,sp,112
    800040f8:	8b2a                	mv	s6,a0
    800040fa:	8bae                	mv	s7,a1
    800040fc:	8a32                	mv	s4,a2
    800040fe:	84b6                	mv	s1,a3
    80004100:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004102:	9f35                	addw	a4,a4,a3
    return 0;
    80004104:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004106:	0ad76063          	bltu	a4,a3,800041a6 <readi+0xd2>
  if(off + n > ip->size)
    8000410a:	00e7f463          	bgeu	a5,a4,80004112 <readi+0x3e>
    n = ip->size - off;
    8000410e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004112:	0a0a8963          	beqz	s5,800041c4 <readi+0xf0>
    80004116:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004118:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000411c:	5c7d                	li	s8,-1
    8000411e:	a82d                	j	80004158 <readi+0x84>
    80004120:	020d1d93          	slli	s11,s10,0x20
    80004124:	020ddd93          	srli	s11,s11,0x20
    80004128:	05890793          	addi	a5,s2,88
    8000412c:	86ee                	mv	a3,s11
    8000412e:	963e                	add	a2,a2,a5
    80004130:	85d2                	mv	a1,s4
    80004132:	855e                	mv	a0,s7
    80004134:	ffffe097          	auipc	ra,0xffffe
    80004138:	634080e7          	jalr	1588(ra) # 80002768 <either_copyout>
    8000413c:	05850d63          	beq	a0,s8,80004196 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004140:	854a                	mv	a0,s2
    80004142:	fffff097          	auipc	ra,0xfffff
    80004146:	5f4080e7          	jalr	1524(ra) # 80003736 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000414a:	013d09bb          	addw	s3,s10,s3
    8000414e:	009d04bb          	addw	s1,s10,s1
    80004152:	9a6e                	add	s4,s4,s11
    80004154:	0559f763          	bgeu	s3,s5,800041a2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004158:	00a4d59b          	srliw	a1,s1,0xa
    8000415c:	855a                	mv	a0,s6
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	8a2080e7          	jalr	-1886(ra) # 80003a00 <bmap>
    80004166:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000416a:	cd85                	beqz	a1,800041a2 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000416c:	000b2503          	lw	a0,0(s6)
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	496080e7          	jalr	1174(ra) # 80003606 <bread>
    80004178:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000417a:	3ff4f613          	andi	a2,s1,1023
    8000417e:	40cc87bb          	subw	a5,s9,a2
    80004182:	413a873b          	subw	a4,s5,s3
    80004186:	8d3e                	mv	s10,a5
    80004188:	2781                	sext.w	a5,a5
    8000418a:	0007069b          	sext.w	a3,a4
    8000418e:	f8f6f9e3          	bgeu	a3,a5,80004120 <readi+0x4c>
    80004192:	8d3a                	mv	s10,a4
    80004194:	b771                	j	80004120 <readi+0x4c>
      brelse(bp);
    80004196:	854a                	mv	a0,s2
    80004198:	fffff097          	auipc	ra,0xfffff
    8000419c:	59e080e7          	jalr	1438(ra) # 80003736 <brelse>
      tot = -1;
    800041a0:	59fd                	li	s3,-1
  }
  return tot;
    800041a2:	0009851b          	sext.w	a0,s3
}
    800041a6:	70a6                	ld	ra,104(sp)
    800041a8:	7406                	ld	s0,96(sp)
    800041aa:	64e6                	ld	s1,88(sp)
    800041ac:	6946                	ld	s2,80(sp)
    800041ae:	69a6                	ld	s3,72(sp)
    800041b0:	6a06                	ld	s4,64(sp)
    800041b2:	7ae2                	ld	s5,56(sp)
    800041b4:	7b42                	ld	s6,48(sp)
    800041b6:	7ba2                	ld	s7,40(sp)
    800041b8:	7c02                	ld	s8,32(sp)
    800041ba:	6ce2                	ld	s9,24(sp)
    800041bc:	6d42                	ld	s10,16(sp)
    800041be:	6da2                	ld	s11,8(sp)
    800041c0:	6165                	addi	sp,sp,112
    800041c2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041c4:	89d6                	mv	s3,s5
    800041c6:	bff1                	j	800041a2 <readi+0xce>
    return 0;
    800041c8:	4501                	li	a0,0
}
    800041ca:	8082                	ret

00000000800041cc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041cc:	457c                	lw	a5,76(a0)
    800041ce:	10d7e863          	bltu	a5,a3,800042de <writei+0x112>
{
    800041d2:	7159                	addi	sp,sp,-112
    800041d4:	f486                	sd	ra,104(sp)
    800041d6:	f0a2                	sd	s0,96(sp)
    800041d8:	eca6                	sd	s1,88(sp)
    800041da:	e8ca                	sd	s2,80(sp)
    800041dc:	e4ce                	sd	s3,72(sp)
    800041de:	e0d2                	sd	s4,64(sp)
    800041e0:	fc56                	sd	s5,56(sp)
    800041e2:	f85a                	sd	s6,48(sp)
    800041e4:	f45e                	sd	s7,40(sp)
    800041e6:	f062                	sd	s8,32(sp)
    800041e8:	ec66                	sd	s9,24(sp)
    800041ea:	e86a                	sd	s10,16(sp)
    800041ec:	e46e                	sd	s11,8(sp)
    800041ee:	1880                	addi	s0,sp,112
    800041f0:	8aaa                	mv	s5,a0
    800041f2:	8bae                	mv	s7,a1
    800041f4:	8a32                	mv	s4,a2
    800041f6:	8936                	mv	s2,a3
    800041f8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041fa:	00e687bb          	addw	a5,a3,a4
    800041fe:	0ed7e263          	bltu	a5,a3,800042e2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004202:	00043737          	lui	a4,0x43
    80004206:	0ef76063          	bltu	a4,a5,800042e6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000420a:	0c0b0863          	beqz	s6,800042da <writei+0x10e>
    8000420e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004210:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004214:	5c7d                	li	s8,-1
    80004216:	a091                	j	8000425a <writei+0x8e>
    80004218:	020d1d93          	slli	s11,s10,0x20
    8000421c:	020ddd93          	srli	s11,s11,0x20
    80004220:	05848793          	addi	a5,s1,88
    80004224:	86ee                	mv	a3,s11
    80004226:	8652                	mv	a2,s4
    80004228:	85de                	mv	a1,s7
    8000422a:	953e                	add	a0,a0,a5
    8000422c:	ffffe097          	auipc	ra,0xffffe
    80004230:	592080e7          	jalr	1426(ra) # 800027be <either_copyin>
    80004234:	07850263          	beq	a0,s8,80004298 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004238:	8526                	mv	a0,s1
    8000423a:	00000097          	auipc	ra,0x0
    8000423e:	780080e7          	jalr	1920(ra) # 800049ba <log_write>
    brelse(bp);
    80004242:	8526                	mv	a0,s1
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	4f2080e7          	jalr	1266(ra) # 80003736 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000424c:	013d09bb          	addw	s3,s10,s3
    80004250:	012d093b          	addw	s2,s10,s2
    80004254:	9a6e                	add	s4,s4,s11
    80004256:	0569f663          	bgeu	s3,s6,800042a2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000425a:	00a9559b          	srliw	a1,s2,0xa
    8000425e:	8556                	mv	a0,s5
    80004260:	fffff097          	auipc	ra,0xfffff
    80004264:	7a0080e7          	jalr	1952(ra) # 80003a00 <bmap>
    80004268:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000426c:	c99d                	beqz	a1,800042a2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000426e:	000aa503          	lw	a0,0(s5)
    80004272:	fffff097          	auipc	ra,0xfffff
    80004276:	394080e7          	jalr	916(ra) # 80003606 <bread>
    8000427a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000427c:	3ff97513          	andi	a0,s2,1023
    80004280:	40ac87bb          	subw	a5,s9,a0
    80004284:	413b073b          	subw	a4,s6,s3
    80004288:	8d3e                	mv	s10,a5
    8000428a:	2781                	sext.w	a5,a5
    8000428c:	0007069b          	sext.w	a3,a4
    80004290:	f8f6f4e3          	bgeu	a3,a5,80004218 <writei+0x4c>
    80004294:	8d3a                	mv	s10,a4
    80004296:	b749                	j	80004218 <writei+0x4c>
      brelse(bp);
    80004298:	8526                	mv	a0,s1
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	49c080e7          	jalr	1180(ra) # 80003736 <brelse>
  }

  if(off > ip->size)
    800042a2:	04caa783          	lw	a5,76(s5)
    800042a6:	0127f463          	bgeu	a5,s2,800042ae <writei+0xe2>
    ip->size = off;
    800042aa:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042ae:	8556                	mv	a0,s5
    800042b0:	00000097          	auipc	ra,0x0
    800042b4:	aa6080e7          	jalr	-1370(ra) # 80003d56 <iupdate>

  return tot;
    800042b8:	0009851b          	sext.w	a0,s3
}
    800042bc:	70a6                	ld	ra,104(sp)
    800042be:	7406                	ld	s0,96(sp)
    800042c0:	64e6                	ld	s1,88(sp)
    800042c2:	6946                	ld	s2,80(sp)
    800042c4:	69a6                	ld	s3,72(sp)
    800042c6:	6a06                	ld	s4,64(sp)
    800042c8:	7ae2                	ld	s5,56(sp)
    800042ca:	7b42                	ld	s6,48(sp)
    800042cc:	7ba2                	ld	s7,40(sp)
    800042ce:	7c02                	ld	s8,32(sp)
    800042d0:	6ce2                	ld	s9,24(sp)
    800042d2:	6d42                	ld	s10,16(sp)
    800042d4:	6da2                	ld	s11,8(sp)
    800042d6:	6165                	addi	sp,sp,112
    800042d8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042da:	89da                	mv	s3,s6
    800042dc:	bfc9                	j	800042ae <writei+0xe2>
    return -1;
    800042de:	557d                	li	a0,-1
}
    800042e0:	8082                	ret
    return -1;
    800042e2:	557d                	li	a0,-1
    800042e4:	bfe1                	j	800042bc <writei+0xf0>
    return -1;
    800042e6:	557d                	li	a0,-1
    800042e8:	bfd1                	j	800042bc <writei+0xf0>

00000000800042ea <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042ea:	1141                	addi	sp,sp,-16
    800042ec:	e406                	sd	ra,8(sp)
    800042ee:	e022                	sd	s0,0(sp)
    800042f0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042f2:	4639                	li	a2,14
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	aae080e7          	jalr	-1362(ra) # 80000da2 <strncmp>
}
    800042fc:	60a2                	ld	ra,8(sp)
    800042fe:	6402                	ld	s0,0(sp)
    80004300:	0141                	addi	sp,sp,16
    80004302:	8082                	ret

0000000080004304 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004304:	7139                	addi	sp,sp,-64
    80004306:	fc06                	sd	ra,56(sp)
    80004308:	f822                	sd	s0,48(sp)
    8000430a:	f426                	sd	s1,40(sp)
    8000430c:	f04a                	sd	s2,32(sp)
    8000430e:	ec4e                	sd	s3,24(sp)
    80004310:	e852                	sd	s4,16(sp)
    80004312:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004314:	04451703          	lh	a4,68(a0)
    80004318:	4785                	li	a5,1
    8000431a:	00f71a63          	bne	a4,a5,8000432e <dirlookup+0x2a>
    8000431e:	892a                	mv	s2,a0
    80004320:	89ae                	mv	s3,a1
    80004322:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004324:	457c                	lw	a5,76(a0)
    80004326:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004328:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000432a:	e79d                	bnez	a5,80004358 <dirlookup+0x54>
    8000432c:	a8a5                	j	800043a4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000432e:	00004517          	auipc	a0,0x4
    80004332:	31250513          	addi	a0,a0,786 # 80008640 <syscalls+0x1c0>
    80004336:	ffffc097          	auipc	ra,0xffffc
    8000433a:	208080e7          	jalr	520(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000433e:	00004517          	auipc	a0,0x4
    80004342:	31a50513          	addi	a0,a0,794 # 80008658 <syscalls+0x1d8>
    80004346:	ffffc097          	auipc	ra,0xffffc
    8000434a:	1f8080e7          	jalr	504(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000434e:	24c1                	addiw	s1,s1,16
    80004350:	04c92783          	lw	a5,76(s2)
    80004354:	04f4f763          	bgeu	s1,a5,800043a2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004358:	4741                	li	a4,16
    8000435a:	86a6                	mv	a3,s1
    8000435c:	fc040613          	addi	a2,s0,-64
    80004360:	4581                	li	a1,0
    80004362:	854a                	mv	a0,s2
    80004364:	00000097          	auipc	ra,0x0
    80004368:	d70080e7          	jalr	-656(ra) # 800040d4 <readi>
    8000436c:	47c1                	li	a5,16
    8000436e:	fcf518e3          	bne	a0,a5,8000433e <dirlookup+0x3a>
    if(de.inum == 0)
    80004372:	fc045783          	lhu	a5,-64(s0)
    80004376:	dfe1                	beqz	a5,8000434e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004378:	fc240593          	addi	a1,s0,-62
    8000437c:	854e                	mv	a0,s3
    8000437e:	00000097          	auipc	ra,0x0
    80004382:	f6c080e7          	jalr	-148(ra) # 800042ea <namecmp>
    80004386:	f561                	bnez	a0,8000434e <dirlookup+0x4a>
      if(poff)
    80004388:	000a0463          	beqz	s4,80004390 <dirlookup+0x8c>
        *poff = off;
    8000438c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004390:	fc045583          	lhu	a1,-64(s0)
    80004394:	00092503          	lw	a0,0(s2)
    80004398:	fffff097          	auipc	ra,0xfffff
    8000439c:	750080e7          	jalr	1872(ra) # 80003ae8 <iget>
    800043a0:	a011                	j	800043a4 <dirlookup+0xa0>
  return 0;
    800043a2:	4501                	li	a0,0
}
    800043a4:	70e2                	ld	ra,56(sp)
    800043a6:	7442                	ld	s0,48(sp)
    800043a8:	74a2                	ld	s1,40(sp)
    800043aa:	7902                	ld	s2,32(sp)
    800043ac:	69e2                	ld	s3,24(sp)
    800043ae:	6a42                	ld	s4,16(sp)
    800043b0:	6121                	addi	sp,sp,64
    800043b2:	8082                	ret

00000000800043b4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043b4:	711d                	addi	sp,sp,-96
    800043b6:	ec86                	sd	ra,88(sp)
    800043b8:	e8a2                	sd	s0,80(sp)
    800043ba:	e4a6                	sd	s1,72(sp)
    800043bc:	e0ca                	sd	s2,64(sp)
    800043be:	fc4e                	sd	s3,56(sp)
    800043c0:	f852                	sd	s4,48(sp)
    800043c2:	f456                	sd	s5,40(sp)
    800043c4:	f05a                	sd	s6,32(sp)
    800043c6:	ec5e                	sd	s7,24(sp)
    800043c8:	e862                	sd	s8,16(sp)
    800043ca:	e466                	sd	s9,8(sp)
    800043cc:	1080                	addi	s0,sp,96
    800043ce:	84aa                	mv	s1,a0
    800043d0:	8aae                	mv	s5,a1
    800043d2:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043d4:	00054703          	lbu	a4,0(a0)
    800043d8:	02f00793          	li	a5,47
    800043dc:	02f70363          	beq	a4,a5,80004402 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043e0:	ffffd097          	auipc	ra,0xffffd
    800043e4:	5cc080e7          	jalr	1484(ra) # 800019ac <myproc>
    800043e8:	15053503          	ld	a0,336(a0)
    800043ec:	00000097          	auipc	ra,0x0
    800043f0:	9f6080e7          	jalr	-1546(ra) # 80003de2 <idup>
    800043f4:	89aa                	mv	s3,a0
  while(*path == '/')
    800043f6:	02f00913          	li	s2,47
  len = path - s;
    800043fa:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800043fc:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043fe:	4b85                	li	s7,1
    80004400:	a865                	j	800044b8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004402:	4585                	li	a1,1
    80004404:	4505                	li	a0,1
    80004406:	fffff097          	auipc	ra,0xfffff
    8000440a:	6e2080e7          	jalr	1762(ra) # 80003ae8 <iget>
    8000440e:	89aa                	mv	s3,a0
    80004410:	b7dd                	j	800043f6 <namex+0x42>
      iunlockput(ip);
    80004412:	854e                	mv	a0,s3
    80004414:	00000097          	auipc	ra,0x0
    80004418:	c6e080e7          	jalr	-914(ra) # 80004082 <iunlockput>
      return 0;
    8000441c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000441e:	854e                	mv	a0,s3
    80004420:	60e6                	ld	ra,88(sp)
    80004422:	6446                	ld	s0,80(sp)
    80004424:	64a6                	ld	s1,72(sp)
    80004426:	6906                	ld	s2,64(sp)
    80004428:	79e2                	ld	s3,56(sp)
    8000442a:	7a42                	ld	s4,48(sp)
    8000442c:	7aa2                	ld	s5,40(sp)
    8000442e:	7b02                	ld	s6,32(sp)
    80004430:	6be2                	ld	s7,24(sp)
    80004432:	6c42                	ld	s8,16(sp)
    80004434:	6ca2                	ld	s9,8(sp)
    80004436:	6125                	addi	sp,sp,96
    80004438:	8082                	ret
      iunlock(ip);
    8000443a:	854e                	mv	a0,s3
    8000443c:	00000097          	auipc	ra,0x0
    80004440:	aa6080e7          	jalr	-1370(ra) # 80003ee2 <iunlock>
      return ip;
    80004444:	bfe9                	j	8000441e <namex+0x6a>
      iunlockput(ip);
    80004446:	854e                	mv	a0,s3
    80004448:	00000097          	auipc	ra,0x0
    8000444c:	c3a080e7          	jalr	-966(ra) # 80004082 <iunlockput>
      return 0;
    80004450:	89e6                	mv	s3,s9
    80004452:	b7f1                	j	8000441e <namex+0x6a>
  len = path - s;
    80004454:	40b48633          	sub	a2,s1,a1
    80004458:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000445c:	099c5463          	bge	s8,s9,800044e4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004460:	4639                	li	a2,14
    80004462:	8552                	mv	a0,s4
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	8ca080e7          	jalr	-1846(ra) # 80000d2e <memmove>
  while(*path == '/')
    8000446c:	0004c783          	lbu	a5,0(s1)
    80004470:	01279763          	bne	a5,s2,8000447e <namex+0xca>
    path++;
    80004474:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004476:	0004c783          	lbu	a5,0(s1)
    8000447a:	ff278de3          	beq	a5,s2,80004474 <namex+0xc0>
    ilock(ip);
    8000447e:	854e                	mv	a0,s3
    80004480:	00000097          	auipc	ra,0x0
    80004484:	9a0080e7          	jalr	-1632(ra) # 80003e20 <ilock>
    if(ip->type != T_DIR){
    80004488:	04499783          	lh	a5,68(s3)
    8000448c:	f97793e3          	bne	a5,s7,80004412 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004490:	000a8563          	beqz	s5,8000449a <namex+0xe6>
    80004494:	0004c783          	lbu	a5,0(s1)
    80004498:	d3cd                	beqz	a5,8000443a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000449a:	865a                	mv	a2,s6
    8000449c:	85d2                	mv	a1,s4
    8000449e:	854e                	mv	a0,s3
    800044a0:	00000097          	auipc	ra,0x0
    800044a4:	e64080e7          	jalr	-412(ra) # 80004304 <dirlookup>
    800044a8:	8caa                	mv	s9,a0
    800044aa:	dd51                	beqz	a0,80004446 <namex+0x92>
    iunlockput(ip);
    800044ac:	854e                	mv	a0,s3
    800044ae:	00000097          	auipc	ra,0x0
    800044b2:	bd4080e7          	jalr	-1068(ra) # 80004082 <iunlockput>
    ip = next;
    800044b6:	89e6                	mv	s3,s9
  while(*path == '/')
    800044b8:	0004c783          	lbu	a5,0(s1)
    800044bc:	05279763          	bne	a5,s2,8000450a <namex+0x156>
    path++;
    800044c0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044c2:	0004c783          	lbu	a5,0(s1)
    800044c6:	ff278de3          	beq	a5,s2,800044c0 <namex+0x10c>
  if(*path == 0)
    800044ca:	c79d                	beqz	a5,800044f8 <namex+0x144>
    path++;
    800044cc:	85a6                	mv	a1,s1
  len = path - s;
    800044ce:	8cda                	mv	s9,s6
    800044d0:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800044d2:	01278963          	beq	a5,s2,800044e4 <namex+0x130>
    800044d6:	dfbd                	beqz	a5,80004454 <namex+0xa0>
    path++;
    800044d8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800044da:	0004c783          	lbu	a5,0(s1)
    800044de:	ff279ce3          	bne	a5,s2,800044d6 <namex+0x122>
    800044e2:	bf8d                	j	80004454 <namex+0xa0>
    memmove(name, s, len);
    800044e4:	2601                	sext.w	a2,a2
    800044e6:	8552                	mv	a0,s4
    800044e8:	ffffd097          	auipc	ra,0xffffd
    800044ec:	846080e7          	jalr	-1978(ra) # 80000d2e <memmove>
    name[len] = 0;
    800044f0:	9cd2                	add	s9,s9,s4
    800044f2:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800044f6:	bf9d                	j	8000446c <namex+0xb8>
  if(nameiparent){
    800044f8:	f20a83e3          	beqz	s5,8000441e <namex+0x6a>
    iput(ip);
    800044fc:	854e                	mv	a0,s3
    800044fe:	00000097          	auipc	ra,0x0
    80004502:	adc080e7          	jalr	-1316(ra) # 80003fda <iput>
    return 0;
    80004506:	4981                	li	s3,0
    80004508:	bf19                	j	8000441e <namex+0x6a>
  if(*path == 0)
    8000450a:	d7fd                	beqz	a5,800044f8 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000450c:	0004c783          	lbu	a5,0(s1)
    80004510:	85a6                	mv	a1,s1
    80004512:	b7d1                	j	800044d6 <namex+0x122>

0000000080004514 <dirlink>:
{
    80004514:	7139                	addi	sp,sp,-64
    80004516:	fc06                	sd	ra,56(sp)
    80004518:	f822                	sd	s0,48(sp)
    8000451a:	f426                	sd	s1,40(sp)
    8000451c:	f04a                	sd	s2,32(sp)
    8000451e:	ec4e                	sd	s3,24(sp)
    80004520:	e852                	sd	s4,16(sp)
    80004522:	0080                	addi	s0,sp,64
    80004524:	892a                	mv	s2,a0
    80004526:	8a2e                	mv	s4,a1
    80004528:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000452a:	4601                	li	a2,0
    8000452c:	00000097          	auipc	ra,0x0
    80004530:	dd8080e7          	jalr	-552(ra) # 80004304 <dirlookup>
    80004534:	e93d                	bnez	a0,800045aa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004536:	04c92483          	lw	s1,76(s2)
    8000453a:	c49d                	beqz	s1,80004568 <dirlink+0x54>
    8000453c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000453e:	4741                	li	a4,16
    80004540:	86a6                	mv	a3,s1
    80004542:	fc040613          	addi	a2,s0,-64
    80004546:	4581                	li	a1,0
    80004548:	854a                	mv	a0,s2
    8000454a:	00000097          	auipc	ra,0x0
    8000454e:	b8a080e7          	jalr	-1142(ra) # 800040d4 <readi>
    80004552:	47c1                	li	a5,16
    80004554:	06f51163          	bne	a0,a5,800045b6 <dirlink+0xa2>
    if(de.inum == 0)
    80004558:	fc045783          	lhu	a5,-64(s0)
    8000455c:	c791                	beqz	a5,80004568 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000455e:	24c1                	addiw	s1,s1,16
    80004560:	04c92783          	lw	a5,76(s2)
    80004564:	fcf4ede3          	bltu	s1,a5,8000453e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004568:	4639                	li	a2,14
    8000456a:	85d2                	mv	a1,s4
    8000456c:	fc240513          	addi	a0,s0,-62
    80004570:	ffffd097          	auipc	ra,0xffffd
    80004574:	86e080e7          	jalr	-1938(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004578:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000457c:	4741                	li	a4,16
    8000457e:	86a6                	mv	a3,s1
    80004580:	fc040613          	addi	a2,s0,-64
    80004584:	4581                	li	a1,0
    80004586:	854a                	mv	a0,s2
    80004588:	00000097          	auipc	ra,0x0
    8000458c:	c44080e7          	jalr	-956(ra) # 800041cc <writei>
    80004590:	1541                	addi	a0,a0,-16
    80004592:	00a03533          	snez	a0,a0
    80004596:	40a00533          	neg	a0,a0
}
    8000459a:	70e2                	ld	ra,56(sp)
    8000459c:	7442                	ld	s0,48(sp)
    8000459e:	74a2                	ld	s1,40(sp)
    800045a0:	7902                	ld	s2,32(sp)
    800045a2:	69e2                	ld	s3,24(sp)
    800045a4:	6a42                	ld	s4,16(sp)
    800045a6:	6121                	addi	sp,sp,64
    800045a8:	8082                	ret
    iput(ip);
    800045aa:	00000097          	auipc	ra,0x0
    800045ae:	a30080e7          	jalr	-1488(ra) # 80003fda <iput>
    return -1;
    800045b2:	557d                	li	a0,-1
    800045b4:	b7dd                	j	8000459a <dirlink+0x86>
      panic("dirlink read");
    800045b6:	00004517          	auipc	a0,0x4
    800045ba:	0b250513          	addi	a0,a0,178 # 80008668 <syscalls+0x1e8>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>

00000000800045c6 <namei>:

struct inode*
namei(char *path)
{
    800045c6:	1101                	addi	sp,sp,-32
    800045c8:	ec06                	sd	ra,24(sp)
    800045ca:	e822                	sd	s0,16(sp)
    800045cc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800045ce:	fe040613          	addi	a2,s0,-32
    800045d2:	4581                	li	a1,0
    800045d4:	00000097          	auipc	ra,0x0
    800045d8:	de0080e7          	jalr	-544(ra) # 800043b4 <namex>
}
    800045dc:	60e2                	ld	ra,24(sp)
    800045de:	6442                	ld	s0,16(sp)
    800045e0:	6105                	addi	sp,sp,32
    800045e2:	8082                	ret

00000000800045e4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045e4:	1141                	addi	sp,sp,-16
    800045e6:	e406                	sd	ra,8(sp)
    800045e8:	e022                	sd	s0,0(sp)
    800045ea:	0800                	addi	s0,sp,16
    800045ec:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045ee:	4585                	li	a1,1
    800045f0:	00000097          	auipc	ra,0x0
    800045f4:	dc4080e7          	jalr	-572(ra) # 800043b4 <namex>
}
    800045f8:	60a2                	ld	ra,8(sp)
    800045fa:	6402                	ld	s0,0(sp)
    800045fc:	0141                	addi	sp,sp,16
    800045fe:	8082                	ret

0000000080004600 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004600:	1101                	addi	sp,sp,-32
    80004602:	ec06                	sd	ra,24(sp)
    80004604:	e822                	sd	s0,16(sp)
    80004606:	e426                	sd	s1,8(sp)
    80004608:	e04a                	sd	s2,0(sp)
    8000460a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000460c:	0001e917          	auipc	s2,0x1e
    80004610:	b4490913          	addi	s2,s2,-1212 # 80022150 <log>
    80004614:	01892583          	lw	a1,24(s2)
    80004618:	02892503          	lw	a0,40(s2)
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	fea080e7          	jalr	-22(ra) # 80003606 <bread>
    80004624:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004626:	02c92683          	lw	a3,44(s2)
    8000462a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000462c:	02d05763          	blez	a3,8000465a <write_head+0x5a>
    80004630:	0001e797          	auipc	a5,0x1e
    80004634:	b5078793          	addi	a5,a5,-1200 # 80022180 <log+0x30>
    80004638:	05c50713          	addi	a4,a0,92
    8000463c:	36fd                	addiw	a3,a3,-1
    8000463e:	1682                	slli	a3,a3,0x20
    80004640:	9281                	srli	a3,a3,0x20
    80004642:	068a                	slli	a3,a3,0x2
    80004644:	0001e617          	auipc	a2,0x1e
    80004648:	b4060613          	addi	a2,a2,-1216 # 80022184 <log+0x34>
    8000464c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000464e:	4390                	lw	a2,0(a5)
    80004650:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004652:	0791                	addi	a5,a5,4
    80004654:	0711                	addi	a4,a4,4
    80004656:	fed79ce3          	bne	a5,a3,8000464e <write_head+0x4e>
  }
  bwrite(buf);
    8000465a:	8526                	mv	a0,s1
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	09c080e7          	jalr	156(ra) # 800036f8 <bwrite>
  brelse(buf);
    80004664:	8526                	mv	a0,s1
    80004666:	fffff097          	auipc	ra,0xfffff
    8000466a:	0d0080e7          	jalr	208(ra) # 80003736 <brelse>
}
    8000466e:	60e2                	ld	ra,24(sp)
    80004670:	6442                	ld	s0,16(sp)
    80004672:	64a2                	ld	s1,8(sp)
    80004674:	6902                	ld	s2,0(sp)
    80004676:	6105                	addi	sp,sp,32
    80004678:	8082                	ret

000000008000467a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000467a:	0001e797          	auipc	a5,0x1e
    8000467e:	b027a783          	lw	a5,-1278(a5) # 8002217c <log+0x2c>
    80004682:	0af05d63          	blez	a5,8000473c <install_trans+0xc2>
{
    80004686:	7139                	addi	sp,sp,-64
    80004688:	fc06                	sd	ra,56(sp)
    8000468a:	f822                	sd	s0,48(sp)
    8000468c:	f426                	sd	s1,40(sp)
    8000468e:	f04a                	sd	s2,32(sp)
    80004690:	ec4e                	sd	s3,24(sp)
    80004692:	e852                	sd	s4,16(sp)
    80004694:	e456                	sd	s5,8(sp)
    80004696:	e05a                	sd	s6,0(sp)
    80004698:	0080                	addi	s0,sp,64
    8000469a:	8b2a                	mv	s6,a0
    8000469c:	0001ea97          	auipc	s5,0x1e
    800046a0:	ae4a8a93          	addi	s5,s5,-1308 # 80022180 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046a4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046a6:	0001e997          	auipc	s3,0x1e
    800046aa:	aaa98993          	addi	s3,s3,-1366 # 80022150 <log>
    800046ae:	a00d                	j	800046d0 <install_trans+0x56>
    brelse(lbuf);
    800046b0:	854a                	mv	a0,s2
    800046b2:	fffff097          	auipc	ra,0xfffff
    800046b6:	084080e7          	jalr	132(ra) # 80003736 <brelse>
    brelse(dbuf);
    800046ba:	8526                	mv	a0,s1
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	07a080e7          	jalr	122(ra) # 80003736 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046c4:	2a05                	addiw	s4,s4,1
    800046c6:	0a91                	addi	s5,s5,4
    800046c8:	02c9a783          	lw	a5,44(s3)
    800046cc:	04fa5e63          	bge	s4,a5,80004728 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046d0:	0189a583          	lw	a1,24(s3)
    800046d4:	014585bb          	addw	a1,a1,s4
    800046d8:	2585                	addiw	a1,a1,1
    800046da:	0289a503          	lw	a0,40(s3)
    800046de:	fffff097          	auipc	ra,0xfffff
    800046e2:	f28080e7          	jalr	-216(ra) # 80003606 <bread>
    800046e6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046e8:	000aa583          	lw	a1,0(s5)
    800046ec:	0289a503          	lw	a0,40(s3)
    800046f0:	fffff097          	auipc	ra,0xfffff
    800046f4:	f16080e7          	jalr	-234(ra) # 80003606 <bread>
    800046f8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046fa:	40000613          	li	a2,1024
    800046fe:	05890593          	addi	a1,s2,88
    80004702:	05850513          	addi	a0,a0,88
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	628080e7          	jalr	1576(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000470e:	8526                	mv	a0,s1
    80004710:	fffff097          	auipc	ra,0xfffff
    80004714:	fe8080e7          	jalr	-24(ra) # 800036f8 <bwrite>
    if(recovering == 0)
    80004718:	f80b1ce3          	bnez	s6,800046b0 <install_trans+0x36>
      bunpin(dbuf);
    8000471c:	8526                	mv	a0,s1
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	0f2080e7          	jalr	242(ra) # 80003810 <bunpin>
    80004726:	b769                	j	800046b0 <install_trans+0x36>
}
    80004728:	70e2                	ld	ra,56(sp)
    8000472a:	7442                	ld	s0,48(sp)
    8000472c:	74a2                	ld	s1,40(sp)
    8000472e:	7902                	ld	s2,32(sp)
    80004730:	69e2                	ld	s3,24(sp)
    80004732:	6a42                	ld	s4,16(sp)
    80004734:	6aa2                	ld	s5,8(sp)
    80004736:	6b02                	ld	s6,0(sp)
    80004738:	6121                	addi	sp,sp,64
    8000473a:	8082                	ret
    8000473c:	8082                	ret

000000008000473e <initlog>:
{
    8000473e:	7179                	addi	sp,sp,-48
    80004740:	f406                	sd	ra,40(sp)
    80004742:	f022                	sd	s0,32(sp)
    80004744:	ec26                	sd	s1,24(sp)
    80004746:	e84a                	sd	s2,16(sp)
    80004748:	e44e                	sd	s3,8(sp)
    8000474a:	1800                	addi	s0,sp,48
    8000474c:	892a                	mv	s2,a0
    8000474e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004750:	0001e497          	auipc	s1,0x1e
    80004754:	a0048493          	addi	s1,s1,-1536 # 80022150 <log>
    80004758:	00004597          	auipc	a1,0x4
    8000475c:	f2058593          	addi	a1,a1,-224 # 80008678 <syscalls+0x1f8>
    80004760:	8526                	mv	a0,s1
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	3e4080e7          	jalr	996(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000476a:	0149a583          	lw	a1,20(s3)
    8000476e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004770:	0109a783          	lw	a5,16(s3)
    80004774:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004776:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000477a:	854a                	mv	a0,s2
    8000477c:	fffff097          	auipc	ra,0xfffff
    80004780:	e8a080e7          	jalr	-374(ra) # 80003606 <bread>
  log.lh.n = lh->n;
    80004784:	4d34                	lw	a3,88(a0)
    80004786:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004788:	02d05563          	blez	a3,800047b2 <initlog+0x74>
    8000478c:	05c50793          	addi	a5,a0,92
    80004790:	0001e717          	auipc	a4,0x1e
    80004794:	9f070713          	addi	a4,a4,-1552 # 80022180 <log+0x30>
    80004798:	36fd                	addiw	a3,a3,-1
    8000479a:	1682                	slli	a3,a3,0x20
    8000479c:	9281                	srli	a3,a3,0x20
    8000479e:	068a                	slli	a3,a3,0x2
    800047a0:	06050613          	addi	a2,a0,96
    800047a4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800047a6:	4390                	lw	a2,0(a5)
    800047a8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800047aa:	0791                	addi	a5,a5,4
    800047ac:	0711                	addi	a4,a4,4
    800047ae:	fed79ce3          	bne	a5,a3,800047a6 <initlog+0x68>
  brelse(buf);
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	f84080e7          	jalr	-124(ra) # 80003736 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047ba:	4505                	li	a0,1
    800047bc:	00000097          	auipc	ra,0x0
    800047c0:	ebe080e7          	jalr	-322(ra) # 8000467a <install_trans>
  log.lh.n = 0;
    800047c4:	0001e797          	auipc	a5,0x1e
    800047c8:	9a07ac23          	sw	zero,-1608(a5) # 8002217c <log+0x2c>
  write_head(); // clear the log
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	e34080e7          	jalr	-460(ra) # 80004600 <write_head>
}
    800047d4:	70a2                	ld	ra,40(sp)
    800047d6:	7402                	ld	s0,32(sp)
    800047d8:	64e2                	ld	s1,24(sp)
    800047da:	6942                	ld	s2,16(sp)
    800047dc:	69a2                	ld	s3,8(sp)
    800047de:	6145                	addi	sp,sp,48
    800047e0:	8082                	ret

00000000800047e2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047e2:	1101                	addi	sp,sp,-32
    800047e4:	ec06                	sd	ra,24(sp)
    800047e6:	e822                	sd	s0,16(sp)
    800047e8:	e426                	sd	s1,8(sp)
    800047ea:	e04a                	sd	s2,0(sp)
    800047ec:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047ee:	0001e517          	auipc	a0,0x1e
    800047f2:	96250513          	addi	a0,a0,-1694 # 80022150 <log>
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	3e0080e7          	jalr	992(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800047fe:	0001e497          	auipc	s1,0x1e
    80004802:	95248493          	addi	s1,s1,-1710 # 80022150 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004806:	4979                	li	s2,30
    80004808:	a039                	j	80004816 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000480a:	85a6                	mv	a1,s1
    8000480c:	8526                	mv	a0,s1
    8000480e:	ffffe097          	auipc	ra,0xffffe
    80004812:	b46080e7          	jalr	-1210(ra) # 80002354 <sleep>
    if(log.committing){
    80004816:	50dc                	lw	a5,36(s1)
    80004818:	fbed                	bnez	a5,8000480a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000481a:	509c                	lw	a5,32(s1)
    8000481c:	0017871b          	addiw	a4,a5,1
    80004820:	0007069b          	sext.w	a3,a4
    80004824:	0027179b          	slliw	a5,a4,0x2
    80004828:	9fb9                	addw	a5,a5,a4
    8000482a:	0017979b          	slliw	a5,a5,0x1
    8000482e:	54d8                	lw	a4,44(s1)
    80004830:	9fb9                	addw	a5,a5,a4
    80004832:	00f95963          	bge	s2,a5,80004844 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004836:	85a6                	mv	a1,s1
    80004838:	8526                	mv	a0,s1
    8000483a:	ffffe097          	auipc	ra,0xffffe
    8000483e:	b1a080e7          	jalr	-1254(ra) # 80002354 <sleep>
    80004842:	bfd1                	j	80004816 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004844:	0001e517          	auipc	a0,0x1e
    80004848:	90c50513          	addi	a0,a0,-1780 # 80022150 <log>
    8000484c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	43c080e7          	jalr	1084(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004856:	60e2                	ld	ra,24(sp)
    80004858:	6442                	ld	s0,16(sp)
    8000485a:	64a2                	ld	s1,8(sp)
    8000485c:	6902                	ld	s2,0(sp)
    8000485e:	6105                	addi	sp,sp,32
    80004860:	8082                	ret

0000000080004862 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004862:	7139                	addi	sp,sp,-64
    80004864:	fc06                	sd	ra,56(sp)
    80004866:	f822                	sd	s0,48(sp)
    80004868:	f426                	sd	s1,40(sp)
    8000486a:	f04a                	sd	s2,32(sp)
    8000486c:	ec4e                	sd	s3,24(sp)
    8000486e:	e852                	sd	s4,16(sp)
    80004870:	e456                	sd	s5,8(sp)
    80004872:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004874:	0001e497          	auipc	s1,0x1e
    80004878:	8dc48493          	addi	s1,s1,-1828 # 80022150 <log>
    8000487c:	8526                	mv	a0,s1
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	358080e7          	jalr	856(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004886:	509c                	lw	a5,32(s1)
    80004888:	37fd                	addiw	a5,a5,-1
    8000488a:	0007891b          	sext.w	s2,a5
    8000488e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004890:	50dc                	lw	a5,36(s1)
    80004892:	e7b9                	bnez	a5,800048e0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004894:	04091e63          	bnez	s2,800048f0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004898:	0001e497          	auipc	s1,0x1e
    8000489c:	8b848493          	addi	s1,s1,-1864 # 80022150 <log>
    800048a0:	4785                	li	a5,1
    800048a2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048a4:	8526                	mv	a0,s1
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	3e4080e7          	jalr	996(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048ae:	54dc                	lw	a5,44(s1)
    800048b0:	06f04763          	bgtz	a5,8000491e <end_op+0xbc>
    acquire(&log.lock);
    800048b4:	0001e497          	auipc	s1,0x1e
    800048b8:	89c48493          	addi	s1,s1,-1892 # 80022150 <log>
    800048bc:	8526                	mv	a0,s1
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	318080e7          	jalr	792(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800048c6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800048ca:	8526                	mv	a0,s1
    800048cc:	ffffe097          	auipc	ra,0xffffe
    800048d0:	aec080e7          	jalr	-1300(ra) # 800023b8 <wakeup>
    release(&log.lock);
    800048d4:	8526                	mv	a0,s1
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	3b4080e7          	jalr	948(ra) # 80000c8a <release>
}
    800048de:	a03d                	j	8000490c <end_op+0xaa>
    panic("log.committing");
    800048e0:	00004517          	auipc	a0,0x4
    800048e4:	da050513          	addi	a0,a0,-608 # 80008680 <syscalls+0x200>
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	c56080e7          	jalr	-938(ra) # 8000053e <panic>
    wakeup(&log);
    800048f0:	0001e497          	auipc	s1,0x1e
    800048f4:	86048493          	addi	s1,s1,-1952 # 80022150 <log>
    800048f8:	8526                	mv	a0,s1
    800048fa:	ffffe097          	auipc	ra,0xffffe
    800048fe:	abe080e7          	jalr	-1346(ra) # 800023b8 <wakeup>
  release(&log.lock);
    80004902:	8526                	mv	a0,s1
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	386080e7          	jalr	902(ra) # 80000c8a <release>
}
    8000490c:	70e2                	ld	ra,56(sp)
    8000490e:	7442                	ld	s0,48(sp)
    80004910:	74a2                	ld	s1,40(sp)
    80004912:	7902                	ld	s2,32(sp)
    80004914:	69e2                	ld	s3,24(sp)
    80004916:	6a42                	ld	s4,16(sp)
    80004918:	6aa2                	ld	s5,8(sp)
    8000491a:	6121                	addi	sp,sp,64
    8000491c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000491e:	0001ea97          	auipc	s5,0x1e
    80004922:	862a8a93          	addi	s5,s5,-1950 # 80022180 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004926:	0001ea17          	auipc	s4,0x1e
    8000492a:	82aa0a13          	addi	s4,s4,-2006 # 80022150 <log>
    8000492e:	018a2583          	lw	a1,24(s4)
    80004932:	012585bb          	addw	a1,a1,s2
    80004936:	2585                	addiw	a1,a1,1
    80004938:	028a2503          	lw	a0,40(s4)
    8000493c:	fffff097          	auipc	ra,0xfffff
    80004940:	cca080e7          	jalr	-822(ra) # 80003606 <bread>
    80004944:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004946:	000aa583          	lw	a1,0(s5)
    8000494a:	028a2503          	lw	a0,40(s4)
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	cb8080e7          	jalr	-840(ra) # 80003606 <bread>
    80004956:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004958:	40000613          	li	a2,1024
    8000495c:	05850593          	addi	a1,a0,88
    80004960:	05848513          	addi	a0,s1,88
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	3ca080e7          	jalr	970(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000496c:	8526                	mv	a0,s1
    8000496e:	fffff097          	auipc	ra,0xfffff
    80004972:	d8a080e7          	jalr	-630(ra) # 800036f8 <bwrite>
    brelse(from);
    80004976:	854e                	mv	a0,s3
    80004978:	fffff097          	auipc	ra,0xfffff
    8000497c:	dbe080e7          	jalr	-578(ra) # 80003736 <brelse>
    brelse(to);
    80004980:	8526                	mv	a0,s1
    80004982:	fffff097          	auipc	ra,0xfffff
    80004986:	db4080e7          	jalr	-588(ra) # 80003736 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000498a:	2905                	addiw	s2,s2,1
    8000498c:	0a91                	addi	s5,s5,4
    8000498e:	02ca2783          	lw	a5,44(s4)
    80004992:	f8f94ee3          	blt	s2,a5,8000492e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004996:	00000097          	auipc	ra,0x0
    8000499a:	c6a080e7          	jalr	-918(ra) # 80004600 <write_head>
    install_trans(0); // Now install writes to home locations
    8000499e:	4501                	li	a0,0
    800049a0:	00000097          	auipc	ra,0x0
    800049a4:	cda080e7          	jalr	-806(ra) # 8000467a <install_trans>
    log.lh.n = 0;
    800049a8:	0001d797          	auipc	a5,0x1d
    800049ac:	7c07aa23          	sw	zero,2004(a5) # 8002217c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049b0:	00000097          	auipc	ra,0x0
    800049b4:	c50080e7          	jalr	-944(ra) # 80004600 <write_head>
    800049b8:	bdf5                	j	800048b4 <end_op+0x52>

00000000800049ba <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049ba:	1101                	addi	sp,sp,-32
    800049bc:	ec06                	sd	ra,24(sp)
    800049be:	e822                	sd	s0,16(sp)
    800049c0:	e426                	sd	s1,8(sp)
    800049c2:	e04a                	sd	s2,0(sp)
    800049c4:	1000                	addi	s0,sp,32
    800049c6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800049c8:	0001d917          	auipc	s2,0x1d
    800049cc:	78890913          	addi	s2,s2,1928 # 80022150 <log>
    800049d0:	854a                	mv	a0,s2
    800049d2:	ffffc097          	auipc	ra,0xffffc
    800049d6:	204080e7          	jalr	516(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800049da:	02c92603          	lw	a2,44(s2)
    800049de:	47f5                	li	a5,29
    800049e0:	06c7c563          	blt	a5,a2,80004a4a <log_write+0x90>
    800049e4:	0001d797          	auipc	a5,0x1d
    800049e8:	7887a783          	lw	a5,1928(a5) # 8002216c <log+0x1c>
    800049ec:	37fd                	addiw	a5,a5,-1
    800049ee:	04f65e63          	bge	a2,a5,80004a4a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049f2:	0001d797          	auipc	a5,0x1d
    800049f6:	77e7a783          	lw	a5,1918(a5) # 80022170 <log+0x20>
    800049fa:	06f05063          	blez	a5,80004a5a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049fe:	4781                	li	a5,0
    80004a00:	06c05563          	blez	a2,80004a6a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a04:	44cc                	lw	a1,12(s1)
    80004a06:	0001d717          	auipc	a4,0x1d
    80004a0a:	77a70713          	addi	a4,a4,1914 # 80022180 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a0e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a10:	4314                	lw	a3,0(a4)
    80004a12:	04b68c63          	beq	a3,a1,80004a6a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a16:	2785                	addiw	a5,a5,1
    80004a18:	0711                	addi	a4,a4,4
    80004a1a:	fef61be3          	bne	a2,a5,80004a10 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a1e:	0621                	addi	a2,a2,8
    80004a20:	060a                	slli	a2,a2,0x2
    80004a22:	0001d797          	auipc	a5,0x1d
    80004a26:	72e78793          	addi	a5,a5,1838 # 80022150 <log>
    80004a2a:	963e                	add	a2,a2,a5
    80004a2c:	44dc                	lw	a5,12(s1)
    80004a2e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a30:	8526                	mv	a0,s1
    80004a32:	fffff097          	auipc	ra,0xfffff
    80004a36:	da2080e7          	jalr	-606(ra) # 800037d4 <bpin>
    log.lh.n++;
    80004a3a:	0001d717          	auipc	a4,0x1d
    80004a3e:	71670713          	addi	a4,a4,1814 # 80022150 <log>
    80004a42:	575c                	lw	a5,44(a4)
    80004a44:	2785                	addiw	a5,a5,1
    80004a46:	d75c                	sw	a5,44(a4)
    80004a48:	a835                	j	80004a84 <log_write+0xca>
    panic("too big a transaction");
    80004a4a:	00004517          	auipc	a0,0x4
    80004a4e:	c4650513          	addi	a0,a0,-954 # 80008690 <syscalls+0x210>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	aec080e7          	jalr	-1300(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a5a:	00004517          	auipc	a0,0x4
    80004a5e:	c4e50513          	addi	a0,a0,-946 # 800086a8 <syscalls+0x228>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	adc080e7          	jalr	-1316(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a6a:	00878713          	addi	a4,a5,8
    80004a6e:	00271693          	slli	a3,a4,0x2
    80004a72:	0001d717          	auipc	a4,0x1d
    80004a76:	6de70713          	addi	a4,a4,1758 # 80022150 <log>
    80004a7a:	9736                	add	a4,a4,a3
    80004a7c:	44d4                	lw	a3,12(s1)
    80004a7e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a80:	faf608e3          	beq	a2,a5,80004a30 <log_write+0x76>
  }
  release(&log.lock);
    80004a84:	0001d517          	auipc	a0,0x1d
    80004a88:	6cc50513          	addi	a0,a0,1740 # 80022150 <log>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	1fe080e7          	jalr	510(ra) # 80000c8a <release>
}
    80004a94:	60e2                	ld	ra,24(sp)
    80004a96:	6442                	ld	s0,16(sp)
    80004a98:	64a2                	ld	s1,8(sp)
    80004a9a:	6902                	ld	s2,0(sp)
    80004a9c:	6105                	addi	sp,sp,32
    80004a9e:	8082                	ret

0000000080004aa0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004aa0:	1101                	addi	sp,sp,-32
    80004aa2:	ec06                	sd	ra,24(sp)
    80004aa4:	e822                	sd	s0,16(sp)
    80004aa6:	e426                	sd	s1,8(sp)
    80004aa8:	e04a                	sd	s2,0(sp)
    80004aaa:	1000                	addi	s0,sp,32
    80004aac:	84aa                	mv	s1,a0
    80004aae:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004ab0:	00004597          	auipc	a1,0x4
    80004ab4:	c1858593          	addi	a1,a1,-1000 # 800086c8 <syscalls+0x248>
    80004ab8:	0521                	addi	a0,a0,8
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	08c080e7          	jalr	140(ra) # 80000b46 <initlock>
  lk->name = name;
    80004ac2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ac6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aca:	0204a423          	sw	zero,40(s1)
}
    80004ace:	60e2                	ld	ra,24(sp)
    80004ad0:	6442                	ld	s0,16(sp)
    80004ad2:	64a2                	ld	s1,8(sp)
    80004ad4:	6902                	ld	s2,0(sp)
    80004ad6:	6105                	addi	sp,sp,32
    80004ad8:	8082                	ret

0000000080004ada <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004ada:	1101                	addi	sp,sp,-32
    80004adc:	ec06                	sd	ra,24(sp)
    80004ade:	e822                	sd	s0,16(sp)
    80004ae0:	e426                	sd	s1,8(sp)
    80004ae2:	e04a                	sd	s2,0(sp)
    80004ae4:	1000                	addi	s0,sp,32
    80004ae6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ae8:	00850913          	addi	s2,a0,8
    80004aec:	854a                	mv	a0,s2
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	0e8080e7          	jalr	232(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004af6:	409c                	lw	a5,0(s1)
    80004af8:	cb89                	beqz	a5,80004b0a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004afa:	85ca                	mv	a1,s2
    80004afc:	8526                	mv	a0,s1
    80004afe:	ffffe097          	auipc	ra,0xffffe
    80004b02:	856080e7          	jalr	-1962(ra) # 80002354 <sleep>
  while (lk->locked) {
    80004b06:	409c                	lw	a5,0(s1)
    80004b08:	fbed                	bnez	a5,80004afa <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b0a:	4785                	li	a5,1
    80004b0c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	e9e080e7          	jalr	-354(ra) # 800019ac <myproc>
    80004b16:	591c                	lw	a5,48(a0)
    80004b18:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b1a:	854a                	mv	a0,s2
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	16e080e7          	jalr	366(ra) # 80000c8a <release>
}
    80004b24:	60e2                	ld	ra,24(sp)
    80004b26:	6442                	ld	s0,16(sp)
    80004b28:	64a2                	ld	s1,8(sp)
    80004b2a:	6902                	ld	s2,0(sp)
    80004b2c:	6105                	addi	sp,sp,32
    80004b2e:	8082                	ret

0000000080004b30 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b30:	1101                	addi	sp,sp,-32
    80004b32:	ec06                	sd	ra,24(sp)
    80004b34:	e822                	sd	s0,16(sp)
    80004b36:	e426                	sd	s1,8(sp)
    80004b38:	e04a                	sd	s2,0(sp)
    80004b3a:	1000                	addi	s0,sp,32
    80004b3c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b3e:	00850913          	addi	s2,a0,8
    80004b42:	854a                	mv	a0,s2
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	092080e7          	jalr	146(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004b4c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b50:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b54:	8526                	mv	a0,s1
    80004b56:	ffffe097          	auipc	ra,0xffffe
    80004b5a:	862080e7          	jalr	-1950(ra) # 800023b8 <wakeup>
  release(&lk->lk);
    80004b5e:	854a                	mv	a0,s2
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	12a080e7          	jalr	298(ra) # 80000c8a <release>
}
    80004b68:	60e2                	ld	ra,24(sp)
    80004b6a:	6442                	ld	s0,16(sp)
    80004b6c:	64a2                	ld	s1,8(sp)
    80004b6e:	6902                	ld	s2,0(sp)
    80004b70:	6105                	addi	sp,sp,32
    80004b72:	8082                	ret

0000000080004b74 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b74:	7179                	addi	sp,sp,-48
    80004b76:	f406                	sd	ra,40(sp)
    80004b78:	f022                	sd	s0,32(sp)
    80004b7a:	ec26                	sd	s1,24(sp)
    80004b7c:	e84a                	sd	s2,16(sp)
    80004b7e:	e44e                	sd	s3,8(sp)
    80004b80:	1800                	addi	s0,sp,48
    80004b82:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b84:	00850913          	addi	s2,a0,8
    80004b88:	854a                	mv	a0,s2
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	04c080e7          	jalr	76(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b92:	409c                	lw	a5,0(s1)
    80004b94:	ef99                	bnez	a5,80004bb2 <holdingsleep+0x3e>
    80004b96:	4481                	li	s1,0
  release(&lk->lk);
    80004b98:	854a                	mv	a0,s2
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	0f0080e7          	jalr	240(ra) # 80000c8a <release>
  return r;
}
    80004ba2:	8526                	mv	a0,s1
    80004ba4:	70a2                	ld	ra,40(sp)
    80004ba6:	7402                	ld	s0,32(sp)
    80004ba8:	64e2                	ld	s1,24(sp)
    80004baa:	6942                	ld	s2,16(sp)
    80004bac:	69a2                	ld	s3,8(sp)
    80004bae:	6145                	addi	sp,sp,48
    80004bb0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bb2:	0284a983          	lw	s3,40(s1)
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	df6080e7          	jalr	-522(ra) # 800019ac <myproc>
    80004bbe:	5904                	lw	s1,48(a0)
    80004bc0:	413484b3          	sub	s1,s1,s3
    80004bc4:	0014b493          	seqz	s1,s1
    80004bc8:	bfc1                	j	80004b98 <holdingsleep+0x24>

0000000080004bca <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004bca:	1141                	addi	sp,sp,-16
    80004bcc:	e406                	sd	ra,8(sp)
    80004bce:	e022                	sd	s0,0(sp)
    80004bd0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004bd2:	00004597          	auipc	a1,0x4
    80004bd6:	b0658593          	addi	a1,a1,-1274 # 800086d8 <syscalls+0x258>
    80004bda:	0001d517          	auipc	a0,0x1d
    80004bde:	6be50513          	addi	a0,a0,1726 # 80022298 <ftable>
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	f64080e7          	jalr	-156(ra) # 80000b46 <initlock>
}
    80004bea:	60a2                	ld	ra,8(sp)
    80004bec:	6402                	ld	s0,0(sp)
    80004bee:	0141                	addi	sp,sp,16
    80004bf0:	8082                	ret

0000000080004bf2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bf2:	1101                	addi	sp,sp,-32
    80004bf4:	ec06                	sd	ra,24(sp)
    80004bf6:	e822                	sd	s0,16(sp)
    80004bf8:	e426                	sd	s1,8(sp)
    80004bfa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bfc:	0001d517          	auipc	a0,0x1d
    80004c00:	69c50513          	addi	a0,a0,1692 # 80022298 <ftable>
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	fd2080e7          	jalr	-46(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c0c:	0001d497          	auipc	s1,0x1d
    80004c10:	6a448493          	addi	s1,s1,1700 # 800222b0 <ftable+0x18>
    80004c14:	0001e717          	auipc	a4,0x1e
    80004c18:	63c70713          	addi	a4,a4,1596 # 80023250 <disk>
    if(f->ref == 0){
    80004c1c:	40dc                	lw	a5,4(s1)
    80004c1e:	cf99                	beqz	a5,80004c3c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c20:	02848493          	addi	s1,s1,40
    80004c24:	fee49ce3          	bne	s1,a4,80004c1c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c28:	0001d517          	auipc	a0,0x1d
    80004c2c:	67050513          	addi	a0,a0,1648 # 80022298 <ftable>
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	05a080e7          	jalr	90(ra) # 80000c8a <release>
  return 0;
    80004c38:	4481                	li	s1,0
    80004c3a:	a819                	j	80004c50 <filealloc+0x5e>
      f->ref = 1;
    80004c3c:	4785                	li	a5,1
    80004c3e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c40:	0001d517          	auipc	a0,0x1d
    80004c44:	65850513          	addi	a0,a0,1624 # 80022298 <ftable>
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	042080e7          	jalr	66(ra) # 80000c8a <release>
}
    80004c50:	8526                	mv	a0,s1
    80004c52:	60e2                	ld	ra,24(sp)
    80004c54:	6442                	ld	s0,16(sp)
    80004c56:	64a2                	ld	s1,8(sp)
    80004c58:	6105                	addi	sp,sp,32
    80004c5a:	8082                	ret

0000000080004c5c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c5c:	1101                	addi	sp,sp,-32
    80004c5e:	ec06                	sd	ra,24(sp)
    80004c60:	e822                	sd	s0,16(sp)
    80004c62:	e426                	sd	s1,8(sp)
    80004c64:	1000                	addi	s0,sp,32
    80004c66:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c68:	0001d517          	auipc	a0,0x1d
    80004c6c:	63050513          	addi	a0,a0,1584 # 80022298 <ftable>
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	f66080e7          	jalr	-154(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004c78:	40dc                	lw	a5,4(s1)
    80004c7a:	02f05263          	blez	a5,80004c9e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c7e:	2785                	addiw	a5,a5,1
    80004c80:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c82:	0001d517          	auipc	a0,0x1d
    80004c86:	61650513          	addi	a0,a0,1558 # 80022298 <ftable>
    80004c8a:	ffffc097          	auipc	ra,0xffffc
    80004c8e:	000080e7          	jalr	ra # 80000c8a <release>
  return f;
}
    80004c92:	8526                	mv	a0,s1
    80004c94:	60e2                	ld	ra,24(sp)
    80004c96:	6442                	ld	s0,16(sp)
    80004c98:	64a2                	ld	s1,8(sp)
    80004c9a:	6105                	addi	sp,sp,32
    80004c9c:	8082                	ret
    panic("filedup");
    80004c9e:	00004517          	auipc	a0,0x4
    80004ca2:	a4250513          	addi	a0,a0,-1470 # 800086e0 <syscalls+0x260>
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	898080e7          	jalr	-1896(ra) # 8000053e <panic>

0000000080004cae <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004cae:	7139                	addi	sp,sp,-64
    80004cb0:	fc06                	sd	ra,56(sp)
    80004cb2:	f822                	sd	s0,48(sp)
    80004cb4:	f426                	sd	s1,40(sp)
    80004cb6:	f04a                	sd	s2,32(sp)
    80004cb8:	ec4e                	sd	s3,24(sp)
    80004cba:	e852                	sd	s4,16(sp)
    80004cbc:	e456                	sd	s5,8(sp)
    80004cbe:	0080                	addi	s0,sp,64
    80004cc0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004cc2:	0001d517          	auipc	a0,0x1d
    80004cc6:	5d650513          	addi	a0,a0,1494 # 80022298 <ftable>
    80004cca:	ffffc097          	auipc	ra,0xffffc
    80004cce:	f0c080e7          	jalr	-244(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004cd2:	40dc                	lw	a5,4(s1)
    80004cd4:	06f05163          	blez	a5,80004d36 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004cd8:	37fd                	addiw	a5,a5,-1
    80004cda:	0007871b          	sext.w	a4,a5
    80004cde:	c0dc                	sw	a5,4(s1)
    80004ce0:	06e04363          	bgtz	a4,80004d46 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ce4:	0004a903          	lw	s2,0(s1)
    80004ce8:	0094ca83          	lbu	s5,9(s1)
    80004cec:	0104ba03          	ld	s4,16(s1)
    80004cf0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cf4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cf8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cfc:	0001d517          	auipc	a0,0x1d
    80004d00:	59c50513          	addi	a0,a0,1436 # 80022298 <ftable>
    80004d04:	ffffc097          	auipc	ra,0xffffc
    80004d08:	f86080e7          	jalr	-122(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004d0c:	4785                	li	a5,1
    80004d0e:	04f90d63          	beq	s2,a5,80004d68 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d12:	3979                	addiw	s2,s2,-2
    80004d14:	4785                	li	a5,1
    80004d16:	0527e063          	bltu	a5,s2,80004d56 <fileclose+0xa8>
    begin_op();
    80004d1a:	00000097          	auipc	ra,0x0
    80004d1e:	ac8080e7          	jalr	-1336(ra) # 800047e2 <begin_op>
    iput(ff.ip);
    80004d22:	854e                	mv	a0,s3
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	2b6080e7          	jalr	694(ra) # 80003fda <iput>
    end_op();
    80004d2c:	00000097          	auipc	ra,0x0
    80004d30:	b36080e7          	jalr	-1226(ra) # 80004862 <end_op>
    80004d34:	a00d                	j	80004d56 <fileclose+0xa8>
    panic("fileclose");
    80004d36:	00004517          	auipc	a0,0x4
    80004d3a:	9b250513          	addi	a0,a0,-1614 # 800086e8 <syscalls+0x268>
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	800080e7          	jalr	-2048(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d46:	0001d517          	auipc	a0,0x1d
    80004d4a:	55250513          	addi	a0,a0,1362 # 80022298 <ftable>
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	f3c080e7          	jalr	-196(ra) # 80000c8a <release>
  }
}
    80004d56:	70e2                	ld	ra,56(sp)
    80004d58:	7442                	ld	s0,48(sp)
    80004d5a:	74a2                	ld	s1,40(sp)
    80004d5c:	7902                	ld	s2,32(sp)
    80004d5e:	69e2                	ld	s3,24(sp)
    80004d60:	6a42                	ld	s4,16(sp)
    80004d62:	6aa2                	ld	s5,8(sp)
    80004d64:	6121                	addi	sp,sp,64
    80004d66:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d68:	85d6                	mv	a1,s5
    80004d6a:	8552                	mv	a0,s4
    80004d6c:	00000097          	auipc	ra,0x0
    80004d70:	34c080e7          	jalr	844(ra) # 800050b8 <pipeclose>
    80004d74:	b7cd                	j	80004d56 <fileclose+0xa8>

0000000080004d76 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d76:	715d                	addi	sp,sp,-80
    80004d78:	e486                	sd	ra,72(sp)
    80004d7a:	e0a2                	sd	s0,64(sp)
    80004d7c:	fc26                	sd	s1,56(sp)
    80004d7e:	f84a                	sd	s2,48(sp)
    80004d80:	f44e                	sd	s3,40(sp)
    80004d82:	0880                	addi	s0,sp,80
    80004d84:	84aa                	mv	s1,a0
    80004d86:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d88:	ffffd097          	auipc	ra,0xffffd
    80004d8c:	c24080e7          	jalr	-988(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d90:	409c                	lw	a5,0(s1)
    80004d92:	37f9                	addiw	a5,a5,-2
    80004d94:	4705                	li	a4,1
    80004d96:	04f76763          	bltu	a4,a5,80004de4 <filestat+0x6e>
    80004d9a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d9c:	6c88                	ld	a0,24(s1)
    80004d9e:	fffff097          	auipc	ra,0xfffff
    80004da2:	082080e7          	jalr	130(ra) # 80003e20 <ilock>
    stati(f->ip, &st);
    80004da6:	fb840593          	addi	a1,s0,-72
    80004daa:	6c88                	ld	a0,24(s1)
    80004dac:	fffff097          	auipc	ra,0xfffff
    80004db0:	2fe080e7          	jalr	766(ra) # 800040aa <stati>
    iunlock(f->ip);
    80004db4:	6c88                	ld	a0,24(s1)
    80004db6:	fffff097          	auipc	ra,0xfffff
    80004dba:	12c080e7          	jalr	300(ra) # 80003ee2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004dbe:	46e1                	li	a3,24
    80004dc0:	fb840613          	addi	a2,s0,-72
    80004dc4:	85ce                	mv	a1,s3
    80004dc6:	05093503          	ld	a0,80(s2)
    80004dca:	ffffd097          	auipc	ra,0xffffd
    80004dce:	89e080e7          	jalr	-1890(ra) # 80001668 <copyout>
    80004dd2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004dd6:	60a6                	ld	ra,72(sp)
    80004dd8:	6406                	ld	s0,64(sp)
    80004dda:	74e2                	ld	s1,56(sp)
    80004ddc:	7942                	ld	s2,48(sp)
    80004dde:	79a2                	ld	s3,40(sp)
    80004de0:	6161                	addi	sp,sp,80
    80004de2:	8082                	ret
  return -1;
    80004de4:	557d                	li	a0,-1
    80004de6:	bfc5                	j	80004dd6 <filestat+0x60>

0000000080004de8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004de8:	7179                	addi	sp,sp,-48
    80004dea:	f406                	sd	ra,40(sp)
    80004dec:	f022                	sd	s0,32(sp)
    80004dee:	ec26                	sd	s1,24(sp)
    80004df0:	e84a                	sd	s2,16(sp)
    80004df2:	e44e                	sd	s3,8(sp)
    80004df4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004df6:	00854783          	lbu	a5,8(a0)
    80004dfa:	c3d5                	beqz	a5,80004e9e <fileread+0xb6>
    80004dfc:	84aa                	mv	s1,a0
    80004dfe:	89ae                	mv	s3,a1
    80004e00:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e02:	411c                	lw	a5,0(a0)
    80004e04:	4705                	li	a4,1
    80004e06:	04e78963          	beq	a5,a4,80004e58 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e0a:	470d                	li	a4,3
    80004e0c:	04e78d63          	beq	a5,a4,80004e66 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e10:	4709                	li	a4,2
    80004e12:	06e79e63          	bne	a5,a4,80004e8e <fileread+0xa6>
    ilock(f->ip);
    80004e16:	6d08                	ld	a0,24(a0)
    80004e18:	fffff097          	auipc	ra,0xfffff
    80004e1c:	008080e7          	jalr	8(ra) # 80003e20 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e20:	874a                	mv	a4,s2
    80004e22:	5094                	lw	a3,32(s1)
    80004e24:	864e                	mv	a2,s3
    80004e26:	4585                	li	a1,1
    80004e28:	6c88                	ld	a0,24(s1)
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	2aa080e7          	jalr	682(ra) # 800040d4 <readi>
    80004e32:	892a                	mv	s2,a0
    80004e34:	00a05563          	blez	a0,80004e3e <fileread+0x56>
      f->off += r;
    80004e38:	509c                	lw	a5,32(s1)
    80004e3a:	9fa9                	addw	a5,a5,a0
    80004e3c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e3e:	6c88                	ld	a0,24(s1)
    80004e40:	fffff097          	auipc	ra,0xfffff
    80004e44:	0a2080e7          	jalr	162(ra) # 80003ee2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e48:	854a                	mv	a0,s2
    80004e4a:	70a2                	ld	ra,40(sp)
    80004e4c:	7402                	ld	s0,32(sp)
    80004e4e:	64e2                	ld	s1,24(sp)
    80004e50:	6942                	ld	s2,16(sp)
    80004e52:	69a2                	ld	s3,8(sp)
    80004e54:	6145                	addi	sp,sp,48
    80004e56:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e58:	6908                	ld	a0,16(a0)
    80004e5a:	00000097          	auipc	ra,0x0
    80004e5e:	3c6080e7          	jalr	966(ra) # 80005220 <piperead>
    80004e62:	892a                	mv	s2,a0
    80004e64:	b7d5                	j	80004e48 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e66:	02451783          	lh	a5,36(a0)
    80004e6a:	03079693          	slli	a3,a5,0x30
    80004e6e:	92c1                	srli	a3,a3,0x30
    80004e70:	4725                	li	a4,9
    80004e72:	02d76863          	bltu	a4,a3,80004ea2 <fileread+0xba>
    80004e76:	0792                	slli	a5,a5,0x4
    80004e78:	0001d717          	auipc	a4,0x1d
    80004e7c:	38070713          	addi	a4,a4,896 # 800221f8 <devsw>
    80004e80:	97ba                	add	a5,a5,a4
    80004e82:	639c                	ld	a5,0(a5)
    80004e84:	c38d                	beqz	a5,80004ea6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e86:	4505                	li	a0,1
    80004e88:	9782                	jalr	a5
    80004e8a:	892a                	mv	s2,a0
    80004e8c:	bf75                	j	80004e48 <fileread+0x60>
    panic("fileread");
    80004e8e:	00004517          	auipc	a0,0x4
    80004e92:	86a50513          	addi	a0,a0,-1942 # 800086f8 <syscalls+0x278>
    80004e96:	ffffb097          	auipc	ra,0xffffb
    80004e9a:	6a8080e7          	jalr	1704(ra) # 8000053e <panic>
    return -1;
    80004e9e:	597d                	li	s2,-1
    80004ea0:	b765                	j	80004e48 <fileread+0x60>
      return -1;
    80004ea2:	597d                	li	s2,-1
    80004ea4:	b755                	j	80004e48 <fileread+0x60>
    80004ea6:	597d                	li	s2,-1
    80004ea8:	b745                	j	80004e48 <fileread+0x60>

0000000080004eaa <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004eaa:	715d                	addi	sp,sp,-80
    80004eac:	e486                	sd	ra,72(sp)
    80004eae:	e0a2                	sd	s0,64(sp)
    80004eb0:	fc26                	sd	s1,56(sp)
    80004eb2:	f84a                	sd	s2,48(sp)
    80004eb4:	f44e                	sd	s3,40(sp)
    80004eb6:	f052                	sd	s4,32(sp)
    80004eb8:	ec56                	sd	s5,24(sp)
    80004eba:	e85a                	sd	s6,16(sp)
    80004ebc:	e45e                	sd	s7,8(sp)
    80004ebe:	e062                	sd	s8,0(sp)
    80004ec0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ec2:	00954783          	lbu	a5,9(a0)
    80004ec6:	10078663          	beqz	a5,80004fd2 <filewrite+0x128>
    80004eca:	892a                	mv	s2,a0
    80004ecc:	8aae                	mv	s5,a1
    80004ece:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ed0:	411c                	lw	a5,0(a0)
    80004ed2:	4705                	li	a4,1
    80004ed4:	02e78263          	beq	a5,a4,80004ef8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ed8:	470d                	li	a4,3
    80004eda:	02e78663          	beq	a5,a4,80004f06 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ede:	4709                	li	a4,2
    80004ee0:	0ee79163          	bne	a5,a4,80004fc2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ee4:	0ac05d63          	blez	a2,80004f9e <filewrite+0xf4>
    int i = 0;
    80004ee8:	4981                	li	s3,0
    80004eea:	6b05                	lui	s6,0x1
    80004eec:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004ef0:	6b85                	lui	s7,0x1
    80004ef2:	c00b8b9b          	addiw	s7,s7,-1024
    80004ef6:	a861                	j	80004f8e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ef8:	6908                	ld	a0,16(a0)
    80004efa:	00000097          	auipc	ra,0x0
    80004efe:	22e080e7          	jalr	558(ra) # 80005128 <pipewrite>
    80004f02:	8a2a                	mv	s4,a0
    80004f04:	a045                	j	80004fa4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f06:	02451783          	lh	a5,36(a0)
    80004f0a:	03079693          	slli	a3,a5,0x30
    80004f0e:	92c1                	srli	a3,a3,0x30
    80004f10:	4725                	li	a4,9
    80004f12:	0cd76263          	bltu	a4,a3,80004fd6 <filewrite+0x12c>
    80004f16:	0792                	slli	a5,a5,0x4
    80004f18:	0001d717          	auipc	a4,0x1d
    80004f1c:	2e070713          	addi	a4,a4,736 # 800221f8 <devsw>
    80004f20:	97ba                	add	a5,a5,a4
    80004f22:	679c                	ld	a5,8(a5)
    80004f24:	cbdd                	beqz	a5,80004fda <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f26:	4505                	li	a0,1
    80004f28:	9782                	jalr	a5
    80004f2a:	8a2a                	mv	s4,a0
    80004f2c:	a8a5                	j	80004fa4 <filewrite+0xfa>
    80004f2e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f32:	00000097          	auipc	ra,0x0
    80004f36:	8b0080e7          	jalr	-1872(ra) # 800047e2 <begin_op>
      ilock(f->ip);
    80004f3a:	01893503          	ld	a0,24(s2)
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	ee2080e7          	jalr	-286(ra) # 80003e20 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f46:	8762                	mv	a4,s8
    80004f48:	02092683          	lw	a3,32(s2)
    80004f4c:	01598633          	add	a2,s3,s5
    80004f50:	4585                	li	a1,1
    80004f52:	01893503          	ld	a0,24(s2)
    80004f56:	fffff097          	auipc	ra,0xfffff
    80004f5a:	276080e7          	jalr	630(ra) # 800041cc <writei>
    80004f5e:	84aa                	mv	s1,a0
    80004f60:	00a05763          	blez	a0,80004f6e <filewrite+0xc4>
        f->off += r;
    80004f64:	02092783          	lw	a5,32(s2)
    80004f68:	9fa9                	addw	a5,a5,a0
    80004f6a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f6e:	01893503          	ld	a0,24(s2)
    80004f72:	fffff097          	auipc	ra,0xfffff
    80004f76:	f70080e7          	jalr	-144(ra) # 80003ee2 <iunlock>
      end_op();
    80004f7a:	00000097          	auipc	ra,0x0
    80004f7e:	8e8080e7          	jalr	-1816(ra) # 80004862 <end_op>

      if(r != n1){
    80004f82:	009c1f63          	bne	s8,s1,80004fa0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f86:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f8a:	0149db63          	bge	s3,s4,80004fa0 <filewrite+0xf6>
      int n1 = n - i;
    80004f8e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f92:	84be                	mv	s1,a5
    80004f94:	2781                	sext.w	a5,a5
    80004f96:	f8fb5ce3          	bge	s6,a5,80004f2e <filewrite+0x84>
    80004f9a:	84de                	mv	s1,s7
    80004f9c:	bf49                	j	80004f2e <filewrite+0x84>
    int i = 0;
    80004f9e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fa0:	013a1f63          	bne	s4,s3,80004fbe <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fa4:	8552                	mv	a0,s4
    80004fa6:	60a6                	ld	ra,72(sp)
    80004fa8:	6406                	ld	s0,64(sp)
    80004faa:	74e2                	ld	s1,56(sp)
    80004fac:	7942                	ld	s2,48(sp)
    80004fae:	79a2                	ld	s3,40(sp)
    80004fb0:	7a02                	ld	s4,32(sp)
    80004fb2:	6ae2                	ld	s5,24(sp)
    80004fb4:	6b42                	ld	s6,16(sp)
    80004fb6:	6ba2                	ld	s7,8(sp)
    80004fb8:	6c02                	ld	s8,0(sp)
    80004fba:	6161                	addi	sp,sp,80
    80004fbc:	8082                	ret
    ret = (i == n ? n : -1);
    80004fbe:	5a7d                	li	s4,-1
    80004fc0:	b7d5                	j	80004fa4 <filewrite+0xfa>
    panic("filewrite");
    80004fc2:	00003517          	auipc	a0,0x3
    80004fc6:	74650513          	addi	a0,a0,1862 # 80008708 <syscalls+0x288>
    80004fca:	ffffb097          	auipc	ra,0xffffb
    80004fce:	574080e7          	jalr	1396(ra) # 8000053e <panic>
    return -1;
    80004fd2:	5a7d                	li	s4,-1
    80004fd4:	bfc1                	j	80004fa4 <filewrite+0xfa>
      return -1;
    80004fd6:	5a7d                	li	s4,-1
    80004fd8:	b7f1                	j	80004fa4 <filewrite+0xfa>
    80004fda:	5a7d                	li	s4,-1
    80004fdc:	b7e1                	j	80004fa4 <filewrite+0xfa>

0000000080004fde <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004fde:	7179                	addi	sp,sp,-48
    80004fe0:	f406                	sd	ra,40(sp)
    80004fe2:	f022                	sd	s0,32(sp)
    80004fe4:	ec26                	sd	s1,24(sp)
    80004fe6:	e84a                	sd	s2,16(sp)
    80004fe8:	e44e                	sd	s3,8(sp)
    80004fea:	e052                	sd	s4,0(sp)
    80004fec:	1800                	addi	s0,sp,48
    80004fee:	84aa                	mv	s1,a0
    80004ff0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ff2:	0005b023          	sd	zero,0(a1)
    80004ff6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ffa:	00000097          	auipc	ra,0x0
    80004ffe:	bf8080e7          	jalr	-1032(ra) # 80004bf2 <filealloc>
    80005002:	e088                	sd	a0,0(s1)
    80005004:	c551                	beqz	a0,80005090 <pipealloc+0xb2>
    80005006:	00000097          	auipc	ra,0x0
    8000500a:	bec080e7          	jalr	-1044(ra) # 80004bf2 <filealloc>
    8000500e:	00aa3023          	sd	a0,0(s4)
    80005012:	c92d                	beqz	a0,80005084 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	ad2080e7          	jalr	-1326(ra) # 80000ae6 <kalloc>
    8000501c:	892a                	mv	s2,a0
    8000501e:	c125                	beqz	a0,8000507e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005020:	4985                	li	s3,1
    80005022:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005026:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000502a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000502e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005032:	00003597          	auipc	a1,0x3
    80005036:	6e658593          	addi	a1,a1,1766 # 80008718 <syscalls+0x298>
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	b0c080e7          	jalr	-1268(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80005042:	609c                	ld	a5,0(s1)
    80005044:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005048:	609c                	ld	a5,0(s1)
    8000504a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000504e:	609c                	ld	a5,0(s1)
    80005050:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005054:	609c                	ld	a5,0(s1)
    80005056:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000505a:	000a3783          	ld	a5,0(s4)
    8000505e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005062:	000a3783          	ld	a5,0(s4)
    80005066:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000506a:	000a3783          	ld	a5,0(s4)
    8000506e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005072:	000a3783          	ld	a5,0(s4)
    80005076:	0127b823          	sd	s2,16(a5)
  return 0;
    8000507a:	4501                	li	a0,0
    8000507c:	a025                	j	800050a4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000507e:	6088                	ld	a0,0(s1)
    80005080:	e501                	bnez	a0,80005088 <pipealloc+0xaa>
    80005082:	a039                	j	80005090 <pipealloc+0xb2>
    80005084:	6088                	ld	a0,0(s1)
    80005086:	c51d                	beqz	a0,800050b4 <pipealloc+0xd6>
    fileclose(*f0);
    80005088:	00000097          	auipc	ra,0x0
    8000508c:	c26080e7          	jalr	-986(ra) # 80004cae <fileclose>
  if(*f1)
    80005090:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005094:	557d                	li	a0,-1
  if(*f1)
    80005096:	c799                	beqz	a5,800050a4 <pipealloc+0xc6>
    fileclose(*f1);
    80005098:	853e                	mv	a0,a5
    8000509a:	00000097          	auipc	ra,0x0
    8000509e:	c14080e7          	jalr	-1004(ra) # 80004cae <fileclose>
  return -1;
    800050a2:	557d                	li	a0,-1
}
    800050a4:	70a2                	ld	ra,40(sp)
    800050a6:	7402                	ld	s0,32(sp)
    800050a8:	64e2                	ld	s1,24(sp)
    800050aa:	6942                	ld	s2,16(sp)
    800050ac:	69a2                	ld	s3,8(sp)
    800050ae:	6a02                	ld	s4,0(sp)
    800050b0:	6145                	addi	sp,sp,48
    800050b2:	8082                	ret
  return -1;
    800050b4:	557d                	li	a0,-1
    800050b6:	b7fd                	j	800050a4 <pipealloc+0xc6>

00000000800050b8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050b8:	1101                	addi	sp,sp,-32
    800050ba:	ec06                	sd	ra,24(sp)
    800050bc:	e822                	sd	s0,16(sp)
    800050be:	e426                	sd	s1,8(sp)
    800050c0:	e04a                	sd	s2,0(sp)
    800050c2:	1000                	addi	s0,sp,32
    800050c4:	84aa                	mv	s1,a0
    800050c6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800050c8:	ffffc097          	auipc	ra,0xffffc
    800050cc:	b0e080e7          	jalr	-1266(ra) # 80000bd6 <acquire>
  if(writable){
    800050d0:	02090d63          	beqz	s2,8000510a <pipeclose+0x52>
    pi->writeopen = 0;
    800050d4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800050d8:	21848513          	addi	a0,s1,536
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	2dc080e7          	jalr	732(ra) # 800023b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050e4:	2204b783          	ld	a5,544(s1)
    800050e8:	eb95                	bnez	a5,8000511c <pipeclose+0x64>
    release(&pi->lock);
    800050ea:	8526                	mv	a0,s1
    800050ec:	ffffc097          	auipc	ra,0xffffc
    800050f0:	b9e080e7          	jalr	-1122(ra) # 80000c8a <release>
    kfree((char*)pi);
    800050f4:	8526                	mv	a0,s1
    800050f6:	ffffc097          	auipc	ra,0xffffc
    800050fa:	8f4080e7          	jalr	-1804(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800050fe:	60e2                	ld	ra,24(sp)
    80005100:	6442                	ld	s0,16(sp)
    80005102:	64a2                	ld	s1,8(sp)
    80005104:	6902                	ld	s2,0(sp)
    80005106:	6105                	addi	sp,sp,32
    80005108:	8082                	ret
    pi->readopen = 0;
    8000510a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000510e:	21c48513          	addi	a0,s1,540
    80005112:	ffffd097          	auipc	ra,0xffffd
    80005116:	2a6080e7          	jalr	678(ra) # 800023b8 <wakeup>
    8000511a:	b7e9                	j	800050e4 <pipeclose+0x2c>
    release(&pi->lock);
    8000511c:	8526                	mv	a0,s1
    8000511e:	ffffc097          	auipc	ra,0xffffc
    80005122:	b6c080e7          	jalr	-1172(ra) # 80000c8a <release>
}
    80005126:	bfe1                	j	800050fe <pipeclose+0x46>

0000000080005128 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005128:	711d                	addi	sp,sp,-96
    8000512a:	ec86                	sd	ra,88(sp)
    8000512c:	e8a2                	sd	s0,80(sp)
    8000512e:	e4a6                	sd	s1,72(sp)
    80005130:	e0ca                	sd	s2,64(sp)
    80005132:	fc4e                	sd	s3,56(sp)
    80005134:	f852                	sd	s4,48(sp)
    80005136:	f456                	sd	s5,40(sp)
    80005138:	f05a                	sd	s6,32(sp)
    8000513a:	ec5e                	sd	s7,24(sp)
    8000513c:	e862                	sd	s8,16(sp)
    8000513e:	1080                	addi	s0,sp,96
    80005140:	84aa                	mv	s1,a0
    80005142:	8aae                	mv	s5,a1
    80005144:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005146:	ffffd097          	auipc	ra,0xffffd
    8000514a:	866080e7          	jalr	-1946(ra) # 800019ac <myproc>
    8000514e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005150:	8526                	mv	a0,s1
    80005152:	ffffc097          	auipc	ra,0xffffc
    80005156:	a84080e7          	jalr	-1404(ra) # 80000bd6 <acquire>
  while(i < n){
    8000515a:	0b405663          	blez	s4,80005206 <pipewrite+0xde>
  int i = 0;
    8000515e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005160:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005162:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005166:	21c48b93          	addi	s7,s1,540
    8000516a:	a089                	j	800051ac <pipewrite+0x84>
      release(&pi->lock);
    8000516c:	8526                	mv	a0,s1
    8000516e:	ffffc097          	auipc	ra,0xffffc
    80005172:	b1c080e7          	jalr	-1252(ra) # 80000c8a <release>
      return -1;
    80005176:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005178:	854a                	mv	a0,s2
    8000517a:	60e6                	ld	ra,88(sp)
    8000517c:	6446                	ld	s0,80(sp)
    8000517e:	64a6                	ld	s1,72(sp)
    80005180:	6906                	ld	s2,64(sp)
    80005182:	79e2                	ld	s3,56(sp)
    80005184:	7a42                	ld	s4,48(sp)
    80005186:	7aa2                	ld	s5,40(sp)
    80005188:	7b02                	ld	s6,32(sp)
    8000518a:	6be2                	ld	s7,24(sp)
    8000518c:	6c42                	ld	s8,16(sp)
    8000518e:	6125                	addi	sp,sp,96
    80005190:	8082                	ret
      wakeup(&pi->nread);
    80005192:	8562                	mv	a0,s8
    80005194:	ffffd097          	auipc	ra,0xffffd
    80005198:	224080e7          	jalr	548(ra) # 800023b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000519c:	85a6                	mv	a1,s1
    8000519e:	855e                	mv	a0,s7
    800051a0:	ffffd097          	auipc	ra,0xffffd
    800051a4:	1b4080e7          	jalr	436(ra) # 80002354 <sleep>
  while(i < n){
    800051a8:	07495063          	bge	s2,s4,80005208 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800051ac:	2204a783          	lw	a5,544(s1)
    800051b0:	dfd5                	beqz	a5,8000516c <pipewrite+0x44>
    800051b2:	854e                	mv	a0,s3
    800051b4:	ffffd097          	auipc	ra,0xffffd
    800051b8:	454080e7          	jalr	1108(ra) # 80002608 <killed>
    800051bc:	f945                	bnez	a0,8000516c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800051be:	2184a783          	lw	a5,536(s1)
    800051c2:	21c4a703          	lw	a4,540(s1)
    800051c6:	2007879b          	addiw	a5,a5,512
    800051ca:	fcf704e3          	beq	a4,a5,80005192 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051ce:	4685                	li	a3,1
    800051d0:	01590633          	add	a2,s2,s5
    800051d4:	faf40593          	addi	a1,s0,-81
    800051d8:	0509b503          	ld	a0,80(s3)
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	518080e7          	jalr	1304(ra) # 800016f4 <copyin>
    800051e4:	03650263          	beq	a0,s6,80005208 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051e8:	21c4a783          	lw	a5,540(s1)
    800051ec:	0017871b          	addiw	a4,a5,1
    800051f0:	20e4ae23          	sw	a4,540(s1)
    800051f4:	1ff7f793          	andi	a5,a5,511
    800051f8:	97a6                	add	a5,a5,s1
    800051fa:	faf44703          	lbu	a4,-81(s0)
    800051fe:	00e78c23          	sb	a4,24(a5)
      i++;
    80005202:	2905                	addiw	s2,s2,1
    80005204:	b755                	j	800051a8 <pipewrite+0x80>
  int i = 0;
    80005206:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005208:	21848513          	addi	a0,s1,536
    8000520c:	ffffd097          	auipc	ra,0xffffd
    80005210:	1ac080e7          	jalr	428(ra) # 800023b8 <wakeup>
  release(&pi->lock);
    80005214:	8526                	mv	a0,s1
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	a74080e7          	jalr	-1420(ra) # 80000c8a <release>
  return i;
    8000521e:	bfa9                	j	80005178 <pipewrite+0x50>

0000000080005220 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005220:	715d                	addi	sp,sp,-80
    80005222:	e486                	sd	ra,72(sp)
    80005224:	e0a2                	sd	s0,64(sp)
    80005226:	fc26                	sd	s1,56(sp)
    80005228:	f84a                	sd	s2,48(sp)
    8000522a:	f44e                	sd	s3,40(sp)
    8000522c:	f052                	sd	s4,32(sp)
    8000522e:	ec56                	sd	s5,24(sp)
    80005230:	e85a                	sd	s6,16(sp)
    80005232:	0880                	addi	s0,sp,80
    80005234:	84aa                	mv	s1,a0
    80005236:	892e                	mv	s2,a1
    80005238:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000523a:	ffffc097          	auipc	ra,0xffffc
    8000523e:	772080e7          	jalr	1906(ra) # 800019ac <myproc>
    80005242:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005244:	8526                	mv	a0,s1
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	990080e7          	jalr	-1648(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000524e:	2184a703          	lw	a4,536(s1)
    80005252:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005256:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000525a:	02f71763          	bne	a4,a5,80005288 <piperead+0x68>
    8000525e:	2244a783          	lw	a5,548(s1)
    80005262:	c39d                	beqz	a5,80005288 <piperead+0x68>
    if(killed(pr)){
    80005264:	8552                	mv	a0,s4
    80005266:	ffffd097          	auipc	ra,0xffffd
    8000526a:	3a2080e7          	jalr	930(ra) # 80002608 <killed>
    8000526e:	e941                	bnez	a0,800052fe <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005270:	85a6                	mv	a1,s1
    80005272:	854e                	mv	a0,s3
    80005274:	ffffd097          	auipc	ra,0xffffd
    80005278:	0e0080e7          	jalr	224(ra) # 80002354 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000527c:	2184a703          	lw	a4,536(s1)
    80005280:	21c4a783          	lw	a5,540(s1)
    80005284:	fcf70de3          	beq	a4,a5,8000525e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005288:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000528a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000528c:	05505363          	blez	s5,800052d2 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005290:	2184a783          	lw	a5,536(s1)
    80005294:	21c4a703          	lw	a4,540(s1)
    80005298:	02f70d63          	beq	a4,a5,800052d2 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000529c:	0017871b          	addiw	a4,a5,1
    800052a0:	20e4ac23          	sw	a4,536(s1)
    800052a4:	1ff7f793          	andi	a5,a5,511
    800052a8:	97a6                	add	a5,a5,s1
    800052aa:	0187c783          	lbu	a5,24(a5)
    800052ae:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052b2:	4685                	li	a3,1
    800052b4:	fbf40613          	addi	a2,s0,-65
    800052b8:	85ca                	mv	a1,s2
    800052ba:	050a3503          	ld	a0,80(s4)
    800052be:	ffffc097          	auipc	ra,0xffffc
    800052c2:	3aa080e7          	jalr	938(ra) # 80001668 <copyout>
    800052c6:	01650663          	beq	a0,s6,800052d2 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052ca:	2985                	addiw	s3,s3,1
    800052cc:	0905                	addi	s2,s2,1
    800052ce:	fd3a91e3          	bne	s5,s3,80005290 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800052d2:	21c48513          	addi	a0,s1,540
    800052d6:	ffffd097          	auipc	ra,0xffffd
    800052da:	0e2080e7          	jalr	226(ra) # 800023b8 <wakeup>
  release(&pi->lock);
    800052de:	8526                	mv	a0,s1
    800052e0:	ffffc097          	auipc	ra,0xffffc
    800052e4:	9aa080e7          	jalr	-1622(ra) # 80000c8a <release>
  return i;
}
    800052e8:	854e                	mv	a0,s3
    800052ea:	60a6                	ld	ra,72(sp)
    800052ec:	6406                	ld	s0,64(sp)
    800052ee:	74e2                	ld	s1,56(sp)
    800052f0:	7942                	ld	s2,48(sp)
    800052f2:	79a2                	ld	s3,40(sp)
    800052f4:	7a02                	ld	s4,32(sp)
    800052f6:	6ae2                	ld	s5,24(sp)
    800052f8:	6b42                	ld	s6,16(sp)
    800052fa:	6161                	addi	sp,sp,80
    800052fc:	8082                	ret
      release(&pi->lock);
    800052fe:	8526                	mv	a0,s1
    80005300:	ffffc097          	auipc	ra,0xffffc
    80005304:	98a080e7          	jalr	-1654(ra) # 80000c8a <release>
      return -1;
    80005308:	59fd                	li	s3,-1
    8000530a:	bff9                	j	800052e8 <piperead+0xc8>

000000008000530c <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000530c:	1141                	addi	sp,sp,-16
    8000530e:	e422                	sd	s0,8(sp)
    80005310:	0800                	addi	s0,sp,16
    80005312:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005314:	8905                	andi	a0,a0,1
    80005316:	c111                	beqz	a0,8000531a <flags2perm+0xe>
      perm = PTE_X;
    80005318:	4521                	li	a0,8
    if(flags & 0x2)
    8000531a:	8b89                	andi	a5,a5,2
    8000531c:	c399                	beqz	a5,80005322 <flags2perm+0x16>
      perm |= PTE_W;
    8000531e:	00456513          	ori	a0,a0,4
    return perm;
}
    80005322:	6422                	ld	s0,8(sp)
    80005324:	0141                	addi	sp,sp,16
    80005326:	8082                	ret

0000000080005328 <exec>:

int
exec(char *path, char **argv)
{
    80005328:	de010113          	addi	sp,sp,-544
    8000532c:	20113c23          	sd	ra,536(sp)
    80005330:	20813823          	sd	s0,528(sp)
    80005334:	20913423          	sd	s1,520(sp)
    80005338:	21213023          	sd	s2,512(sp)
    8000533c:	ffce                	sd	s3,504(sp)
    8000533e:	fbd2                	sd	s4,496(sp)
    80005340:	f7d6                	sd	s5,488(sp)
    80005342:	f3da                	sd	s6,480(sp)
    80005344:	efde                	sd	s7,472(sp)
    80005346:	ebe2                	sd	s8,464(sp)
    80005348:	e7e6                	sd	s9,456(sp)
    8000534a:	e3ea                	sd	s10,448(sp)
    8000534c:	ff6e                	sd	s11,440(sp)
    8000534e:	1400                	addi	s0,sp,544
    80005350:	892a                	mv	s2,a0
    80005352:	dea43423          	sd	a0,-536(s0)
    80005356:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000535a:	ffffc097          	auipc	ra,0xffffc
    8000535e:	652080e7          	jalr	1618(ra) # 800019ac <myproc>
    80005362:	84aa                	mv	s1,a0

  begin_op();
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	47e080e7          	jalr	1150(ra) # 800047e2 <begin_op>

  if((ip = namei(path)) == 0){
    8000536c:	854a                	mv	a0,s2
    8000536e:	fffff097          	auipc	ra,0xfffff
    80005372:	258080e7          	jalr	600(ra) # 800045c6 <namei>
    80005376:	c93d                	beqz	a0,800053ec <exec+0xc4>
    80005378:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	aa6080e7          	jalr	-1370(ra) # 80003e20 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005382:	04000713          	li	a4,64
    80005386:	4681                	li	a3,0
    80005388:	e5040613          	addi	a2,s0,-432
    8000538c:	4581                	li	a1,0
    8000538e:	8556                	mv	a0,s5
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	d44080e7          	jalr	-700(ra) # 800040d4 <readi>
    80005398:	04000793          	li	a5,64
    8000539c:	00f51a63          	bne	a0,a5,800053b0 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800053a0:	e5042703          	lw	a4,-432(s0)
    800053a4:	464c47b7          	lui	a5,0x464c4
    800053a8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053ac:	04f70663          	beq	a4,a5,800053f8 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053b0:	8556                	mv	a0,s5
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	cd0080e7          	jalr	-816(ra) # 80004082 <iunlockput>
    end_op();
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	4a8080e7          	jalr	1192(ra) # 80004862 <end_op>
  }
  return -1;
    800053c2:	557d                	li	a0,-1
}
    800053c4:	21813083          	ld	ra,536(sp)
    800053c8:	21013403          	ld	s0,528(sp)
    800053cc:	20813483          	ld	s1,520(sp)
    800053d0:	20013903          	ld	s2,512(sp)
    800053d4:	79fe                	ld	s3,504(sp)
    800053d6:	7a5e                	ld	s4,496(sp)
    800053d8:	7abe                	ld	s5,488(sp)
    800053da:	7b1e                	ld	s6,480(sp)
    800053dc:	6bfe                	ld	s7,472(sp)
    800053de:	6c5e                	ld	s8,464(sp)
    800053e0:	6cbe                	ld	s9,456(sp)
    800053e2:	6d1e                	ld	s10,448(sp)
    800053e4:	7dfa                	ld	s11,440(sp)
    800053e6:	22010113          	addi	sp,sp,544
    800053ea:	8082                	ret
    end_op();
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	476080e7          	jalr	1142(ra) # 80004862 <end_op>
    return -1;
    800053f4:	557d                	li	a0,-1
    800053f6:	b7f9                	j	800053c4 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800053f8:	8526                	mv	a0,s1
    800053fa:	ffffc097          	auipc	ra,0xffffc
    800053fe:	676080e7          	jalr	1654(ra) # 80001a70 <proc_pagetable>
    80005402:	8b2a                	mv	s6,a0
    80005404:	d555                	beqz	a0,800053b0 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005406:	e7042783          	lw	a5,-400(s0)
    8000540a:	e8845703          	lhu	a4,-376(s0)
    8000540e:	c735                	beqz	a4,8000547a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005410:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005412:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005416:	6a05                	lui	s4,0x1
    80005418:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000541c:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005420:	6d85                	lui	s11,0x1
    80005422:	7d7d                	lui	s10,0xfffff
    80005424:	a481                	j	80005664 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005426:	00003517          	auipc	a0,0x3
    8000542a:	2fa50513          	addi	a0,a0,762 # 80008720 <syscalls+0x2a0>
    8000542e:	ffffb097          	auipc	ra,0xffffb
    80005432:	110080e7          	jalr	272(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005436:	874a                	mv	a4,s2
    80005438:	009c86bb          	addw	a3,s9,s1
    8000543c:	4581                	li	a1,0
    8000543e:	8556                	mv	a0,s5
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	c94080e7          	jalr	-876(ra) # 800040d4 <readi>
    80005448:	2501                	sext.w	a0,a0
    8000544a:	1aa91a63          	bne	s2,a0,800055fe <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    8000544e:	009d84bb          	addw	s1,s11,s1
    80005452:	013d09bb          	addw	s3,s10,s3
    80005456:	1f74f763          	bgeu	s1,s7,80005644 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    8000545a:	02049593          	slli	a1,s1,0x20
    8000545e:	9181                	srli	a1,a1,0x20
    80005460:	95e2                	add	a1,a1,s8
    80005462:	855a                	mv	a0,s6
    80005464:	ffffc097          	auipc	ra,0xffffc
    80005468:	bf8080e7          	jalr	-1032(ra) # 8000105c <walkaddr>
    8000546c:	862a                	mv	a2,a0
    if(pa == 0)
    8000546e:	dd45                	beqz	a0,80005426 <exec+0xfe>
      n = PGSIZE;
    80005470:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005472:	fd49f2e3          	bgeu	s3,s4,80005436 <exec+0x10e>
      n = sz - i;
    80005476:	894e                	mv	s2,s3
    80005478:	bf7d                	j	80005436 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000547a:	4901                	li	s2,0
  iunlockput(ip);
    8000547c:	8556                	mv	a0,s5
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	c04080e7          	jalr	-1020(ra) # 80004082 <iunlockput>
  end_op();
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	3dc080e7          	jalr	988(ra) # 80004862 <end_op>
  p = myproc();
    8000548e:	ffffc097          	auipc	ra,0xffffc
    80005492:	51e080e7          	jalr	1310(ra) # 800019ac <myproc>
    80005496:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005498:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000549c:	6785                	lui	a5,0x1
    8000549e:	17fd                	addi	a5,a5,-1
    800054a0:	993e                	add	s2,s2,a5
    800054a2:	77fd                	lui	a5,0xfffff
    800054a4:	00f977b3          	and	a5,s2,a5
    800054a8:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054ac:	4691                	li	a3,4
    800054ae:	6609                	lui	a2,0x2
    800054b0:	963e                	add	a2,a2,a5
    800054b2:	85be                	mv	a1,a5
    800054b4:	855a                	mv	a0,s6
    800054b6:	ffffc097          	auipc	ra,0xffffc
    800054ba:	f5a080e7          	jalr	-166(ra) # 80001410 <uvmalloc>
    800054be:	8c2a                	mv	s8,a0
  ip = 0;
    800054c0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054c2:	12050e63          	beqz	a0,800055fe <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054c6:	75f9                	lui	a1,0xffffe
    800054c8:	95aa                	add	a1,a1,a0
    800054ca:	855a                	mv	a0,s6
    800054cc:	ffffc097          	auipc	ra,0xffffc
    800054d0:	16a080e7          	jalr	362(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    800054d4:	7afd                	lui	s5,0xfffff
    800054d6:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800054d8:	df043783          	ld	a5,-528(s0)
    800054dc:	6388                	ld	a0,0(a5)
    800054de:	c925                	beqz	a0,8000554e <exec+0x226>
    800054e0:	e9040993          	addi	s3,s0,-368
    800054e4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800054e8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800054ea:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800054ec:	ffffc097          	auipc	ra,0xffffc
    800054f0:	962080e7          	jalr	-1694(ra) # 80000e4e <strlen>
    800054f4:	0015079b          	addiw	a5,a0,1
    800054f8:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054fc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005500:	13596663          	bltu	s2,s5,8000562c <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005504:	df043d83          	ld	s11,-528(s0)
    80005508:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000550c:	8552                	mv	a0,s4
    8000550e:	ffffc097          	auipc	ra,0xffffc
    80005512:	940080e7          	jalr	-1728(ra) # 80000e4e <strlen>
    80005516:	0015069b          	addiw	a3,a0,1
    8000551a:	8652                	mv	a2,s4
    8000551c:	85ca                	mv	a1,s2
    8000551e:	855a                	mv	a0,s6
    80005520:	ffffc097          	auipc	ra,0xffffc
    80005524:	148080e7          	jalr	328(ra) # 80001668 <copyout>
    80005528:	10054663          	bltz	a0,80005634 <exec+0x30c>
    ustack[argc] = sp;
    8000552c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005530:	0485                	addi	s1,s1,1
    80005532:	008d8793          	addi	a5,s11,8
    80005536:	def43823          	sd	a5,-528(s0)
    8000553a:	008db503          	ld	a0,8(s11)
    8000553e:	c911                	beqz	a0,80005552 <exec+0x22a>
    if(argc >= MAXARG)
    80005540:	09a1                	addi	s3,s3,8
    80005542:	fb3c95e3          	bne	s9,s3,800054ec <exec+0x1c4>
  sz = sz1;
    80005546:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000554a:	4a81                	li	s5,0
    8000554c:	a84d                	j	800055fe <exec+0x2d6>
  sp = sz;
    8000554e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005550:	4481                	li	s1,0
  ustack[argc] = 0;
    80005552:	00349793          	slli	a5,s1,0x3
    80005556:	f9040713          	addi	a4,s0,-112
    8000555a:	97ba                	add	a5,a5,a4
    8000555c:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdbb70>
  sp -= (argc+1) * sizeof(uint64);
    80005560:	00148693          	addi	a3,s1,1
    80005564:	068e                	slli	a3,a3,0x3
    80005566:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000556a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000556e:	01597663          	bgeu	s2,s5,8000557a <exec+0x252>
  sz = sz1;
    80005572:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005576:	4a81                	li	s5,0
    80005578:	a059                	j	800055fe <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000557a:	e9040613          	addi	a2,s0,-368
    8000557e:	85ca                	mv	a1,s2
    80005580:	855a                	mv	a0,s6
    80005582:	ffffc097          	auipc	ra,0xffffc
    80005586:	0e6080e7          	jalr	230(ra) # 80001668 <copyout>
    8000558a:	0a054963          	bltz	a0,8000563c <exec+0x314>
  p->trapframe->a1 = sp;
    8000558e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005592:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005596:	de843783          	ld	a5,-536(s0)
    8000559a:	0007c703          	lbu	a4,0(a5)
    8000559e:	cf11                	beqz	a4,800055ba <exec+0x292>
    800055a0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055a2:	02f00693          	li	a3,47
    800055a6:	a039                	j	800055b4 <exec+0x28c>
      last = s+1;
    800055a8:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800055ac:	0785                	addi	a5,a5,1
    800055ae:	fff7c703          	lbu	a4,-1(a5)
    800055b2:	c701                	beqz	a4,800055ba <exec+0x292>
    if(*s == '/')
    800055b4:	fed71ce3          	bne	a4,a3,800055ac <exec+0x284>
    800055b8:	bfc5                	j	800055a8 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    800055ba:	4641                	li	a2,16
    800055bc:	de843583          	ld	a1,-536(s0)
    800055c0:	158b8513          	addi	a0,s7,344
    800055c4:	ffffc097          	auipc	ra,0xffffc
    800055c8:	858080e7          	jalr	-1960(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800055cc:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800055d0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800055d4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055d8:	058bb783          	ld	a5,88(s7)
    800055dc:	e6843703          	ld	a4,-408(s0)
    800055e0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055e2:	058bb783          	ld	a5,88(s7)
    800055e6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055ea:	85ea                	mv	a1,s10
    800055ec:	ffffc097          	auipc	ra,0xffffc
    800055f0:	520080e7          	jalr	1312(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055f4:	0004851b          	sext.w	a0,s1
    800055f8:	b3f1                	j	800053c4 <exec+0x9c>
    800055fa:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800055fe:	df843583          	ld	a1,-520(s0)
    80005602:	855a                	mv	a0,s6
    80005604:	ffffc097          	auipc	ra,0xffffc
    80005608:	508080e7          	jalr	1288(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    8000560c:	da0a92e3          	bnez	s5,800053b0 <exec+0x88>
  return -1;
    80005610:	557d                	li	a0,-1
    80005612:	bb4d                	j	800053c4 <exec+0x9c>
    80005614:	df243c23          	sd	s2,-520(s0)
    80005618:	b7dd                	j	800055fe <exec+0x2d6>
    8000561a:	df243c23          	sd	s2,-520(s0)
    8000561e:	b7c5                	j	800055fe <exec+0x2d6>
    80005620:	df243c23          	sd	s2,-520(s0)
    80005624:	bfe9                	j	800055fe <exec+0x2d6>
    80005626:	df243c23          	sd	s2,-520(s0)
    8000562a:	bfd1                	j	800055fe <exec+0x2d6>
  sz = sz1;
    8000562c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005630:	4a81                	li	s5,0
    80005632:	b7f1                	j	800055fe <exec+0x2d6>
  sz = sz1;
    80005634:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005638:	4a81                	li	s5,0
    8000563a:	b7d1                	j	800055fe <exec+0x2d6>
  sz = sz1;
    8000563c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005640:	4a81                	li	s5,0
    80005642:	bf75                	j	800055fe <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005644:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005648:	e0843783          	ld	a5,-504(s0)
    8000564c:	0017869b          	addiw	a3,a5,1
    80005650:	e0d43423          	sd	a3,-504(s0)
    80005654:	e0043783          	ld	a5,-512(s0)
    80005658:	0387879b          	addiw	a5,a5,56
    8000565c:	e8845703          	lhu	a4,-376(s0)
    80005660:	e0e6dee3          	bge	a3,a4,8000547c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005664:	2781                	sext.w	a5,a5
    80005666:	e0f43023          	sd	a5,-512(s0)
    8000566a:	03800713          	li	a4,56
    8000566e:	86be                	mv	a3,a5
    80005670:	e1840613          	addi	a2,s0,-488
    80005674:	4581                	li	a1,0
    80005676:	8556                	mv	a0,s5
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	a5c080e7          	jalr	-1444(ra) # 800040d4 <readi>
    80005680:	03800793          	li	a5,56
    80005684:	f6f51be3          	bne	a0,a5,800055fa <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005688:	e1842783          	lw	a5,-488(s0)
    8000568c:	4705                	li	a4,1
    8000568e:	fae79de3          	bne	a5,a4,80005648 <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005692:	e4043483          	ld	s1,-448(s0)
    80005696:	e3843783          	ld	a5,-456(s0)
    8000569a:	f6f4ede3          	bltu	s1,a5,80005614 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000569e:	e2843783          	ld	a5,-472(s0)
    800056a2:	94be                	add	s1,s1,a5
    800056a4:	f6f4ebe3          	bltu	s1,a5,8000561a <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    800056a8:	de043703          	ld	a4,-544(s0)
    800056ac:	8ff9                	and	a5,a5,a4
    800056ae:	fbad                	bnez	a5,80005620 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800056b0:	e1c42503          	lw	a0,-484(s0)
    800056b4:	00000097          	auipc	ra,0x0
    800056b8:	c58080e7          	jalr	-936(ra) # 8000530c <flags2perm>
    800056bc:	86aa                	mv	a3,a0
    800056be:	8626                	mv	a2,s1
    800056c0:	85ca                	mv	a1,s2
    800056c2:	855a                	mv	a0,s6
    800056c4:	ffffc097          	auipc	ra,0xffffc
    800056c8:	d4c080e7          	jalr	-692(ra) # 80001410 <uvmalloc>
    800056cc:	dea43c23          	sd	a0,-520(s0)
    800056d0:	d939                	beqz	a0,80005626 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056d2:	e2843c03          	ld	s8,-472(s0)
    800056d6:	e2042c83          	lw	s9,-480(s0)
    800056da:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056de:	f60b83e3          	beqz	s7,80005644 <exec+0x31c>
    800056e2:	89de                	mv	s3,s7
    800056e4:	4481                	li	s1,0
    800056e6:	bb95                	j	8000545a <exec+0x132>

00000000800056e8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056e8:	7179                	addi	sp,sp,-48
    800056ea:	f406                	sd	ra,40(sp)
    800056ec:	f022                	sd	s0,32(sp)
    800056ee:	ec26                	sd	s1,24(sp)
    800056f0:	e84a                	sd	s2,16(sp)
    800056f2:	1800                	addi	s0,sp,48
    800056f4:	892e                	mv	s2,a1
    800056f6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800056f8:	fdc40593          	addi	a1,s0,-36
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	af8080e7          	jalr	-1288(ra) # 800031f4 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005704:	fdc42703          	lw	a4,-36(s0)
    80005708:	47bd                	li	a5,15
    8000570a:	02e7eb63          	bltu	a5,a4,80005740 <argfd+0x58>
    8000570e:	ffffc097          	auipc	ra,0xffffc
    80005712:	29e080e7          	jalr	670(ra) # 800019ac <myproc>
    80005716:	fdc42703          	lw	a4,-36(s0)
    8000571a:	01a70793          	addi	a5,a4,26
    8000571e:	078e                	slli	a5,a5,0x3
    80005720:	953e                	add	a0,a0,a5
    80005722:	611c                	ld	a5,0(a0)
    80005724:	c385                	beqz	a5,80005744 <argfd+0x5c>
    return -1;
  if(pfd)
    80005726:	00090463          	beqz	s2,8000572e <argfd+0x46>
    *pfd = fd;
    8000572a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000572e:	4501                	li	a0,0
  if(pf)
    80005730:	c091                	beqz	s1,80005734 <argfd+0x4c>
    *pf = f;
    80005732:	e09c                	sd	a5,0(s1)
}
    80005734:	70a2                	ld	ra,40(sp)
    80005736:	7402                	ld	s0,32(sp)
    80005738:	64e2                	ld	s1,24(sp)
    8000573a:	6942                	ld	s2,16(sp)
    8000573c:	6145                	addi	sp,sp,48
    8000573e:	8082                	ret
    return -1;
    80005740:	557d                	li	a0,-1
    80005742:	bfcd                	j	80005734 <argfd+0x4c>
    80005744:	557d                	li	a0,-1
    80005746:	b7fd                	j	80005734 <argfd+0x4c>

0000000080005748 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005748:	1101                	addi	sp,sp,-32
    8000574a:	ec06                	sd	ra,24(sp)
    8000574c:	e822                	sd	s0,16(sp)
    8000574e:	e426                	sd	s1,8(sp)
    80005750:	1000                	addi	s0,sp,32
    80005752:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005754:	ffffc097          	auipc	ra,0xffffc
    80005758:	258080e7          	jalr	600(ra) # 800019ac <myproc>
    8000575c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000575e:	0d050793          	addi	a5,a0,208
    80005762:	4501                	li	a0,0
    80005764:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005766:	6398                	ld	a4,0(a5)
    80005768:	cb19                	beqz	a4,8000577e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000576a:	2505                	addiw	a0,a0,1
    8000576c:	07a1                	addi	a5,a5,8
    8000576e:	fed51ce3          	bne	a0,a3,80005766 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005772:	557d                	li	a0,-1
}
    80005774:	60e2                	ld	ra,24(sp)
    80005776:	6442                	ld	s0,16(sp)
    80005778:	64a2                	ld	s1,8(sp)
    8000577a:	6105                	addi	sp,sp,32
    8000577c:	8082                	ret
      p->ofile[fd] = f;
    8000577e:	01a50793          	addi	a5,a0,26
    80005782:	078e                	slli	a5,a5,0x3
    80005784:	963e                	add	a2,a2,a5
    80005786:	e204                	sd	s1,0(a2)
      return fd;
    80005788:	b7f5                	j	80005774 <fdalloc+0x2c>

000000008000578a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000578a:	715d                	addi	sp,sp,-80
    8000578c:	e486                	sd	ra,72(sp)
    8000578e:	e0a2                	sd	s0,64(sp)
    80005790:	fc26                	sd	s1,56(sp)
    80005792:	f84a                	sd	s2,48(sp)
    80005794:	f44e                	sd	s3,40(sp)
    80005796:	f052                	sd	s4,32(sp)
    80005798:	ec56                	sd	s5,24(sp)
    8000579a:	e85a                	sd	s6,16(sp)
    8000579c:	0880                	addi	s0,sp,80
    8000579e:	8b2e                	mv	s6,a1
    800057a0:	89b2                	mv	s3,a2
    800057a2:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800057a4:	fb040593          	addi	a1,s0,-80
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	e3c080e7          	jalr	-452(ra) # 800045e4 <nameiparent>
    800057b0:	84aa                	mv	s1,a0
    800057b2:	14050f63          	beqz	a0,80005910 <create+0x186>
    return 0;

  ilock(dp);
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	66a080e7          	jalr	1642(ra) # 80003e20 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800057be:	4601                	li	a2,0
    800057c0:	fb040593          	addi	a1,s0,-80
    800057c4:	8526                	mv	a0,s1
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	b3e080e7          	jalr	-1218(ra) # 80004304 <dirlookup>
    800057ce:	8aaa                	mv	s5,a0
    800057d0:	c931                	beqz	a0,80005824 <create+0x9a>
    iunlockput(dp);
    800057d2:	8526                	mv	a0,s1
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	8ae080e7          	jalr	-1874(ra) # 80004082 <iunlockput>
    ilock(ip);
    800057dc:	8556                	mv	a0,s5
    800057de:	ffffe097          	auipc	ra,0xffffe
    800057e2:	642080e7          	jalr	1602(ra) # 80003e20 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057e6:	000b059b          	sext.w	a1,s6
    800057ea:	4789                	li	a5,2
    800057ec:	02f59563          	bne	a1,a5,80005816 <create+0x8c>
    800057f0:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdbcb4>
    800057f4:	37f9                	addiw	a5,a5,-2
    800057f6:	17c2                	slli	a5,a5,0x30
    800057f8:	93c1                	srli	a5,a5,0x30
    800057fa:	4705                	li	a4,1
    800057fc:	00f76d63          	bltu	a4,a5,80005816 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005800:	8556                	mv	a0,s5
    80005802:	60a6                	ld	ra,72(sp)
    80005804:	6406                	ld	s0,64(sp)
    80005806:	74e2                	ld	s1,56(sp)
    80005808:	7942                	ld	s2,48(sp)
    8000580a:	79a2                	ld	s3,40(sp)
    8000580c:	7a02                	ld	s4,32(sp)
    8000580e:	6ae2                	ld	s5,24(sp)
    80005810:	6b42                	ld	s6,16(sp)
    80005812:	6161                	addi	sp,sp,80
    80005814:	8082                	ret
    iunlockput(ip);
    80005816:	8556                	mv	a0,s5
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	86a080e7          	jalr	-1942(ra) # 80004082 <iunlockput>
    return 0;
    80005820:	4a81                	li	s5,0
    80005822:	bff9                	j	80005800 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005824:	85da                	mv	a1,s6
    80005826:	4088                	lw	a0,0(s1)
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	45c080e7          	jalr	1116(ra) # 80003c84 <ialloc>
    80005830:	8a2a                	mv	s4,a0
    80005832:	c539                	beqz	a0,80005880 <create+0xf6>
  ilock(ip);
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	5ec080e7          	jalr	1516(ra) # 80003e20 <ilock>
  ip->major = major;
    8000583c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005840:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005844:	4905                	li	s2,1
    80005846:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000584a:	8552                	mv	a0,s4
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	50a080e7          	jalr	1290(ra) # 80003d56 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005854:	000b059b          	sext.w	a1,s6
    80005858:	03258b63          	beq	a1,s2,8000588e <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000585c:	004a2603          	lw	a2,4(s4)
    80005860:	fb040593          	addi	a1,s0,-80
    80005864:	8526                	mv	a0,s1
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	cae080e7          	jalr	-850(ra) # 80004514 <dirlink>
    8000586e:	06054f63          	bltz	a0,800058ec <create+0x162>
  iunlockput(dp);
    80005872:	8526                	mv	a0,s1
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	80e080e7          	jalr	-2034(ra) # 80004082 <iunlockput>
  return ip;
    8000587c:	8ad2                	mv	s5,s4
    8000587e:	b749                	j	80005800 <create+0x76>
    iunlockput(dp);
    80005880:	8526                	mv	a0,s1
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	800080e7          	jalr	-2048(ra) # 80004082 <iunlockput>
    return 0;
    8000588a:	8ad2                	mv	s5,s4
    8000588c:	bf95                	j	80005800 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000588e:	004a2603          	lw	a2,4(s4)
    80005892:	00003597          	auipc	a1,0x3
    80005896:	eae58593          	addi	a1,a1,-338 # 80008740 <syscalls+0x2c0>
    8000589a:	8552                	mv	a0,s4
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	c78080e7          	jalr	-904(ra) # 80004514 <dirlink>
    800058a4:	04054463          	bltz	a0,800058ec <create+0x162>
    800058a8:	40d0                	lw	a2,4(s1)
    800058aa:	00003597          	auipc	a1,0x3
    800058ae:	e9e58593          	addi	a1,a1,-354 # 80008748 <syscalls+0x2c8>
    800058b2:	8552                	mv	a0,s4
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	c60080e7          	jalr	-928(ra) # 80004514 <dirlink>
    800058bc:	02054863          	bltz	a0,800058ec <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800058c0:	004a2603          	lw	a2,4(s4)
    800058c4:	fb040593          	addi	a1,s0,-80
    800058c8:	8526                	mv	a0,s1
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	c4a080e7          	jalr	-950(ra) # 80004514 <dirlink>
    800058d2:	00054d63          	bltz	a0,800058ec <create+0x162>
    dp->nlink++;  // for ".."
    800058d6:	04a4d783          	lhu	a5,74(s1)
    800058da:	2785                	addiw	a5,a5,1
    800058dc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058e0:	8526                	mv	a0,s1
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	474080e7          	jalr	1140(ra) # 80003d56 <iupdate>
    800058ea:	b761                	j	80005872 <create+0xe8>
  ip->nlink = 0;
    800058ec:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800058f0:	8552                	mv	a0,s4
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	464080e7          	jalr	1124(ra) # 80003d56 <iupdate>
  iunlockput(ip);
    800058fa:	8552                	mv	a0,s4
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	786080e7          	jalr	1926(ra) # 80004082 <iunlockput>
  iunlockput(dp);
    80005904:	8526                	mv	a0,s1
    80005906:	ffffe097          	auipc	ra,0xffffe
    8000590a:	77c080e7          	jalr	1916(ra) # 80004082 <iunlockput>
  return 0;
    8000590e:	bdcd                	j	80005800 <create+0x76>
    return 0;
    80005910:	8aaa                	mv	s5,a0
    80005912:	b5fd                	j	80005800 <create+0x76>

0000000080005914 <sys_dup>:
{
    80005914:	7179                	addi	sp,sp,-48
    80005916:	f406                	sd	ra,40(sp)
    80005918:	f022                	sd	s0,32(sp)
    8000591a:	ec26                	sd	s1,24(sp)
    8000591c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000591e:	fd840613          	addi	a2,s0,-40
    80005922:	4581                	li	a1,0
    80005924:	4501                	li	a0,0
    80005926:	00000097          	auipc	ra,0x0
    8000592a:	dc2080e7          	jalr	-574(ra) # 800056e8 <argfd>
    return -1;
    8000592e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005930:	02054363          	bltz	a0,80005956 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005934:	fd843503          	ld	a0,-40(s0)
    80005938:	00000097          	auipc	ra,0x0
    8000593c:	e10080e7          	jalr	-496(ra) # 80005748 <fdalloc>
    80005940:	84aa                	mv	s1,a0
    return -1;
    80005942:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005944:	00054963          	bltz	a0,80005956 <sys_dup+0x42>
  filedup(f);
    80005948:	fd843503          	ld	a0,-40(s0)
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	310080e7          	jalr	784(ra) # 80004c5c <filedup>
  return fd;
    80005954:	87a6                	mv	a5,s1
}
    80005956:	853e                	mv	a0,a5
    80005958:	70a2                	ld	ra,40(sp)
    8000595a:	7402                	ld	s0,32(sp)
    8000595c:	64e2                	ld	s1,24(sp)
    8000595e:	6145                	addi	sp,sp,48
    80005960:	8082                	ret

0000000080005962 <sys_read>:
{
    80005962:	7179                	addi	sp,sp,-48
    80005964:	f406                	sd	ra,40(sp)
    80005966:	f022                	sd	s0,32(sp)
    80005968:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000596a:	fd840593          	addi	a1,s0,-40
    8000596e:	4505                	li	a0,1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	8a4080e7          	jalr	-1884(ra) # 80003214 <argaddr>
  argint(2, &n);
    80005978:	fe440593          	addi	a1,s0,-28
    8000597c:	4509                	li	a0,2
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	876080e7          	jalr	-1930(ra) # 800031f4 <argint>
  if(argfd(0, 0, &f) < 0)
    80005986:	fe840613          	addi	a2,s0,-24
    8000598a:	4581                	li	a1,0
    8000598c:	4501                	li	a0,0
    8000598e:	00000097          	auipc	ra,0x0
    80005992:	d5a080e7          	jalr	-678(ra) # 800056e8 <argfd>
    80005996:	87aa                	mv	a5,a0
    return -1;
    80005998:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000599a:	0007cc63          	bltz	a5,800059b2 <sys_read+0x50>
  return fileread(f, p, n);
    8000599e:	fe442603          	lw	a2,-28(s0)
    800059a2:	fd843583          	ld	a1,-40(s0)
    800059a6:	fe843503          	ld	a0,-24(s0)
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	43e080e7          	jalr	1086(ra) # 80004de8 <fileread>
}
    800059b2:	70a2                	ld	ra,40(sp)
    800059b4:	7402                	ld	s0,32(sp)
    800059b6:	6145                	addi	sp,sp,48
    800059b8:	8082                	ret

00000000800059ba <sys_getreadcount>:
{
    800059ba:	1141                	addi	sp,sp,-16
    800059bc:	e422                	sd	s0,8(sp)
    800059be:	0800                	addi	s0,sp,16
}
    800059c0:	00003517          	auipc	a0,0x3
    800059c4:	f5452503          	lw	a0,-172(a0) # 80008914 <readcount>
    800059c8:	6422                	ld	s0,8(sp)
    800059ca:	0141                	addi	sp,sp,16
    800059cc:	8082                	ret

00000000800059ce <sys_sigalarm>:
{
    800059ce:	7179                	addi	sp,sp,-48
    800059d0:	f406                	sd	ra,40(sp)
    800059d2:	f022                	sd	s0,32(sp)
    800059d4:	ec26                	sd	s1,24(sp)
    800059d6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800059d8:	ffffc097          	auipc	ra,0xffffc
    800059dc:	fd4080e7          	jalr	-44(ra) # 800019ac <myproc>
    800059e0:	84aa                	mv	s1,a0
  argint(0, &ticks);
    800059e2:	fd440593          	addi	a1,s0,-44
    800059e6:	4501                	li	a0,0
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	80c080e7          	jalr	-2036(ra) # 800031f4 <argint>
  argaddr(1, &addr);
    800059f0:	fd840593          	addi	a1,s0,-40
    800059f4:	4505                	li	a0,1
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	81e080e7          	jalr	-2018(ra) # 80003214 <argaddr>
  p->ticks = ticks;
    800059fe:	fd442783          	lw	a5,-44(s0)
    80005a02:	18f4a023          	sw	a5,384(s1)
  p->handler = addr;
    80005a06:	fd843783          	ld	a5,-40(s0)
    80005a0a:	16f4bc23          	sd	a5,376(s1)
  p->kernelornot=1;
    80005a0e:	4785                	li	a5,1
    80005a10:	18f4aa23          	sw	a5,404(s1)
}
    80005a14:	4501                	li	a0,0
    80005a16:	70a2                	ld	ra,40(sp)
    80005a18:	7402                	ld	s0,32(sp)
    80005a1a:	64e2                	ld	s1,24(sp)
    80005a1c:	6145                	addi	sp,sp,48
    80005a1e:	8082                	ret

0000000080005a20 <sys_sigreturn>:
{
    80005a20:	7129                	addi	sp,sp,-320
    80005a22:	fe06                	sd	ra,312(sp)
    80005a24:	fa22                	sd	s0,304(sp)
    80005a26:	f626                	sd	s1,296(sp)
    80005a28:	0280                	addi	s0,sp,320
  struct proc *p = myproc();
    80005a2a:	ffffc097          	auipc	ra,0xffffc
    80005a2e:	f82080e7          	jalr	-126(ra) # 800019ac <myproc>
    80005a32:	84aa                	mv	s1,a0
  memmove(&save_tf, p->trapframe, sizeof(struct trapframe));
    80005a34:	12000613          	li	a2,288
    80005a38:	6d2c                	ld	a1,88(a0)
    80005a3a:	ec040513          	addi	a0,s0,-320
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	2f0080e7          	jalr	752(ra) # 80000d2e <memmove>
  memmove(p->trapframe, p->alarm_tf, PGSIZE);
    80005a46:	6605                	lui	a2,0x1
    80005a48:	1884b583          	ld	a1,392(s1)
    80005a4c:	6ca8                	ld	a0,88(s1)
    80005a4e:	ffffb097          	auipc	ra,0xffffb
    80005a52:	2e0080e7          	jalr	736(ra) # 80000d2e <memmove>
  kfree(p->alarm_tf);
    80005a56:	1884b503          	ld	a0,392(s1)
    80005a5a:	ffffb097          	auipc	ra,0xffffb
    80005a5e:	f90080e7          	jalr	-112(ra) # 800009ea <kfree>
  p->alarm_tf = 0;
    80005a62:	1804b423          	sd	zero,392(s1)
  p->ticks=0;
    80005a66:	1804a023          	sw	zero,384(s1)
  p->alarm_on = 0;
    80005a6a:	1804a823          	sw	zero,400(s1)
  p->cur_ticks = 0;
    80005a6e:	1804a223          	sw	zero,388(s1)
  p->kernelornot=0;
    80005a72:	1804aa23          	sw	zero,404(s1)
  return p->trapframe->a0;
    80005a76:	6cbc                	ld	a5,88(s1)
}
    80005a78:	7ba8                	ld	a0,112(a5)
    80005a7a:	70f2                	ld	ra,312(sp)
    80005a7c:	7452                	ld	s0,304(sp)
    80005a7e:	74b2                	ld	s1,296(sp)
    80005a80:	6131                	addi	sp,sp,320
    80005a82:	8082                	ret

0000000080005a84 <sys_write>:
{
    80005a84:	7179                	addi	sp,sp,-48
    80005a86:	f406                	sd	ra,40(sp)
    80005a88:	f022                	sd	s0,32(sp)
    80005a8a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005a8c:	fd840593          	addi	a1,s0,-40
    80005a90:	4505                	li	a0,1
    80005a92:	ffffd097          	auipc	ra,0xffffd
    80005a96:	782080e7          	jalr	1922(ra) # 80003214 <argaddr>
  argint(2, &n);
    80005a9a:	fe440593          	addi	a1,s0,-28
    80005a9e:	4509                	li	a0,2
    80005aa0:	ffffd097          	auipc	ra,0xffffd
    80005aa4:	754080e7          	jalr	1876(ra) # 800031f4 <argint>
  if(argfd(0, 0, &f) < 0)
    80005aa8:	fe840613          	addi	a2,s0,-24
    80005aac:	4581                	li	a1,0
    80005aae:	4501                	li	a0,0
    80005ab0:	00000097          	auipc	ra,0x0
    80005ab4:	c38080e7          	jalr	-968(ra) # 800056e8 <argfd>
    80005ab8:	87aa                	mv	a5,a0
    return -1;
    80005aba:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005abc:	0007cc63          	bltz	a5,80005ad4 <sys_write+0x50>
  return filewrite(f, p, n);
    80005ac0:	fe442603          	lw	a2,-28(s0)
    80005ac4:	fd843583          	ld	a1,-40(s0)
    80005ac8:	fe843503          	ld	a0,-24(s0)
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	3de080e7          	jalr	990(ra) # 80004eaa <filewrite>
}
    80005ad4:	70a2                	ld	ra,40(sp)
    80005ad6:	7402                	ld	s0,32(sp)
    80005ad8:	6145                	addi	sp,sp,48
    80005ada:	8082                	ret

0000000080005adc <sys_close>:
{
    80005adc:	1101                	addi	sp,sp,-32
    80005ade:	ec06                	sd	ra,24(sp)
    80005ae0:	e822                	sd	s0,16(sp)
    80005ae2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005ae4:	fe040613          	addi	a2,s0,-32
    80005ae8:	fec40593          	addi	a1,s0,-20
    80005aec:	4501                	li	a0,0
    80005aee:	00000097          	auipc	ra,0x0
    80005af2:	bfa080e7          	jalr	-1030(ra) # 800056e8 <argfd>
    return -1;
    80005af6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005af8:	02054463          	bltz	a0,80005b20 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005afc:	ffffc097          	auipc	ra,0xffffc
    80005b00:	eb0080e7          	jalr	-336(ra) # 800019ac <myproc>
    80005b04:	fec42783          	lw	a5,-20(s0)
    80005b08:	07e9                	addi	a5,a5,26
    80005b0a:	078e                	slli	a5,a5,0x3
    80005b0c:	97aa                	add	a5,a5,a0
    80005b0e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005b12:	fe043503          	ld	a0,-32(s0)
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	198080e7          	jalr	408(ra) # 80004cae <fileclose>
  return 0;
    80005b1e:	4781                	li	a5,0
}
    80005b20:	853e                	mv	a0,a5
    80005b22:	60e2                	ld	ra,24(sp)
    80005b24:	6442                	ld	s0,16(sp)
    80005b26:	6105                	addi	sp,sp,32
    80005b28:	8082                	ret

0000000080005b2a <sys_fstat>:
{
    80005b2a:	1101                	addi	sp,sp,-32
    80005b2c:	ec06                	sd	ra,24(sp)
    80005b2e:	e822                	sd	s0,16(sp)
    80005b30:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005b32:	fe040593          	addi	a1,s0,-32
    80005b36:	4505                	li	a0,1
    80005b38:	ffffd097          	auipc	ra,0xffffd
    80005b3c:	6dc080e7          	jalr	1756(ra) # 80003214 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005b40:	fe840613          	addi	a2,s0,-24
    80005b44:	4581                	li	a1,0
    80005b46:	4501                	li	a0,0
    80005b48:	00000097          	auipc	ra,0x0
    80005b4c:	ba0080e7          	jalr	-1120(ra) # 800056e8 <argfd>
    80005b50:	87aa                	mv	a5,a0
    return -1;
    80005b52:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b54:	0007ca63          	bltz	a5,80005b68 <sys_fstat+0x3e>
  return filestat(f, st);
    80005b58:	fe043583          	ld	a1,-32(s0)
    80005b5c:	fe843503          	ld	a0,-24(s0)
    80005b60:	fffff097          	auipc	ra,0xfffff
    80005b64:	216080e7          	jalr	534(ra) # 80004d76 <filestat>
}
    80005b68:	60e2                	ld	ra,24(sp)
    80005b6a:	6442                	ld	s0,16(sp)
    80005b6c:	6105                	addi	sp,sp,32
    80005b6e:	8082                	ret

0000000080005b70 <sys_link>:
{
    80005b70:	7169                	addi	sp,sp,-304
    80005b72:	f606                	sd	ra,296(sp)
    80005b74:	f222                	sd	s0,288(sp)
    80005b76:	ee26                	sd	s1,280(sp)
    80005b78:	ea4a                	sd	s2,272(sp)
    80005b7a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b7c:	08000613          	li	a2,128
    80005b80:	ed040593          	addi	a1,s0,-304
    80005b84:	4501                	li	a0,0
    80005b86:	ffffd097          	auipc	ra,0xffffd
    80005b8a:	6ae080e7          	jalr	1710(ra) # 80003234 <argstr>
    return -1;
    80005b8e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b90:	10054e63          	bltz	a0,80005cac <sys_link+0x13c>
    80005b94:	08000613          	li	a2,128
    80005b98:	f5040593          	addi	a1,s0,-176
    80005b9c:	4505                	li	a0,1
    80005b9e:	ffffd097          	auipc	ra,0xffffd
    80005ba2:	696080e7          	jalr	1686(ra) # 80003234 <argstr>
    return -1;
    80005ba6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ba8:	10054263          	bltz	a0,80005cac <sys_link+0x13c>
  begin_op();
    80005bac:	fffff097          	auipc	ra,0xfffff
    80005bb0:	c36080e7          	jalr	-970(ra) # 800047e2 <begin_op>
  if((ip = namei(old)) == 0){
    80005bb4:	ed040513          	addi	a0,s0,-304
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	a0e080e7          	jalr	-1522(ra) # 800045c6 <namei>
    80005bc0:	84aa                	mv	s1,a0
    80005bc2:	c551                	beqz	a0,80005c4e <sys_link+0xde>
  ilock(ip);
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	25c080e7          	jalr	604(ra) # 80003e20 <ilock>
  if(ip->type == T_DIR){
    80005bcc:	04449703          	lh	a4,68(s1)
    80005bd0:	4785                	li	a5,1
    80005bd2:	08f70463          	beq	a4,a5,80005c5a <sys_link+0xea>
  ip->nlink++;
    80005bd6:	04a4d783          	lhu	a5,74(s1)
    80005bda:	2785                	addiw	a5,a5,1
    80005bdc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005be0:	8526                	mv	a0,s1
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	174080e7          	jalr	372(ra) # 80003d56 <iupdate>
  iunlock(ip);
    80005bea:	8526                	mv	a0,s1
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	2f6080e7          	jalr	758(ra) # 80003ee2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005bf4:	fd040593          	addi	a1,s0,-48
    80005bf8:	f5040513          	addi	a0,s0,-176
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	9e8080e7          	jalr	-1560(ra) # 800045e4 <nameiparent>
    80005c04:	892a                	mv	s2,a0
    80005c06:	c935                	beqz	a0,80005c7a <sys_link+0x10a>
  ilock(dp);
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	218080e7          	jalr	536(ra) # 80003e20 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c10:	00092703          	lw	a4,0(s2)
    80005c14:	409c                	lw	a5,0(s1)
    80005c16:	04f71d63          	bne	a4,a5,80005c70 <sys_link+0x100>
    80005c1a:	40d0                	lw	a2,4(s1)
    80005c1c:	fd040593          	addi	a1,s0,-48
    80005c20:	854a                	mv	a0,s2
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	8f2080e7          	jalr	-1806(ra) # 80004514 <dirlink>
    80005c2a:	04054363          	bltz	a0,80005c70 <sys_link+0x100>
  iunlockput(dp);
    80005c2e:	854a                	mv	a0,s2
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	452080e7          	jalr	1106(ra) # 80004082 <iunlockput>
  iput(ip);
    80005c38:	8526                	mv	a0,s1
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	3a0080e7          	jalr	928(ra) # 80003fda <iput>
  end_op();
    80005c42:	fffff097          	auipc	ra,0xfffff
    80005c46:	c20080e7          	jalr	-992(ra) # 80004862 <end_op>
  return 0;
    80005c4a:	4781                	li	a5,0
    80005c4c:	a085                	j	80005cac <sys_link+0x13c>
    end_op();
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	c14080e7          	jalr	-1004(ra) # 80004862 <end_op>
    return -1;
    80005c56:	57fd                	li	a5,-1
    80005c58:	a891                	j	80005cac <sys_link+0x13c>
    iunlockput(ip);
    80005c5a:	8526                	mv	a0,s1
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	426080e7          	jalr	1062(ra) # 80004082 <iunlockput>
    end_op();
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	bfe080e7          	jalr	-1026(ra) # 80004862 <end_op>
    return -1;
    80005c6c:	57fd                	li	a5,-1
    80005c6e:	a83d                	j	80005cac <sys_link+0x13c>
    iunlockput(dp);
    80005c70:	854a                	mv	a0,s2
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	410080e7          	jalr	1040(ra) # 80004082 <iunlockput>
  ilock(ip);
    80005c7a:	8526                	mv	a0,s1
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	1a4080e7          	jalr	420(ra) # 80003e20 <ilock>
  ip->nlink--;
    80005c84:	04a4d783          	lhu	a5,74(s1)
    80005c88:	37fd                	addiw	a5,a5,-1
    80005c8a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c8e:	8526                	mv	a0,s1
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	0c6080e7          	jalr	198(ra) # 80003d56 <iupdate>
  iunlockput(ip);
    80005c98:	8526                	mv	a0,s1
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	3e8080e7          	jalr	1000(ra) # 80004082 <iunlockput>
  end_op();
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	bc0080e7          	jalr	-1088(ra) # 80004862 <end_op>
  return -1;
    80005caa:	57fd                	li	a5,-1
}
    80005cac:	853e                	mv	a0,a5
    80005cae:	70b2                	ld	ra,296(sp)
    80005cb0:	7412                	ld	s0,288(sp)
    80005cb2:	64f2                	ld	s1,280(sp)
    80005cb4:	6952                	ld	s2,272(sp)
    80005cb6:	6155                	addi	sp,sp,304
    80005cb8:	8082                	ret

0000000080005cba <sys_unlink>:
{
    80005cba:	7151                	addi	sp,sp,-240
    80005cbc:	f586                	sd	ra,232(sp)
    80005cbe:	f1a2                	sd	s0,224(sp)
    80005cc0:	eda6                	sd	s1,216(sp)
    80005cc2:	e9ca                	sd	s2,208(sp)
    80005cc4:	e5ce                	sd	s3,200(sp)
    80005cc6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005cc8:	08000613          	li	a2,128
    80005ccc:	f3040593          	addi	a1,s0,-208
    80005cd0:	4501                	li	a0,0
    80005cd2:	ffffd097          	auipc	ra,0xffffd
    80005cd6:	562080e7          	jalr	1378(ra) # 80003234 <argstr>
    80005cda:	18054163          	bltz	a0,80005e5c <sys_unlink+0x1a2>
  begin_op();
    80005cde:	fffff097          	auipc	ra,0xfffff
    80005ce2:	b04080e7          	jalr	-1276(ra) # 800047e2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ce6:	fb040593          	addi	a1,s0,-80
    80005cea:	f3040513          	addi	a0,s0,-208
    80005cee:	fffff097          	auipc	ra,0xfffff
    80005cf2:	8f6080e7          	jalr	-1802(ra) # 800045e4 <nameiparent>
    80005cf6:	84aa                	mv	s1,a0
    80005cf8:	c979                	beqz	a0,80005dce <sys_unlink+0x114>
  ilock(dp);
    80005cfa:	ffffe097          	auipc	ra,0xffffe
    80005cfe:	126080e7          	jalr	294(ra) # 80003e20 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005d02:	00003597          	auipc	a1,0x3
    80005d06:	a3e58593          	addi	a1,a1,-1474 # 80008740 <syscalls+0x2c0>
    80005d0a:	fb040513          	addi	a0,s0,-80
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	5dc080e7          	jalr	1500(ra) # 800042ea <namecmp>
    80005d16:	14050a63          	beqz	a0,80005e6a <sys_unlink+0x1b0>
    80005d1a:	00003597          	auipc	a1,0x3
    80005d1e:	a2e58593          	addi	a1,a1,-1490 # 80008748 <syscalls+0x2c8>
    80005d22:	fb040513          	addi	a0,s0,-80
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	5c4080e7          	jalr	1476(ra) # 800042ea <namecmp>
    80005d2e:	12050e63          	beqz	a0,80005e6a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d32:	f2c40613          	addi	a2,s0,-212
    80005d36:	fb040593          	addi	a1,s0,-80
    80005d3a:	8526                	mv	a0,s1
    80005d3c:	ffffe097          	auipc	ra,0xffffe
    80005d40:	5c8080e7          	jalr	1480(ra) # 80004304 <dirlookup>
    80005d44:	892a                	mv	s2,a0
    80005d46:	12050263          	beqz	a0,80005e6a <sys_unlink+0x1b0>
  ilock(ip);
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	0d6080e7          	jalr	214(ra) # 80003e20 <ilock>
  if(ip->nlink < 1)
    80005d52:	04a91783          	lh	a5,74(s2)
    80005d56:	08f05263          	blez	a5,80005dda <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d5a:	04491703          	lh	a4,68(s2)
    80005d5e:	4785                	li	a5,1
    80005d60:	08f70563          	beq	a4,a5,80005dea <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d64:	4641                	li	a2,16
    80005d66:	4581                	li	a1,0
    80005d68:	fc040513          	addi	a0,s0,-64
    80005d6c:	ffffb097          	auipc	ra,0xffffb
    80005d70:	f66080e7          	jalr	-154(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d74:	4741                	li	a4,16
    80005d76:	f2c42683          	lw	a3,-212(s0)
    80005d7a:	fc040613          	addi	a2,s0,-64
    80005d7e:	4581                	li	a1,0
    80005d80:	8526                	mv	a0,s1
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	44a080e7          	jalr	1098(ra) # 800041cc <writei>
    80005d8a:	47c1                	li	a5,16
    80005d8c:	0af51563          	bne	a0,a5,80005e36 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d90:	04491703          	lh	a4,68(s2)
    80005d94:	4785                	li	a5,1
    80005d96:	0af70863          	beq	a4,a5,80005e46 <sys_unlink+0x18c>
  iunlockput(dp);
    80005d9a:	8526                	mv	a0,s1
    80005d9c:	ffffe097          	auipc	ra,0xffffe
    80005da0:	2e6080e7          	jalr	742(ra) # 80004082 <iunlockput>
  ip->nlink--;
    80005da4:	04a95783          	lhu	a5,74(s2)
    80005da8:	37fd                	addiw	a5,a5,-1
    80005daa:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005dae:	854a                	mv	a0,s2
    80005db0:	ffffe097          	auipc	ra,0xffffe
    80005db4:	fa6080e7          	jalr	-90(ra) # 80003d56 <iupdate>
  iunlockput(ip);
    80005db8:	854a                	mv	a0,s2
    80005dba:	ffffe097          	auipc	ra,0xffffe
    80005dbe:	2c8080e7          	jalr	712(ra) # 80004082 <iunlockput>
  end_op();
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	aa0080e7          	jalr	-1376(ra) # 80004862 <end_op>
  return 0;
    80005dca:	4501                	li	a0,0
    80005dcc:	a84d                	j	80005e7e <sys_unlink+0x1c4>
    end_op();
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	a94080e7          	jalr	-1388(ra) # 80004862 <end_op>
    return -1;
    80005dd6:	557d                	li	a0,-1
    80005dd8:	a05d                	j	80005e7e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005dda:	00003517          	auipc	a0,0x3
    80005dde:	97650513          	addi	a0,a0,-1674 # 80008750 <syscalls+0x2d0>
    80005de2:	ffffa097          	auipc	ra,0xffffa
    80005de6:	75c080e7          	jalr	1884(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005dea:	04c92703          	lw	a4,76(s2)
    80005dee:	02000793          	li	a5,32
    80005df2:	f6e7f9e3          	bgeu	a5,a4,80005d64 <sys_unlink+0xaa>
    80005df6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005dfa:	4741                	li	a4,16
    80005dfc:	86ce                	mv	a3,s3
    80005dfe:	f1840613          	addi	a2,s0,-232
    80005e02:	4581                	li	a1,0
    80005e04:	854a                	mv	a0,s2
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	2ce080e7          	jalr	718(ra) # 800040d4 <readi>
    80005e0e:	47c1                	li	a5,16
    80005e10:	00f51b63          	bne	a0,a5,80005e26 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e14:	f1845783          	lhu	a5,-232(s0)
    80005e18:	e7a1                	bnez	a5,80005e60 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e1a:	29c1                	addiw	s3,s3,16
    80005e1c:	04c92783          	lw	a5,76(s2)
    80005e20:	fcf9ede3          	bltu	s3,a5,80005dfa <sys_unlink+0x140>
    80005e24:	b781                	j	80005d64 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e26:	00003517          	auipc	a0,0x3
    80005e2a:	94250513          	addi	a0,a0,-1726 # 80008768 <syscalls+0x2e8>
    80005e2e:	ffffa097          	auipc	ra,0xffffa
    80005e32:	710080e7          	jalr	1808(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005e36:	00003517          	auipc	a0,0x3
    80005e3a:	94a50513          	addi	a0,a0,-1718 # 80008780 <syscalls+0x300>
    80005e3e:	ffffa097          	auipc	ra,0xffffa
    80005e42:	700080e7          	jalr	1792(ra) # 8000053e <panic>
    dp->nlink--;
    80005e46:	04a4d783          	lhu	a5,74(s1)
    80005e4a:	37fd                	addiw	a5,a5,-1
    80005e4c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e50:	8526                	mv	a0,s1
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	f04080e7          	jalr	-252(ra) # 80003d56 <iupdate>
    80005e5a:	b781                	j	80005d9a <sys_unlink+0xe0>
    return -1;
    80005e5c:	557d                	li	a0,-1
    80005e5e:	a005                	j	80005e7e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e60:	854a                	mv	a0,s2
    80005e62:	ffffe097          	auipc	ra,0xffffe
    80005e66:	220080e7          	jalr	544(ra) # 80004082 <iunlockput>
  iunlockput(dp);
    80005e6a:	8526                	mv	a0,s1
    80005e6c:	ffffe097          	auipc	ra,0xffffe
    80005e70:	216080e7          	jalr	534(ra) # 80004082 <iunlockput>
  end_op();
    80005e74:	fffff097          	auipc	ra,0xfffff
    80005e78:	9ee080e7          	jalr	-1554(ra) # 80004862 <end_op>
  return -1;
    80005e7c:	557d                	li	a0,-1
}
    80005e7e:	70ae                	ld	ra,232(sp)
    80005e80:	740e                	ld	s0,224(sp)
    80005e82:	64ee                	ld	s1,216(sp)
    80005e84:	694e                	ld	s2,208(sp)
    80005e86:	69ae                	ld	s3,200(sp)
    80005e88:	616d                	addi	sp,sp,240
    80005e8a:	8082                	ret

0000000080005e8c <sys_open>:

uint64
sys_open(void)
{
    80005e8c:	7131                	addi	sp,sp,-192
    80005e8e:	fd06                	sd	ra,184(sp)
    80005e90:	f922                	sd	s0,176(sp)
    80005e92:	f526                	sd	s1,168(sp)
    80005e94:	f14a                	sd	s2,160(sp)
    80005e96:	ed4e                	sd	s3,152(sp)
    80005e98:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005e9a:	f4c40593          	addi	a1,s0,-180
    80005e9e:	4505                	li	a0,1
    80005ea0:	ffffd097          	auipc	ra,0xffffd
    80005ea4:	354080e7          	jalr	852(ra) # 800031f4 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ea8:	08000613          	li	a2,128
    80005eac:	f5040593          	addi	a1,s0,-176
    80005eb0:	4501                	li	a0,0
    80005eb2:	ffffd097          	auipc	ra,0xffffd
    80005eb6:	382080e7          	jalr	898(ra) # 80003234 <argstr>
    80005eba:	87aa                	mv	a5,a0
    return -1;
    80005ebc:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ebe:	0a07c963          	bltz	a5,80005f70 <sys_open+0xe4>

  begin_op();
    80005ec2:	fffff097          	auipc	ra,0xfffff
    80005ec6:	920080e7          	jalr	-1760(ra) # 800047e2 <begin_op>

  if(omode & O_CREATE){
    80005eca:	f4c42783          	lw	a5,-180(s0)
    80005ece:	2007f793          	andi	a5,a5,512
    80005ed2:	cfc5                	beqz	a5,80005f8a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ed4:	4681                	li	a3,0
    80005ed6:	4601                	li	a2,0
    80005ed8:	4589                	li	a1,2
    80005eda:	f5040513          	addi	a0,s0,-176
    80005ede:	00000097          	auipc	ra,0x0
    80005ee2:	8ac080e7          	jalr	-1876(ra) # 8000578a <create>
    80005ee6:	84aa                	mv	s1,a0
    if(ip == 0){
    80005ee8:	c959                	beqz	a0,80005f7e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005eea:	04449703          	lh	a4,68(s1)
    80005eee:	478d                	li	a5,3
    80005ef0:	00f71763          	bne	a4,a5,80005efe <sys_open+0x72>
    80005ef4:	0464d703          	lhu	a4,70(s1)
    80005ef8:	47a5                	li	a5,9
    80005efa:	0ce7ed63          	bltu	a5,a4,80005fd4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005efe:	fffff097          	auipc	ra,0xfffff
    80005f02:	cf4080e7          	jalr	-780(ra) # 80004bf2 <filealloc>
    80005f06:	89aa                	mv	s3,a0
    80005f08:	10050363          	beqz	a0,8000600e <sys_open+0x182>
    80005f0c:	00000097          	auipc	ra,0x0
    80005f10:	83c080e7          	jalr	-1988(ra) # 80005748 <fdalloc>
    80005f14:	892a                	mv	s2,a0
    80005f16:	0e054763          	bltz	a0,80006004 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f1a:	04449703          	lh	a4,68(s1)
    80005f1e:	478d                	li	a5,3
    80005f20:	0cf70563          	beq	a4,a5,80005fea <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f24:	4789                	li	a5,2
    80005f26:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f2a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f2e:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f32:	f4c42783          	lw	a5,-180(s0)
    80005f36:	0017c713          	xori	a4,a5,1
    80005f3a:	8b05                	andi	a4,a4,1
    80005f3c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f40:	0037f713          	andi	a4,a5,3
    80005f44:	00e03733          	snez	a4,a4
    80005f48:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f4c:	4007f793          	andi	a5,a5,1024
    80005f50:	c791                	beqz	a5,80005f5c <sys_open+0xd0>
    80005f52:	04449703          	lh	a4,68(s1)
    80005f56:	4789                	li	a5,2
    80005f58:	0af70063          	beq	a4,a5,80005ff8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f5c:	8526                	mv	a0,s1
    80005f5e:	ffffe097          	auipc	ra,0xffffe
    80005f62:	f84080e7          	jalr	-124(ra) # 80003ee2 <iunlock>
  end_op();
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	8fc080e7          	jalr	-1796(ra) # 80004862 <end_op>

  return fd;
    80005f6e:	854a                	mv	a0,s2
}
    80005f70:	70ea                	ld	ra,184(sp)
    80005f72:	744a                	ld	s0,176(sp)
    80005f74:	74aa                	ld	s1,168(sp)
    80005f76:	790a                	ld	s2,160(sp)
    80005f78:	69ea                	ld	s3,152(sp)
    80005f7a:	6129                	addi	sp,sp,192
    80005f7c:	8082                	ret
      end_op();
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	8e4080e7          	jalr	-1820(ra) # 80004862 <end_op>
      return -1;
    80005f86:	557d                	li	a0,-1
    80005f88:	b7e5                	j	80005f70 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f8a:	f5040513          	addi	a0,s0,-176
    80005f8e:	ffffe097          	auipc	ra,0xffffe
    80005f92:	638080e7          	jalr	1592(ra) # 800045c6 <namei>
    80005f96:	84aa                	mv	s1,a0
    80005f98:	c905                	beqz	a0,80005fc8 <sys_open+0x13c>
    ilock(ip);
    80005f9a:	ffffe097          	auipc	ra,0xffffe
    80005f9e:	e86080e7          	jalr	-378(ra) # 80003e20 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005fa2:	04449703          	lh	a4,68(s1)
    80005fa6:	4785                	li	a5,1
    80005fa8:	f4f711e3          	bne	a4,a5,80005eea <sys_open+0x5e>
    80005fac:	f4c42783          	lw	a5,-180(s0)
    80005fb0:	d7b9                	beqz	a5,80005efe <sys_open+0x72>
      iunlockput(ip);
    80005fb2:	8526                	mv	a0,s1
    80005fb4:	ffffe097          	auipc	ra,0xffffe
    80005fb8:	0ce080e7          	jalr	206(ra) # 80004082 <iunlockput>
      end_op();
    80005fbc:	fffff097          	auipc	ra,0xfffff
    80005fc0:	8a6080e7          	jalr	-1882(ra) # 80004862 <end_op>
      return -1;
    80005fc4:	557d                	li	a0,-1
    80005fc6:	b76d                	j	80005f70 <sys_open+0xe4>
      end_op();
    80005fc8:	fffff097          	auipc	ra,0xfffff
    80005fcc:	89a080e7          	jalr	-1894(ra) # 80004862 <end_op>
      return -1;
    80005fd0:	557d                	li	a0,-1
    80005fd2:	bf79                	j	80005f70 <sys_open+0xe4>
    iunlockput(ip);
    80005fd4:	8526                	mv	a0,s1
    80005fd6:	ffffe097          	auipc	ra,0xffffe
    80005fda:	0ac080e7          	jalr	172(ra) # 80004082 <iunlockput>
    end_op();
    80005fde:	fffff097          	auipc	ra,0xfffff
    80005fe2:	884080e7          	jalr	-1916(ra) # 80004862 <end_op>
    return -1;
    80005fe6:	557d                	li	a0,-1
    80005fe8:	b761                	j	80005f70 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005fea:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005fee:	04649783          	lh	a5,70(s1)
    80005ff2:	02f99223          	sh	a5,36(s3)
    80005ff6:	bf25                	j	80005f2e <sys_open+0xa2>
    itrunc(ip);
    80005ff8:	8526                	mv	a0,s1
    80005ffa:	ffffe097          	auipc	ra,0xffffe
    80005ffe:	f34080e7          	jalr	-204(ra) # 80003f2e <itrunc>
    80006002:	bfa9                	j	80005f5c <sys_open+0xd0>
      fileclose(f);
    80006004:	854e                	mv	a0,s3
    80006006:	fffff097          	auipc	ra,0xfffff
    8000600a:	ca8080e7          	jalr	-856(ra) # 80004cae <fileclose>
    iunlockput(ip);
    8000600e:	8526                	mv	a0,s1
    80006010:	ffffe097          	auipc	ra,0xffffe
    80006014:	072080e7          	jalr	114(ra) # 80004082 <iunlockput>
    end_op();
    80006018:	fffff097          	auipc	ra,0xfffff
    8000601c:	84a080e7          	jalr	-1974(ra) # 80004862 <end_op>
    return -1;
    80006020:	557d                	li	a0,-1
    80006022:	b7b9                	j	80005f70 <sys_open+0xe4>

0000000080006024 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006024:	7175                	addi	sp,sp,-144
    80006026:	e506                	sd	ra,136(sp)
    80006028:	e122                	sd	s0,128(sp)
    8000602a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	7b6080e7          	jalr	1974(ra) # 800047e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006034:	08000613          	li	a2,128
    80006038:	f7040593          	addi	a1,s0,-144
    8000603c:	4501                	li	a0,0
    8000603e:	ffffd097          	auipc	ra,0xffffd
    80006042:	1f6080e7          	jalr	502(ra) # 80003234 <argstr>
    80006046:	02054963          	bltz	a0,80006078 <sys_mkdir+0x54>
    8000604a:	4681                	li	a3,0
    8000604c:	4601                	li	a2,0
    8000604e:	4585                	li	a1,1
    80006050:	f7040513          	addi	a0,s0,-144
    80006054:	fffff097          	auipc	ra,0xfffff
    80006058:	736080e7          	jalr	1846(ra) # 8000578a <create>
    8000605c:	cd11                	beqz	a0,80006078 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000605e:	ffffe097          	auipc	ra,0xffffe
    80006062:	024080e7          	jalr	36(ra) # 80004082 <iunlockput>
  end_op();
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	7fc080e7          	jalr	2044(ra) # 80004862 <end_op>
  return 0;
    8000606e:	4501                	li	a0,0
}
    80006070:	60aa                	ld	ra,136(sp)
    80006072:	640a                	ld	s0,128(sp)
    80006074:	6149                	addi	sp,sp,144
    80006076:	8082                	ret
    end_op();
    80006078:	ffffe097          	auipc	ra,0xffffe
    8000607c:	7ea080e7          	jalr	2026(ra) # 80004862 <end_op>
    return -1;
    80006080:	557d                	li	a0,-1
    80006082:	b7fd                	j	80006070 <sys_mkdir+0x4c>

0000000080006084 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006084:	7135                	addi	sp,sp,-160
    80006086:	ed06                	sd	ra,152(sp)
    80006088:	e922                	sd	s0,144(sp)
    8000608a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	756080e7          	jalr	1878(ra) # 800047e2 <begin_op>
  argint(1, &major);
    80006094:	f6c40593          	addi	a1,s0,-148
    80006098:	4505                	li	a0,1
    8000609a:	ffffd097          	auipc	ra,0xffffd
    8000609e:	15a080e7          	jalr	346(ra) # 800031f4 <argint>
  argint(2, &minor);
    800060a2:	f6840593          	addi	a1,s0,-152
    800060a6:	4509                	li	a0,2
    800060a8:	ffffd097          	auipc	ra,0xffffd
    800060ac:	14c080e7          	jalr	332(ra) # 800031f4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060b0:	08000613          	li	a2,128
    800060b4:	f7040593          	addi	a1,s0,-144
    800060b8:	4501                	li	a0,0
    800060ba:	ffffd097          	auipc	ra,0xffffd
    800060be:	17a080e7          	jalr	378(ra) # 80003234 <argstr>
    800060c2:	02054b63          	bltz	a0,800060f8 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800060c6:	f6841683          	lh	a3,-152(s0)
    800060ca:	f6c41603          	lh	a2,-148(s0)
    800060ce:	458d                	li	a1,3
    800060d0:	f7040513          	addi	a0,s0,-144
    800060d4:	fffff097          	auipc	ra,0xfffff
    800060d8:	6b6080e7          	jalr	1718(ra) # 8000578a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060dc:	cd11                	beqz	a0,800060f8 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060de:	ffffe097          	auipc	ra,0xffffe
    800060e2:	fa4080e7          	jalr	-92(ra) # 80004082 <iunlockput>
  end_op();
    800060e6:	ffffe097          	auipc	ra,0xffffe
    800060ea:	77c080e7          	jalr	1916(ra) # 80004862 <end_op>
  return 0;
    800060ee:	4501                	li	a0,0
}
    800060f0:	60ea                	ld	ra,152(sp)
    800060f2:	644a                	ld	s0,144(sp)
    800060f4:	610d                	addi	sp,sp,160
    800060f6:	8082                	ret
    end_op();
    800060f8:	ffffe097          	auipc	ra,0xffffe
    800060fc:	76a080e7          	jalr	1898(ra) # 80004862 <end_op>
    return -1;
    80006100:	557d                	li	a0,-1
    80006102:	b7fd                	j	800060f0 <sys_mknod+0x6c>

0000000080006104 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006104:	7135                	addi	sp,sp,-160
    80006106:	ed06                	sd	ra,152(sp)
    80006108:	e922                	sd	s0,144(sp)
    8000610a:	e526                	sd	s1,136(sp)
    8000610c:	e14a                	sd	s2,128(sp)
    8000610e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006110:	ffffc097          	auipc	ra,0xffffc
    80006114:	89c080e7          	jalr	-1892(ra) # 800019ac <myproc>
    80006118:	892a                	mv	s2,a0
  
  begin_op();
    8000611a:	ffffe097          	auipc	ra,0xffffe
    8000611e:	6c8080e7          	jalr	1736(ra) # 800047e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006122:	08000613          	li	a2,128
    80006126:	f6040593          	addi	a1,s0,-160
    8000612a:	4501                	li	a0,0
    8000612c:	ffffd097          	auipc	ra,0xffffd
    80006130:	108080e7          	jalr	264(ra) # 80003234 <argstr>
    80006134:	04054b63          	bltz	a0,8000618a <sys_chdir+0x86>
    80006138:	f6040513          	addi	a0,s0,-160
    8000613c:	ffffe097          	auipc	ra,0xffffe
    80006140:	48a080e7          	jalr	1162(ra) # 800045c6 <namei>
    80006144:	84aa                	mv	s1,a0
    80006146:	c131                	beqz	a0,8000618a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006148:	ffffe097          	auipc	ra,0xffffe
    8000614c:	cd8080e7          	jalr	-808(ra) # 80003e20 <ilock>
  if(ip->type != T_DIR){
    80006150:	04449703          	lh	a4,68(s1)
    80006154:	4785                	li	a5,1
    80006156:	04f71063          	bne	a4,a5,80006196 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000615a:	8526                	mv	a0,s1
    8000615c:	ffffe097          	auipc	ra,0xffffe
    80006160:	d86080e7          	jalr	-634(ra) # 80003ee2 <iunlock>
  iput(p->cwd);
    80006164:	15093503          	ld	a0,336(s2)
    80006168:	ffffe097          	auipc	ra,0xffffe
    8000616c:	e72080e7          	jalr	-398(ra) # 80003fda <iput>
  end_op();
    80006170:	ffffe097          	auipc	ra,0xffffe
    80006174:	6f2080e7          	jalr	1778(ra) # 80004862 <end_op>
  p->cwd = ip;
    80006178:	14993823          	sd	s1,336(s2)
  return 0;
    8000617c:	4501                	li	a0,0
}
    8000617e:	60ea                	ld	ra,152(sp)
    80006180:	644a                	ld	s0,144(sp)
    80006182:	64aa                	ld	s1,136(sp)
    80006184:	690a                	ld	s2,128(sp)
    80006186:	610d                	addi	sp,sp,160
    80006188:	8082                	ret
    end_op();
    8000618a:	ffffe097          	auipc	ra,0xffffe
    8000618e:	6d8080e7          	jalr	1752(ra) # 80004862 <end_op>
    return -1;
    80006192:	557d                	li	a0,-1
    80006194:	b7ed                	j	8000617e <sys_chdir+0x7a>
    iunlockput(ip);
    80006196:	8526                	mv	a0,s1
    80006198:	ffffe097          	auipc	ra,0xffffe
    8000619c:	eea080e7          	jalr	-278(ra) # 80004082 <iunlockput>
    end_op();
    800061a0:	ffffe097          	auipc	ra,0xffffe
    800061a4:	6c2080e7          	jalr	1730(ra) # 80004862 <end_op>
    return -1;
    800061a8:	557d                	li	a0,-1
    800061aa:	bfd1                	j	8000617e <sys_chdir+0x7a>

00000000800061ac <sys_exec>:

uint64
sys_exec(void)
{
    800061ac:	7145                	addi	sp,sp,-464
    800061ae:	e786                	sd	ra,456(sp)
    800061b0:	e3a2                	sd	s0,448(sp)
    800061b2:	ff26                	sd	s1,440(sp)
    800061b4:	fb4a                	sd	s2,432(sp)
    800061b6:	f74e                	sd	s3,424(sp)
    800061b8:	f352                	sd	s4,416(sp)
    800061ba:	ef56                	sd	s5,408(sp)
    800061bc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800061be:	e3840593          	addi	a1,s0,-456
    800061c2:	4505                	li	a0,1
    800061c4:	ffffd097          	auipc	ra,0xffffd
    800061c8:	050080e7          	jalr	80(ra) # 80003214 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800061cc:	08000613          	li	a2,128
    800061d0:	f4040593          	addi	a1,s0,-192
    800061d4:	4501                	li	a0,0
    800061d6:	ffffd097          	auipc	ra,0xffffd
    800061da:	05e080e7          	jalr	94(ra) # 80003234 <argstr>
    800061de:	87aa                	mv	a5,a0
    return -1;
    800061e0:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800061e2:	0c07c263          	bltz	a5,800062a6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800061e6:	10000613          	li	a2,256
    800061ea:	4581                	li	a1,0
    800061ec:	e4040513          	addi	a0,s0,-448
    800061f0:	ffffb097          	auipc	ra,0xffffb
    800061f4:	ae2080e7          	jalr	-1310(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800061f8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061fc:	89a6                	mv	s3,s1
    800061fe:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006200:	02000a13          	li	s4,32
    80006204:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006208:	00391793          	slli	a5,s2,0x3
    8000620c:	e3040593          	addi	a1,s0,-464
    80006210:	e3843503          	ld	a0,-456(s0)
    80006214:	953e                	add	a0,a0,a5
    80006216:	ffffd097          	auipc	ra,0xffffd
    8000621a:	f40080e7          	jalr	-192(ra) # 80003156 <fetchaddr>
    8000621e:	02054a63          	bltz	a0,80006252 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006222:	e3043783          	ld	a5,-464(s0)
    80006226:	c3b9                	beqz	a5,8000626c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006228:	ffffb097          	auipc	ra,0xffffb
    8000622c:	8be080e7          	jalr	-1858(ra) # 80000ae6 <kalloc>
    80006230:	85aa                	mv	a1,a0
    80006232:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006236:	cd11                	beqz	a0,80006252 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006238:	6605                	lui	a2,0x1
    8000623a:	e3043503          	ld	a0,-464(s0)
    8000623e:	ffffd097          	auipc	ra,0xffffd
    80006242:	f6a080e7          	jalr	-150(ra) # 800031a8 <fetchstr>
    80006246:	00054663          	bltz	a0,80006252 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    8000624a:	0905                	addi	s2,s2,1
    8000624c:	09a1                	addi	s3,s3,8
    8000624e:	fb491be3          	bne	s2,s4,80006204 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006252:	10048913          	addi	s2,s1,256
    80006256:	6088                	ld	a0,0(s1)
    80006258:	c531                	beqz	a0,800062a4 <sys_exec+0xf8>
    kfree(argv[i]);
    8000625a:	ffffa097          	auipc	ra,0xffffa
    8000625e:	790080e7          	jalr	1936(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006262:	04a1                	addi	s1,s1,8
    80006264:	ff2499e3          	bne	s1,s2,80006256 <sys_exec+0xaa>
  return -1;
    80006268:	557d                	li	a0,-1
    8000626a:	a835                	j	800062a6 <sys_exec+0xfa>
      argv[i] = 0;
    8000626c:	0a8e                	slli	s5,s5,0x3
    8000626e:	fc040793          	addi	a5,s0,-64
    80006272:	9abe                	add	s5,s5,a5
    80006274:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006278:	e4040593          	addi	a1,s0,-448
    8000627c:	f4040513          	addi	a0,s0,-192
    80006280:	fffff097          	auipc	ra,0xfffff
    80006284:	0a8080e7          	jalr	168(ra) # 80005328 <exec>
    80006288:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000628a:	10048993          	addi	s3,s1,256
    8000628e:	6088                	ld	a0,0(s1)
    80006290:	c901                	beqz	a0,800062a0 <sys_exec+0xf4>
    kfree(argv[i]);
    80006292:	ffffa097          	auipc	ra,0xffffa
    80006296:	758080e7          	jalr	1880(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000629a:	04a1                	addi	s1,s1,8
    8000629c:	ff3499e3          	bne	s1,s3,8000628e <sys_exec+0xe2>
  return ret;
    800062a0:	854a                	mv	a0,s2
    800062a2:	a011                	j	800062a6 <sys_exec+0xfa>
  return -1;
    800062a4:	557d                	li	a0,-1
}
    800062a6:	60be                	ld	ra,456(sp)
    800062a8:	641e                	ld	s0,448(sp)
    800062aa:	74fa                	ld	s1,440(sp)
    800062ac:	795a                	ld	s2,432(sp)
    800062ae:	79ba                	ld	s3,424(sp)
    800062b0:	7a1a                	ld	s4,416(sp)
    800062b2:	6afa                	ld	s5,408(sp)
    800062b4:	6179                	addi	sp,sp,464
    800062b6:	8082                	ret

00000000800062b8 <sys_pipe>:

uint64
sys_pipe(void)
{
    800062b8:	7139                	addi	sp,sp,-64
    800062ba:	fc06                	sd	ra,56(sp)
    800062bc:	f822                	sd	s0,48(sp)
    800062be:	f426                	sd	s1,40(sp)
    800062c0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800062c2:	ffffb097          	auipc	ra,0xffffb
    800062c6:	6ea080e7          	jalr	1770(ra) # 800019ac <myproc>
    800062ca:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800062cc:	fd840593          	addi	a1,s0,-40
    800062d0:	4501                	li	a0,0
    800062d2:	ffffd097          	auipc	ra,0xffffd
    800062d6:	f42080e7          	jalr	-190(ra) # 80003214 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800062da:	fc840593          	addi	a1,s0,-56
    800062de:	fd040513          	addi	a0,s0,-48
    800062e2:	fffff097          	auipc	ra,0xfffff
    800062e6:	cfc080e7          	jalr	-772(ra) # 80004fde <pipealloc>
    return -1;
    800062ea:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800062ec:	0c054463          	bltz	a0,800063b4 <sys_pipe+0xfc>
  fd0 = -1;
    800062f0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800062f4:	fd043503          	ld	a0,-48(s0)
    800062f8:	fffff097          	auipc	ra,0xfffff
    800062fc:	450080e7          	jalr	1104(ra) # 80005748 <fdalloc>
    80006300:	fca42223          	sw	a0,-60(s0)
    80006304:	08054b63          	bltz	a0,8000639a <sys_pipe+0xe2>
    80006308:	fc843503          	ld	a0,-56(s0)
    8000630c:	fffff097          	auipc	ra,0xfffff
    80006310:	43c080e7          	jalr	1084(ra) # 80005748 <fdalloc>
    80006314:	fca42023          	sw	a0,-64(s0)
    80006318:	06054863          	bltz	a0,80006388 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000631c:	4691                	li	a3,4
    8000631e:	fc440613          	addi	a2,s0,-60
    80006322:	fd843583          	ld	a1,-40(s0)
    80006326:	68a8                	ld	a0,80(s1)
    80006328:	ffffb097          	auipc	ra,0xffffb
    8000632c:	340080e7          	jalr	832(ra) # 80001668 <copyout>
    80006330:	02054063          	bltz	a0,80006350 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006334:	4691                	li	a3,4
    80006336:	fc040613          	addi	a2,s0,-64
    8000633a:	fd843583          	ld	a1,-40(s0)
    8000633e:	0591                	addi	a1,a1,4
    80006340:	68a8                	ld	a0,80(s1)
    80006342:	ffffb097          	auipc	ra,0xffffb
    80006346:	326080e7          	jalr	806(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000634a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000634c:	06055463          	bgez	a0,800063b4 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006350:	fc442783          	lw	a5,-60(s0)
    80006354:	07e9                	addi	a5,a5,26
    80006356:	078e                	slli	a5,a5,0x3
    80006358:	97a6                	add	a5,a5,s1
    8000635a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000635e:	fc042503          	lw	a0,-64(s0)
    80006362:	0569                	addi	a0,a0,26
    80006364:	050e                	slli	a0,a0,0x3
    80006366:	94aa                	add	s1,s1,a0
    80006368:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000636c:	fd043503          	ld	a0,-48(s0)
    80006370:	fffff097          	auipc	ra,0xfffff
    80006374:	93e080e7          	jalr	-1730(ra) # 80004cae <fileclose>
    fileclose(wf);
    80006378:	fc843503          	ld	a0,-56(s0)
    8000637c:	fffff097          	auipc	ra,0xfffff
    80006380:	932080e7          	jalr	-1742(ra) # 80004cae <fileclose>
    return -1;
    80006384:	57fd                	li	a5,-1
    80006386:	a03d                	j	800063b4 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006388:	fc442783          	lw	a5,-60(s0)
    8000638c:	0007c763          	bltz	a5,8000639a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006390:	07e9                	addi	a5,a5,26
    80006392:	078e                	slli	a5,a5,0x3
    80006394:	94be                	add	s1,s1,a5
    80006396:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000639a:	fd043503          	ld	a0,-48(s0)
    8000639e:	fffff097          	auipc	ra,0xfffff
    800063a2:	910080e7          	jalr	-1776(ra) # 80004cae <fileclose>
    fileclose(wf);
    800063a6:	fc843503          	ld	a0,-56(s0)
    800063aa:	fffff097          	auipc	ra,0xfffff
    800063ae:	904080e7          	jalr	-1788(ra) # 80004cae <fileclose>
    return -1;
    800063b2:	57fd                	li	a5,-1
}
    800063b4:	853e                	mv	a0,a5
    800063b6:	70e2                	ld	ra,56(sp)
    800063b8:	7442                	ld	s0,48(sp)
    800063ba:	74a2                	ld	s1,40(sp)
    800063bc:	6121                	addi	sp,sp,64
    800063be:	8082                	ret

00000000800063c0 <kernelvec>:
    800063c0:	7111                	addi	sp,sp,-256
    800063c2:	e006                	sd	ra,0(sp)
    800063c4:	e40a                	sd	sp,8(sp)
    800063c6:	e80e                	sd	gp,16(sp)
    800063c8:	ec12                	sd	tp,24(sp)
    800063ca:	f016                	sd	t0,32(sp)
    800063cc:	f41a                	sd	t1,40(sp)
    800063ce:	f81e                	sd	t2,48(sp)
    800063d0:	fc22                	sd	s0,56(sp)
    800063d2:	e0a6                	sd	s1,64(sp)
    800063d4:	e4aa                	sd	a0,72(sp)
    800063d6:	e8ae                	sd	a1,80(sp)
    800063d8:	ecb2                	sd	a2,88(sp)
    800063da:	f0b6                	sd	a3,96(sp)
    800063dc:	f4ba                	sd	a4,104(sp)
    800063de:	f8be                	sd	a5,112(sp)
    800063e0:	fcc2                	sd	a6,120(sp)
    800063e2:	e146                	sd	a7,128(sp)
    800063e4:	e54a                	sd	s2,136(sp)
    800063e6:	e94e                	sd	s3,144(sp)
    800063e8:	ed52                	sd	s4,152(sp)
    800063ea:	f156                	sd	s5,160(sp)
    800063ec:	f55a                	sd	s6,168(sp)
    800063ee:	f95e                	sd	s7,176(sp)
    800063f0:	fd62                	sd	s8,184(sp)
    800063f2:	e1e6                	sd	s9,192(sp)
    800063f4:	e5ea                	sd	s10,200(sp)
    800063f6:	e9ee                	sd	s11,208(sp)
    800063f8:	edf2                	sd	t3,216(sp)
    800063fa:	f1f6                	sd	t4,224(sp)
    800063fc:	f5fa                	sd	t5,232(sp)
    800063fe:	f9fe                	sd	t6,240(sp)
    80006400:	b31fc0ef          	jal	ra,80002f30 <kerneltrap>
    80006404:	6082                	ld	ra,0(sp)
    80006406:	6122                	ld	sp,8(sp)
    80006408:	61c2                	ld	gp,16(sp)
    8000640a:	7282                	ld	t0,32(sp)
    8000640c:	7322                	ld	t1,40(sp)
    8000640e:	73c2                	ld	t2,48(sp)
    80006410:	7462                	ld	s0,56(sp)
    80006412:	6486                	ld	s1,64(sp)
    80006414:	6526                	ld	a0,72(sp)
    80006416:	65c6                	ld	a1,80(sp)
    80006418:	6666                	ld	a2,88(sp)
    8000641a:	7686                	ld	a3,96(sp)
    8000641c:	7726                	ld	a4,104(sp)
    8000641e:	77c6                	ld	a5,112(sp)
    80006420:	7866                	ld	a6,120(sp)
    80006422:	688a                	ld	a7,128(sp)
    80006424:	692a                	ld	s2,136(sp)
    80006426:	69ca                	ld	s3,144(sp)
    80006428:	6a6a                	ld	s4,152(sp)
    8000642a:	7a8a                	ld	s5,160(sp)
    8000642c:	7b2a                	ld	s6,168(sp)
    8000642e:	7bca                	ld	s7,176(sp)
    80006430:	7c6a                	ld	s8,184(sp)
    80006432:	6c8e                	ld	s9,192(sp)
    80006434:	6d2e                	ld	s10,200(sp)
    80006436:	6dce                	ld	s11,208(sp)
    80006438:	6e6e                	ld	t3,216(sp)
    8000643a:	7e8e                	ld	t4,224(sp)
    8000643c:	7f2e                	ld	t5,232(sp)
    8000643e:	7fce                	ld	t6,240(sp)
    80006440:	6111                	addi	sp,sp,256
    80006442:	10200073          	sret
    80006446:	00000013          	nop
    8000644a:	00000013          	nop
    8000644e:	0001                	nop

0000000080006450 <timervec>:
    80006450:	34051573          	csrrw	a0,mscratch,a0
    80006454:	e10c                	sd	a1,0(a0)
    80006456:	e510                	sd	a2,8(a0)
    80006458:	e914                	sd	a3,16(a0)
    8000645a:	6d0c                	ld	a1,24(a0)
    8000645c:	7110                	ld	a2,32(a0)
    8000645e:	6194                	ld	a3,0(a1)
    80006460:	96b2                	add	a3,a3,a2
    80006462:	e194                	sd	a3,0(a1)
    80006464:	4589                	li	a1,2
    80006466:	14459073          	csrw	sip,a1
    8000646a:	6914                	ld	a3,16(a0)
    8000646c:	6510                	ld	a2,8(a0)
    8000646e:	610c                	ld	a1,0(a0)
    80006470:	34051573          	csrrw	a0,mscratch,a0
    80006474:	30200073          	mret
	...

000000008000647a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000647a:	1141                	addi	sp,sp,-16
    8000647c:	e422                	sd	s0,8(sp)
    8000647e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006480:	0c0007b7          	lui	a5,0xc000
    80006484:	4705                	li	a4,1
    80006486:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006488:	c3d8                	sw	a4,4(a5)
}
    8000648a:	6422                	ld	s0,8(sp)
    8000648c:	0141                	addi	sp,sp,16
    8000648e:	8082                	ret

0000000080006490 <plicinithart>:

void
plicinithart(void)
{
    80006490:	1141                	addi	sp,sp,-16
    80006492:	e406                	sd	ra,8(sp)
    80006494:	e022                	sd	s0,0(sp)
    80006496:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006498:	ffffb097          	auipc	ra,0xffffb
    8000649c:	4e8080e7          	jalr	1256(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800064a0:	0085171b          	slliw	a4,a0,0x8
    800064a4:	0c0027b7          	lui	a5,0xc002
    800064a8:	97ba                	add	a5,a5,a4
    800064aa:	40200713          	li	a4,1026
    800064ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800064b2:	00d5151b          	slliw	a0,a0,0xd
    800064b6:	0c2017b7          	lui	a5,0xc201
    800064ba:	953e                	add	a0,a0,a5
    800064bc:	00052023          	sw	zero,0(a0)
}
    800064c0:	60a2                	ld	ra,8(sp)
    800064c2:	6402                	ld	s0,0(sp)
    800064c4:	0141                	addi	sp,sp,16
    800064c6:	8082                	ret

00000000800064c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800064c8:	1141                	addi	sp,sp,-16
    800064ca:	e406                	sd	ra,8(sp)
    800064cc:	e022                	sd	s0,0(sp)
    800064ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064d0:	ffffb097          	auipc	ra,0xffffb
    800064d4:	4b0080e7          	jalr	1200(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800064d8:	00d5179b          	slliw	a5,a0,0xd
    800064dc:	0c201537          	lui	a0,0xc201
    800064e0:	953e                	add	a0,a0,a5
  return irq;
}
    800064e2:	4148                	lw	a0,4(a0)
    800064e4:	60a2                	ld	ra,8(sp)
    800064e6:	6402                	ld	s0,0(sp)
    800064e8:	0141                	addi	sp,sp,16
    800064ea:	8082                	ret

00000000800064ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064ec:	1101                	addi	sp,sp,-32
    800064ee:	ec06                	sd	ra,24(sp)
    800064f0:	e822                	sd	s0,16(sp)
    800064f2:	e426                	sd	s1,8(sp)
    800064f4:	1000                	addi	s0,sp,32
    800064f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800064f8:	ffffb097          	auipc	ra,0xffffb
    800064fc:	488080e7          	jalr	1160(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006500:	00d5151b          	slliw	a0,a0,0xd
    80006504:	0c2017b7          	lui	a5,0xc201
    80006508:	97aa                	add	a5,a5,a0
    8000650a:	c3c4                	sw	s1,4(a5)
}
    8000650c:	60e2                	ld	ra,24(sp)
    8000650e:	6442                	ld	s0,16(sp)
    80006510:	64a2                	ld	s1,8(sp)
    80006512:	6105                	addi	sp,sp,32
    80006514:	8082                	ret

0000000080006516 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006516:	1141                	addi	sp,sp,-16
    80006518:	e406                	sd	ra,8(sp)
    8000651a:	e022                	sd	s0,0(sp)
    8000651c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000651e:	479d                	li	a5,7
    80006520:	04a7cc63          	blt	a5,a0,80006578 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006524:	0001d797          	auipc	a5,0x1d
    80006528:	d2c78793          	addi	a5,a5,-724 # 80023250 <disk>
    8000652c:	97aa                	add	a5,a5,a0
    8000652e:	0187c783          	lbu	a5,24(a5)
    80006532:	ebb9                	bnez	a5,80006588 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006534:	00451613          	slli	a2,a0,0x4
    80006538:	0001d797          	auipc	a5,0x1d
    8000653c:	d1878793          	addi	a5,a5,-744 # 80023250 <disk>
    80006540:	6394                	ld	a3,0(a5)
    80006542:	96b2                	add	a3,a3,a2
    80006544:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006548:	6398                	ld	a4,0(a5)
    8000654a:	9732                	add	a4,a4,a2
    8000654c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006550:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006554:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006558:	953e                	add	a0,a0,a5
    8000655a:	4785                	li	a5,1
    8000655c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006560:	0001d517          	auipc	a0,0x1d
    80006564:	d0850513          	addi	a0,a0,-760 # 80023268 <disk+0x18>
    80006568:	ffffc097          	auipc	ra,0xffffc
    8000656c:	e50080e7          	jalr	-432(ra) # 800023b8 <wakeup>
}
    80006570:	60a2                	ld	ra,8(sp)
    80006572:	6402                	ld	s0,0(sp)
    80006574:	0141                	addi	sp,sp,16
    80006576:	8082                	ret
    panic("free_desc 1");
    80006578:	00002517          	auipc	a0,0x2
    8000657c:	21850513          	addi	a0,a0,536 # 80008790 <syscalls+0x310>
    80006580:	ffffa097          	auipc	ra,0xffffa
    80006584:	fbe080e7          	jalr	-66(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006588:	00002517          	auipc	a0,0x2
    8000658c:	21850513          	addi	a0,a0,536 # 800087a0 <syscalls+0x320>
    80006590:	ffffa097          	auipc	ra,0xffffa
    80006594:	fae080e7          	jalr	-82(ra) # 8000053e <panic>

0000000080006598 <virtio_disk_init>:
{
    80006598:	1101                	addi	sp,sp,-32
    8000659a:	ec06                	sd	ra,24(sp)
    8000659c:	e822                	sd	s0,16(sp)
    8000659e:	e426                	sd	s1,8(sp)
    800065a0:	e04a                	sd	s2,0(sp)
    800065a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800065a4:	00002597          	auipc	a1,0x2
    800065a8:	20c58593          	addi	a1,a1,524 # 800087b0 <syscalls+0x330>
    800065ac:	0001d517          	auipc	a0,0x1d
    800065b0:	dcc50513          	addi	a0,a0,-564 # 80023378 <disk+0x128>
    800065b4:	ffffa097          	auipc	ra,0xffffa
    800065b8:	592080e7          	jalr	1426(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065bc:	100017b7          	lui	a5,0x10001
    800065c0:	4398                	lw	a4,0(a5)
    800065c2:	2701                	sext.w	a4,a4
    800065c4:	747277b7          	lui	a5,0x74727
    800065c8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065cc:	14f71c63          	bne	a4,a5,80006724 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800065d0:	100017b7          	lui	a5,0x10001
    800065d4:	43dc                	lw	a5,4(a5)
    800065d6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065d8:	4709                	li	a4,2
    800065da:	14e79563          	bne	a5,a4,80006724 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065de:	100017b7          	lui	a5,0x10001
    800065e2:	479c                	lw	a5,8(a5)
    800065e4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800065e6:	12e79f63          	bne	a5,a4,80006724 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065ea:	100017b7          	lui	a5,0x10001
    800065ee:	47d8                	lw	a4,12(a5)
    800065f0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065f2:	554d47b7          	lui	a5,0x554d4
    800065f6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800065fa:	12f71563          	bne	a4,a5,80006724 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065fe:	100017b7          	lui	a5,0x10001
    80006602:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006606:	4705                	li	a4,1
    80006608:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000660a:	470d                	li	a4,3
    8000660c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000660e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006610:	c7ffe737          	lui	a4,0xc7ffe
    80006614:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb3cf>
    80006618:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000661a:	2701                	sext.w	a4,a4
    8000661c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000661e:	472d                	li	a4,11
    80006620:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006622:	5bbc                	lw	a5,112(a5)
    80006624:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006628:	8ba1                	andi	a5,a5,8
    8000662a:	10078563          	beqz	a5,80006734 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000662e:	100017b7          	lui	a5,0x10001
    80006632:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006636:	43fc                	lw	a5,68(a5)
    80006638:	2781                	sext.w	a5,a5
    8000663a:	10079563          	bnez	a5,80006744 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000663e:	100017b7          	lui	a5,0x10001
    80006642:	5bdc                	lw	a5,52(a5)
    80006644:	2781                	sext.w	a5,a5
  if(max == 0)
    80006646:	10078763          	beqz	a5,80006754 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000664a:	471d                	li	a4,7
    8000664c:	10f77c63          	bgeu	a4,a5,80006764 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006650:	ffffa097          	auipc	ra,0xffffa
    80006654:	496080e7          	jalr	1174(ra) # 80000ae6 <kalloc>
    80006658:	0001d497          	auipc	s1,0x1d
    8000665c:	bf848493          	addi	s1,s1,-1032 # 80023250 <disk>
    80006660:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006662:	ffffa097          	auipc	ra,0xffffa
    80006666:	484080e7          	jalr	1156(ra) # 80000ae6 <kalloc>
    8000666a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000666c:	ffffa097          	auipc	ra,0xffffa
    80006670:	47a080e7          	jalr	1146(ra) # 80000ae6 <kalloc>
    80006674:	87aa                	mv	a5,a0
    80006676:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006678:	6088                	ld	a0,0(s1)
    8000667a:	cd6d                	beqz	a0,80006774 <virtio_disk_init+0x1dc>
    8000667c:	0001d717          	auipc	a4,0x1d
    80006680:	bdc73703          	ld	a4,-1060(a4) # 80023258 <disk+0x8>
    80006684:	cb65                	beqz	a4,80006774 <virtio_disk_init+0x1dc>
    80006686:	c7fd                	beqz	a5,80006774 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006688:	6605                	lui	a2,0x1
    8000668a:	4581                	li	a1,0
    8000668c:	ffffa097          	auipc	ra,0xffffa
    80006690:	646080e7          	jalr	1606(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006694:	0001d497          	auipc	s1,0x1d
    80006698:	bbc48493          	addi	s1,s1,-1092 # 80023250 <disk>
    8000669c:	6605                	lui	a2,0x1
    8000669e:	4581                	li	a1,0
    800066a0:	6488                	ld	a0,8(s1)
    800066a2:	ffffa097          	auipc	ra,0xffffa
    800066a6:	630080e7          	jalr	1584(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800066aa:	6605                	lui	a2,0x1
    800066ac:	4581                	li	a1,0
    800066ae:	6888                	ld	a0,16(s1)
    800066b0:	ffffa097          	auipc	ra,0xffffa
    800066b4:	622080e7          	jalr	1570(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800066b8:	100017b7          	lui	a5,0x10001
    800066bc:	4721                	li	a4,8
    800066be:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800066c0:	4098                	lw	a4,0(s1)
    800066c2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800066c6:	40d8                	lw	a4,4(s1)
    800066c8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800066cc:	6498                	ld	a4,8(s1)
    800066ce:	0007069b          	sext.w	a3,a4
    800066d2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800066d6:	9701                	srai	a4,a4,0x20
    800066d8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800066dc:	6898                	ld	a4,16(s1)
    800066de:	0007069b          	sext.w	a3,a4
    800066e2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800066e6:	9701                	srai	a4,a4,0x20
    800066e8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800066ec:	4705                	li	a4,1
    800066ee:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800066f0:	00e48c23          	sb	a4,24(s1)
    800066f4:	00e48ca3          	sb	a4,25(s1)
    800066f8:	00e48d23          	sb	a4,26(s1)
    800066fc:	00e48da3          	sb	a4,27(s1)
    80006700:	00e48e23          	sb	a4,28(s1)
    80006704:	00e48ea3          	sb	a4,29(s1)
    80006708:	00e48f23          	sb	a4,30(s1)
    8000670c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006710:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006714:	0727a823          	sw	s2,112(a5)
}
    80006718:	60e2                	ld	ra,24(sp)
    8000671a:	6442                	ld	s0,16(sp)
    8000671c:	64a2                	ld	s1,8(sp)
    8000671e:	6902                	ld	s2,0(sp)
    80006720:	6105                	addi	sp,sp,32
    80006722:	8082                	ret
    panic("could not find virtio disk");
    80006724:	00002517          	auipc	a0,0x2
    80006728:	09c50513          	addi	a0,a0,156 # 800087c0 <syscalls+0x340>
    8000672c:	ffffa097          	auipc	ra,0xffffa
    80006730:	e12080e7          	jalr	-494(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006734:	00002517          	auipc	a0,0x2
    80006738:	0ac50513          	addi	a0,a0,172 # 800087e0 <syscalls+0x360>
    8000673c:	ffffa097          	auipc	ra,0xffffa
    80006740:	e02080e7          	jalr	-510(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006744:	00002517          	auipc	a0,0x2
    80006748:	0bc50513          	addi	a0,a0,188 # 80008800 <syscalls+0x380>
    8000674c:	ffffa097          	auipc	ra,0xffffa
    80006750:	df2080e7          	jalr	-526(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006754:	00002517          	auipc	a0,0x2
    80006758:	0cc50513          	addi	a0,a0,204 # 80008820 <syscalls+0x3a0>
    8000675c:	ffffa097          	auipc	ra,0xffffa
    80006760:	de2080e7          	jalr	-542(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006764:	00002517          	auipc	a0,0x2
    80006768:	0dc50513          	addi	a0,a0,220 # 80008840 <syscalls+0x3c0>
    8000676c:	ffffa097          	auipc	ra,0xffffa
    80006770:	dd2080e7          	jalr	-558(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006774:	00002517          	auipc	a0,0x2
    80006778:	0ec50513          	addi	a0,a0,236 # 80008860 <syscalls+0x3e0>
    8000677c:	ffffa097          	auipc	ra,0xffffa
    80006780:	dc2080e7          	jalr	-574(ra) # 8000053e <panic>

0000000080006784 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006784:	7119                	addi	sp,sp,-128
    80006786:	fc86                	sd	ra,120(sp)
    80006788:	f8a2                	sd	s0,112(sp)
    8000678a:	f4a6                	sd	s1,104(sp)
    8000678c:	f0ca                	sd	s2,96(sp)
    8000678e:	ecce                	sd	s3,88(sp)
    80006790:	e8d2                	sd	s4,80(sp)
    80006792:	e4d6                	sd	s5,72(sp)
    80006794:	e0da                	sd	s6,64(sp)
    80006796:	fc5e                	sd	s7,56(sp)
    80006798:	f862                	sd	s8,48(sp)
    8000679a:	f466                	sd	s9,40(sp)
    8000679c:	f06a                	sd	s10,32(sp)
    8000679e:	ec6e                	sd	s11,24(sp)
    800067a0:	0100                	addi	s0,sp,128
    800067a2:	8aaa                	mv	s5,a0
    800067a4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800067a6:	00c52d03          	lw	s10,12(a0)
    800067aa:	001d1d1b          	slliw	s10,s10,0x1
    800067ae:	1d02                	slli	s10,s10,0x20
    800067b0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800067b4:	0001d517          	auipc	a0,0x1d
    800067b8:	bc450513          	addi	a0,a0,-1084 # 80023378 <disk+0x128>
    800067bc:	ffffa097          	auipc	ra,0xffffa
    800067c0:	41a080e7          	jalr	1050(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800067c4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800067c6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800067c8:	0001db97          	auipc	s7,0x1d
    800067cc:	a88b8b93          	addi	s7,s7,-1400 # 80023250 <disk>
  for(int i = 0; i < 3; i++){
    800067d0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067d2:	0001dc97          	auipc	s9,0x1d
    800067d6:	ba6c8c93          	addi	s9,s9,-1114 # 80023378 <disk+0x128>
    800067da:	a08d                	j	8000683c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800067dc:	00fb8733          	add	a4,s7,a5
    800067e0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800067e4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800067e6:	0207c563          	bltz	a5,80006810 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800067ea:	2905                	addiw	s2,s2,1
    800067ec:	0611                	addi	a2,a2,4
    800067ee:	05690c63          	beq	s2,s6,80006846 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800067f2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800067f4:	0001d717          	auipc	a4,0x1d
    800067f8:	a5c70713          	addi	a4,a4,-1444 # 80023250 <disk>
    800067fc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800067fe:	01874683          	lbu	a3,24(a4)
    80006802:	fee9                	bnez	a3,800067dc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006804:	2785                	addiw	a5,a5,1
    80006806:	0705                	addi	a4,a4,1
    80006808:	fe979be3          	bne	a5,s1,800067fe <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000680c:	57fd                	li	a5,-1
    8000680e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006810:	01205d63          	blez	s2,8000682a <virtio_disk_rw+0xa6>
    80006814:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006816:	000a2503          	lw	a0,0(s4)
    8000681a:	00000097          	auipc	ra,0x0
    8000681e:	cfc080e7          	jalr	-772(ra) # 80006516 <free_desc>
      for(int j = 0; j < i; j++)
    80006822:	2d85                	addiw	s11,s11,1
    80006824:	0a11                	addi	s4,s4,4
    80006826:	ffb918e3          	bne	s2,s11,80006816 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000682a:	85e6                	mv	a1,s9
    8000682c:	0001d517          	auipc	a0,0x1d
    80006830:	a3c50513          	addi	a0,a0,-1476 # 80023268 <disk+0x18>
    80006834:	ffffc097          	auipc	ra,0xffffc
    80006838:	b20080e7          	jalr	-1248(ra) # 80002354 <sleep>
  for(int i = 0; i < 3; i++){
    8000683c:	f8040a13          	addi	s4,s0,-128
{
    80006840:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006842:	894e                	mv	s2,s3
    80006844:	b77d                	j	800067f2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006846:	f8042583          	lw	a1,-128(s0)
    8000684a:	00a58793          	addi	a5,a1,10
    8000684e:	0792                	slli	a5,a5,0x4

  if(write)
    80006850:	0001d617          	auipc	a2,0x1d
    80006854:	a0060613          	addi	a2,a2,-1536 # 80023250 <disk>
    80006858:	00f60733          	add	a4,a2,a5
    8000685c:	018036b3          	snez	a3,s8
    80006860:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006862:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006866:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000686a:	f6078693          	addi	a3,a5,-160
    8000686e:	6218                	ld	a4,0(a2)
    80006870:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006872:	00878513          	addi	a0,a5,8
    80006876:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006878:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000687a:	6208                	ld	a0,0(a2)
    8000687c:	96aa                	add	a3,a3,a0
    8000687e:	4741                	li	a4,16
    80006880:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006882:	4705                	li	a4,1
    80006884:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006888:	f8442703          	lw	a4,-124(s0)
    8000688c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006890:	0712                	slli	a4,a4,0x4
    80006892:	953a                	add	a0,a0,a4
    80006894:	058a8693          	addi	a3,s5,88
    80006898:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000689a:	6208                	ld	a0,0(a2)
    8000689c:	972a                	add	a4,a4,a0
    8000689e:	40000693          	li	a3,1024
    800068a2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800068a4:	001c3c13          	seqz	s8,s8
    800068a8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800068aa:	001c6c13          	ori	s8,s8,1
    800068ae:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800068b2:	f8842603          	lw	a2,-120(s0)
    800068b6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800068ba:	0001d697          	auipc	a3,0x1d
    800068be:	99668693          	addi	a3,a3,-1642 # 80023250 <disk>
    800068c2:	00258713          	addi	a4,a1,2
    800068c6:	0712                	slli	a4,a4,0x4
    800068c8:	9736                	add	a4,a4,a3
    800068ca:	587d                	li	a6,-1
    800068cc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800068d0:	0612                	slli	a2,a2,0x4
    800068d2:	9532                	add	a0,a0,a2
    800068d4:	f9078793          	addi	a5,a5,-112
    800068d8:	97b6                	add	a5,a5,a3
    800068da:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800068dc:	629c                	ld	a5,0(a3)
    800068de:	97b2                	add	a5,a5,a2
    800068e0:	4605                	li	a2,1
    800068e2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800068e4:	4509                	li	a0,2
    800068e6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800068ea:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800068ee:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800068f2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800068f6:	6698                	ld	a4,8(a3)
    800068f8:	00275783          	lhu	a5,2(a4)
    800068fc:	8b9d                	andi	a5,a5,7
    800068fe:	0786                	slli	a5,a5,0x1
    80006900:	97ba                	add	a5,a5,a4
    80006902:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006906:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000690a:	6698                	ld	a4,8(a3)
    8000690c:	00275783          	lhu	a5,2(a4)
    80006910:	2785                	addiw	a5,a5,1
    80006912:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006916:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000691a:	100017b7          	lui	a5,0x10001
    8000691e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006922:	004aa783          	lw	a5,4(s5)
    80006926:	02c79163          	bne	a5,a2,80006948 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000692a:	0001d917          	auipc	s2,0x1d
    8000692e:	a4e90913          	addi	s2,s2,-1458 # 80023378 <disk+0x128>
  while(b->disk == 1) {
    80006932:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006934:	85ca                	mv	a1,s2
    80006936:	8556                	mv	a0,s5
    80006938:	ffffc097          	auipc	ra,0xffffc
    8000693c:	a1c080e7          	jalr	-1508(ra) # 80002354 <sleep>
  while(b->disk == 1) {
    80006940:	004aa783          	lw	a5,4(s5)
    80006944:	fe9788e3          	beq	a5,s1,80006934 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006948:	f8042903          	lw	s2,-128(s0)
    8000694c:	00290793          	addi	a5,s2,2
    80006950:	00479713          	slli	a4,a5,0x4
    80006954:	0001d797          	auipc	a5,0x1d
    80006958:	8fc78793          	addi	a5,a5,-1796 # 80023250 <disk>
    8000695c:	97ba                	add	a5,a5,a4
    8000695e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006962:	0001d997          	auipc	s3,0x1d
    80006966:	8ee98993          	addi	s3,s3,-1810 # 80023250 <disk>
    8000696a:	00491713          	slli	a4,s2,0x4
    8000696e:	0009b783          	ld	a5,0(s3)
    80006972:	97ba                	add	a5,a5,a4
    80006974:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006978:	854a                	mv	a0,s2
    8000697a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000697e:	00000097          	auipc	ra,0x0
    80006982:	b98080e7          	jalr	-1128(ra) # 80006516 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006986:	8885                	andi	s1,s1,1
    80006988:	f0ed                	bnez	s1,8000696a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000698a:	0001d517          	auipc	a0,0x1d
    8000698e:	9ee50513          	addi	a0,a0,-1554 # 80023378 <disk+0x128>
    80006992:	ffffa097          	auipc	ra,0xffffa
    80006996:	2f8080e7          	jalr	760(ra) # 80000c8a <release>
}
    8000699a:	70e6                	ld	ra,120(sp)
    8000699c:	7446                	ld	s0,112(sp)
    8000699e:	74a6                	ld	s1,104(sp)
    800069a0:	7906                	ld	s2,96(sp)
    800069a2:	69e6                	ld	s3,88(sp)
    800069a4:	6a46                	ld	s4,80(sp)
    800069a6:	6aa6                	ld	s5,72(sp)
    800069a8:	6b06                	ld	s6,64(sp)
    800069aa:	7be2                	ld	s7,56(sp)
    800069ac:	7c42                	ld	s8,48(sp)
    800069ae:	7ca2                	ld	s9,40(sp)
    800069b0:	7d02                	ld	s10,32(sp)
    800069b2:	6de2                	ld	s11,24(sp)
    800069b4:	6109                	addi	sp,sp,128
    800069b6:	8082                	ret

00000000800069b8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800069b8:	1101                	addi	sp,sp,-32
    800069ba:	ec06                	sd	ra,24(sp)
    800069bc:	e822                	sd	s0,16(sp)
    800069be:	e426                	sd	s1,8(sp)
    800069c0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800069c2:	0001d497          	auipc	s1,0x1d
    800069c6:	88e48493          	addi	s1,s1,-1906 # 80023250 <disk>
    800069ca:	0001d517          	auipc	a0,0x1d
    800069ce:	9ae50513          	addi	a0,a0,-1618 # 80023378 <disk+0x128>
    800069d2:	ffffa097          	auipc	ra,0xffffa
    800069d6:	204080e7          	jalr	516(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800069da:	10001737          	lui	a4,0x10001
    800069de:	533c                	lw	a5,96(a4)
    800069e0:	8b8d                	andi	a5,a5,3
    800069e2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800069e4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800069e8:	689c                	ld	a5,16(s1)
    800069ea:	0204d703          	lhu	a4,32(s1)
    800069ee:	0027d783          	lhu	a5,2(a5)
    800069f2:	04f70863          	beq	a4,a5,80006a42 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800069f6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069fa:	6898                	ld	a4,16(s1)
    800069fc:	0204d783          	lhu	a5,32(s1)
    80006a00:	8b9d                	andi	a5,a5,7
    80006a02:	078e                	slli	a5,a5,0x3
    80006a04:	97ba                	add	a5,a5,a4
    80006a06:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a08:	00278713          	addi	a4,a5,2
    80006a0c:	0712                	slli	a4,a4,0x4
    80006a0e:	9726                	add	a4,a4,s1
    80006a10:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006a14:	e721                	bnez	a4,80006a5c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a16:	0789                	addi	a5,a5,2
    80006a18:	0792                	slli	a5,a5,0x4
    80006a1a:	97a6                	add	a5,a5,s1
    80006a1c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006a1e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a22:	ffffc097          	auipc	ra,0xffffc
    80006a26:	996080e7          	jalr	-1642(ra) # 800023b8 <wakeup>

    disk.used_idx += 1;
    80006a2a:	0204d783          	lhu	a5,32(s1)
    80006a2e:	2785                	addiw	a5,a5,1
    80006a30:	17c2                	slli	a5,a5,0x30
    80006a32:	93c1                	srli	a5,a5,0x30
    80006a34:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a38:	6898                	ld	a4,16(s1)
    80006a3a:	00275703          	lhu	a4,2(a4)
    80006a3e:	faf71ce3          	bne	a4,a5,800069f6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006a42:	0001d517          	auipc	a0,0x1d
    80006a46:	93650513          	addi	a0,a0,-1738 # 80023378 <disk+0x128>
    80006a4a:	ffffa097          	auipc	ra,0xffffa
    80006a4e:	240080e7          	jalr	576(ra) # 80000c8a <release>
}
    80006a52:	60e2                	ld	ra,24(sp)
    80006a54:	6442                	ld	s0,16(sp)
    80006a56:	64a2                	ld	s1,8(sp)
    80006a58:	6105                	addi	sp,sp,32
    80006a5a:	8082                	ret
      panic("virtio_disk_intr status");
    80006a5c:	00002517          	auipc	a0,0x2
    80006a60:	e1c50513          	addi	a0,a0,-484 # 80008878 <syscalls+0x3f8>
    80006a64:	ffffa097          	auipc	ra,0xffffa
    80006a68:	ada080e7          	jalr	-1318(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
