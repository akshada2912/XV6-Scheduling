// // semaphore.c

// #include "semaphore.h"

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
