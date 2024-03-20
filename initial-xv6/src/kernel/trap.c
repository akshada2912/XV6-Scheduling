#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct spinlock tickslock;
uint ticks;

extern char trampoline[], uservec[], userret[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

void trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}

//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
//
void usertrap(void)
{
  int which_dev = 0;

  if ((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  w_stvec((uint64)kernelvec);

  struct proc *p = myproc();

  // save user program counter.
  p->trapframe->epc = r_sepc();

  if (r_scause() == 8)
  {
    // system call

    if (killed(p))
      exit(-1);

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    p->trapframe->epc += 4;

    // an interrupt will change sepc, scause, and sstatus,
    // so enable only now that we're done with those registers.
    intr_on();

    syscall();
  }
  else if ((which_dev = devintr()) != 0)
  {
    // ok
    if (which_dev == 2 && p->alarm_on == 0)
    {
      // Save trapframe
      p->alarm_on = 1;
      struct trapframe *tf = kalloc();
      memmove(tf, p->trapframe, PGSIZE);
      p->alarm_tf = tf;

      p->cur_ticks+=2;
      if (p->cur_ticks >= p->ticks)
        p->trapframe->epc = p->handler;
    }
  }
  else
  {
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    setkilled(p);
  }
// if(p->priority!=3 )
//             p->priority++;
  if (killed(p))
    exit(-1);

//give up the CPU if this is a timer interrupt.
#ifdef RR
  if (which_dev == 2)
    yield();
#else
#ifdef FCFS
  if( which_dev==1 || which_dev==2)
  {
    if ( which_dev==2 && myproc() != 0 && myproc()->state != RUNNING)
   {
    #ifdef FCFS
    yield();
    #endif
   }
   
    //don't yield
  }
#else
#ifdef MLFQ
   
    if (which_dev == 1) //I/O call
      {
       // printf("1. %d %d %d %d %d\n",p->pid,p->que0time,p->que1time,p->que2time,p->que3time);
        
        yield();}
    else if(which_dev==2){
      struct proc *p = myproc();
      
      if(p->queticks==0)
      {
       if(p->priority!=3)
            p->priority++;
        if(p->priority==1)
          p->que1time=ticks;
          else if(p->priority==2)
          p->que2time=ticks;
          else if(p->priority==3)
          p->que3time=ticks;
       if(p->prevticks==1)
         {
          p->queticks=3;
          p->prevticks=3;
         }
       else if(p->prevticks==3)
         {
          p->queticks=9;
          p->prevticks=9;
         }
       else if(p->prevticks==9)
         {
          p->queticks=15;
          p->prevticks=15;
         }
        // else if(currticks==3)
        // p->queticks=9;
        // else if(currticks==9)
        // p->queticks=15;
       // printf("2. %d %d %d %d %d\n",p->pid,p->que0time,p->que1time,p->que2time,p->que3time);
       
        yield();
      }
      else if(p->queticks>0)
        {
          
          p->queticks--;
          }
    }

#endif
#endif
#endif
  //  if (which_dev == 2 && p->queticks==0)
  //    yield();
  usertrapret();
}

//
// return to user space
//
void usertrapret(void)
{
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap;
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64))trampoline_userret)(satp);

  int which_dev = devintr();
  if ((which_dev) != 0)
  {

    if (which_dev == 2)
    {
      if (p->alarm_on == 0)
      {
        // Save trapframe
        p->alarm_on=1;
        struct trapframe *tf = kalloc();   // allocate mem for new trapframe
        memmove(tf, p->trapframe, PGSIZE); // copies current trapframe contents to allocated tf, saving current CPU state
        p->alarm_tf = tf;
        p->alarm_on = 1;
        p->cur_ticks++;
        if (p->cur_ticks >= p->ticks)
          p->trapframe->epc = p->handler; // updates epc (Exception Program Counter) to the next instruction when an interrupt occurs
      }
    }
  }
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();
  if ((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if (intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  if ((which_dev = devintr()) == 0)
  {
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
   if (which_dev == 2 && myproc() != 0 && myproc()->state != RUNNING)
   {
    #ifdef FCFS
    yield();
    #endif
   }

   
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
  {
    #ifdef FCFS
      //   if(proc && proc->killed && (tf->cs&3) == DPL_USER)
      // exit();
      // printf("3. hiii");
    #else
    #ifdef MLFQ
    struct proc *p = myproc();
      if(p->queticks==0)
      {
       if(p->priority!=3)
            p->priority++;
        if(p->priority==1)
          p->que1time=ticks;
          else if(p->priority==2)
          p->que2time=ticks;
          else if(p->priority==3)
          p->que3time=ticks;
       if(p->prevticks==1)
         {
          p->queticks=3;
          p->prevticks=3;
         }
       else if(p->prevticks==3)
         {
          p->queticks=9;
          p->prevticks=9;
         }
       else if(p->prevticks==9)
         {
          p->queticks=15;
          p->prevticks=15;
         }
        // else if(currticks==3)
        // p->queticks=9;
        // else if(currticks==9)
        // p->queticks=15;
       // printf("3. %d %d %d %d %d\n",p->pid,p->que0time,p->que1time,p->que2time,p->que3time);
        yield();
      }
      else if(p->queticks>0)
        p->queticks--;

    #else
        yield();

    #endif
    #endif
  }
  if (which_dev == 1 && myproc() != 0 && myproc()->state == RUNNING) // I/O interrupt
  {
    
    #ifdef MLFQ
    //struct proc* p=myproc();
   // printf("4. %d %d %d %d %d\n",p->pid,p->que0time,p->que1time,p->que2time,p->que3time);
    yield();
    #else
    #ifdef FCFS
    // printf("4. hiii");
    //don't yield
    #endif
    #endif
    
  }
  if (which_dev == 1 && myproc() != 0 && myproc()->state != RUNNING)
   {
    #ifdef FCFS
    yield();
    #endif
   }

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
  acquire(&tickslock);
  ticks++;
  update_time();
  // for (struct proc *p = proc; p < &proc[NPROC]; p++)
  // {
  //   acquire(&p->lock);
  //   if (p->state == RUNNING)
  //   {
  //     printf("here");
  //     p->rtime++;
  //   }
  //   // if (p->state == SLEEPING)
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
  release(&tickslock);
}

// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
      (scause & 0xff) == 9)
  {
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if (irq == UART0_IRQ)
    {
      uartintr();
    }
    else if (irq == VIRTIO0_IRQ)
    {
      virtio_disk_intr();
    }
    else if (irq)
    {
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
  {
    // software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if (cpuid() == 0)
    {
      clockintr();
    }

    // acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  }
  else
  {
    return 0;
  }
}

