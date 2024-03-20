
# Project
-Implemented system calls: sigalarm(interval, handler) system call. If an application calls alarm(n, fn) , then after every n  ”ticks” of CPU time that the program consumes, the kernel will cause application function fn  to be called. When fn  returns, the application will resume where it left off.

And system call sigreturn(), to reset the process state to before the handler was called. This system call needs to be made at the end of the handler so the process can resume where it left off.

-Implemented FCFS and MLFQ

REPORT:
- FCFS: I initialized a creation time variable in proc.h, set to ticks in allocproc. In the for (p = proc; p < &proc[NPROC]; p++){}
        loop, I found process with minimum creation time and ran that first. In trap.c, if scheduler is FCFS, I don't yield control
        to CPU on timer interrupt or I/O call. Hence the entire process will run first.
        Average values: 1 CPU: Average rtime 14,  wtime 156
                        2 CPU: Average rtime 15,  wtime 117
![](<Screenshot (269).png>)
![](<Screenshot (260).png>)


- MLFQ: I initialize a priority and queticks variable in proc.h, set to 0 and 1 in allocproc. I run a priority loop from 0-3 and 
        inside that the for (p = proc; p < &proc[NPROC]; p++){ } loop. We run all processes of queue 0-3, and if there is a timer
        interrupt(devintr()==2), we continue decreasing queticks until it's 0. Then we increase the priority variable, i.e. putting it
        in a new queue, and set queticks to the corresponding time slice of that queue, and yield(). If there's an I/O interrupt (devintr()==1), we can just yield without setting the ticks or changing the queue. Additionally, if a process has not run 3 times, it gets boosted into the higher queue.
        Average values: Average rtime 12,  wtime 148
![](<Screenshot (264).png>)



- RR: Average values: 1 CPU: Average rtime 13,  wtime 151
                      2 CPU: Average rtime 15,  wtime 120
![](<Screenshot (266).png>)
![](<Screenshot (259).png>)


- Values for the graph: PID and Ticks at which processes 5-9 entered each queue:
                        267, 3940, 3942, 3954, 3980
                        268, 3940, 3944, 3958, 3990
                        269, 3940, 3946, 3962, 4000 
                        270, 3940, 3948, 3966, 4010
                        271, 3940, 3950, 3970, 4020
![](<Screenshot (272).png>)