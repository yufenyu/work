#include "detmp-pthreads.h"

void queue_init(struct queue * que, int size, int threads) {
  pthread_mutex_init(&que->mutex, NULL);
  pthread_cond_init(&que->empty, NULL);
  pthread_cond_init(&que->full, NULL);
  que->head = que->tail = 0;
  que->data = (void **)malloc(sizeof(void*) *size);
  que->size = size;
  que->threads = threads;
  que->end_count = 0;
}

void queue_signal_terminate(struct queue * que) {
  pthread_mutex_lock(&que->mutex);
  que->end_count ++;
  pthread_cond_broadcast(&que->empty);
  pthread_mutex_unlock(&que->mutex);
}

//void *dequeue(struct queue * que) {
void *dequeue(int cino) {
  struct queue* que =  &global_vars.que[cino];
  pthread_mutex_lock(&que->mutex);
  while (que->tail == que->head && (que->end_count) < que->threads) {
	pthread_cond_wait(&que->empty, &que->mutex);
  }
  if (que->tail == que->head && (que->end_count) == que->threads) {
    pthread_cond_broadcast(&que->empty);
    pthread_mutex_unlock(&que->mutex);
    return NULL;
  }
  void* to_buf = que->data[que->tail];
  que->tail ++;
  if (que->tail == que->size) que->tail = 0;
  pthread_cond_signal(&que->full);
  pthread_mutex_unlock(&que->mutex);
//printf("dequeu\n");  
  return to_buf;
}

int enqueue(struct queue* que, void *from_buf) {
  pthread_mutex_lock(&que->mutex);
  while (que->head == (que->tail-1+que->size)%que->size)
    pthread_cond_wait(&que->full, &que->mutex);
  que->data[que->head] = from_buf;
  que->head ++;
  if (que->head == que->size) que->head = 0;
//printf("enqueu\n");  
  pthread_cond_signal(&que->empty);
  pthread_mutex_unlock(&que->mutex);
  return 0;
}


//spmc environment
void spmc_init(int nthreads){
  global_vars.tids = (pthread_t*)malloc(sizeof(pthread_t)*nthreads);
  global_vars.nth = 0;
  global_vars.nqueues = 0;
}

void spmc_destroy(){
  free(global_vars.tids);
}


//thread operations
int thread_alloc(int gid){
  return global_vars.nth++;
}

#define thread_start(id, fn, args) pthread_create((&(global_vars.tids[id])), NULL, fn, args)

#define thread_join(id, b) pthread_join(global_vars.tids[id], b)

//channel operations
int chan_alloc(int cino){
  int id = global_vars.nqueues++;
  queue_init(&(global_vars.que[id]), QUEUE_SZ, 1);	
  return id;
}

void chan_send(spmcchan_t cino, void *addr, size_t sz){
  char *data = (char*)malloc(sz);
  memcpy(data, addr, sz);
  enqueue(&(global_vars.que[cino]), data);	
}

void chan_sendLast(spmcchan_t cino, void *addr, size_t sz){
	chan_send(cino, addr, sz);
}

int chan_setprod(spmcchan_t cino, spaceid_t dsid, int cons){
  return 0;
}

int chan_setcons(spmcchan_t cino, spaceid_t dsid){
  return 0;
}

#define chan_recv(cino, addr)  ((addr) = dequeue(cino))
//(addr = dequeue(&global_vars.que[cino]);)

void spmc_set_copyargs(int flag, int sz){

}

void spmc_set_shareargs(void *addr, int sz){

}

void chan_end_meta(int cnt){
	
}
