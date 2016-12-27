#ifdef PTHREADS_STATIC
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

#define NEWARRAY(p,t,n) ((p) = malloc((n) * sizeof (t)))
#define DEQ_NUM 1
#define QUEUE_SZ 1024*2014UL
#define MAX_QUEUENUM 1024
#define spmcchan_t int
#define spaceid_t int
#define tid_t int

struct queue {
  int head, tail;
  void ** data;
  int size;
  int threads;
  int end_count;
  pthread_mutex_t mutex;
  pthread_cond_t empty, full;
};

typedef struct global_info{
	pthread_t *tids;
	int nth;
	struct queue que[MAX_QUEUENUM];
	int nqueues;
}global_info_t;

global_info_t global_vars;

//operations about queue
void queue_init(struct queue * que, int size, int threads);
void queue_signal_terminate(struct queue * que);
//void* dequeue(struct queue* que);
void* dequeue(int cino);
int enqueue(struct queue* que, void * from_buf);

//spmc environment
void spmc_init(int nthreads);
void spmc_destroy();

//thread manage
int thread_alloc(int gid);
//void thread_start(int idx, void *(*fn)(void*), void *arg);
//void thread_join(pthread_t idx);

//channel operations
int chan_alloc(int cino);
int chan_setprod(spmcchan_t cino, spaceid_t dsid, int cons);
int chan_setcons(spmcchan_t cino, spaceid_t dsid);
void chan_send(spmcchan_t cino, void *addr, size_t sz);
void chan_sendLast(spmcchan_t cino, void *addr, size_t sz);
void chan_end_meta(int cnt);

#define thread_start(id, fn, args) pthread_create((&(global_vars.tids[id])), NULL, fn, args)

#define thread_join(id) pthread_join(global_vars.tids[id], NULL)

#define chan_recv(a, b) b = dequeue(a)

void spmc_set_copyargs(int flag, int sz);
void spmc_set_shareargs(void *addr, int sz);
#endif
