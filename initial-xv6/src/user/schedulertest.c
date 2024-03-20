#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define NFORK 10
#define IO 5

// struct semaphore
// {
//   int count;
// };

// void sem_create(struct semaphore *s, int count) {
//   s->count = count;
// }

// void sem_wait(struct semaphore *s) {
//   while (s->count <= 0) {
//     // Busy-wait until the semaphore is signaled
//   }
//   s->count--;
// }

// void sem_signal(struct semaphore *s) {
//   s->count++;
// }

int main()
{
  int n, pid;
  int wtime, rtime;
  int twtime = 0, trtime = 0;
  // printf("hi");
  // struct semaphore sem1;
  // sem1.count = 1;
  // sem_create(&sem1, 1);
  // sem1->count=1;
  for (n = 0; n < NFORK; n++)
  {
    pid = fork();
    if (pid < 0)
    {
      break;
    }
    if (pid == 0)
    {
      if (n < IO)
      {
        // sem_wait(&sem1);
        // while (sem1.count <= 0)
        // {
        //   // Busy-wait until the semaphore is signaled
        // }
        //sem1.count--;
        sleep(200); // IO bound processes
        //sem1.count++;
      }
      else
      {
        for (volatile int i = 0; i < 1000000000; i++)
        {
        } // CPU bound process
      }
      //printf("Process %d finished\n", n);
      
      exit(0);
    }
  }
  for (; n > 0; n--)
  {
    if (waitx(0, &wtime, &rtime) >= 0)
    {
      trtime += rtime;
      twtime += wtime;
    }
  }
  printf("Average rtime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
  exit(0);
}