/*
 ============================================================================
 Name        : main.c
 Author      : why
 Version     :
 Copyright   : by why
 Description : Ansi-style
 ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <semaphore.h>
#include <unistd.h>

//共享缓冲区
#define BUFFER_SIZE 10
typedef struct {
	int id;
    void *data;
} item;
item buffer[BUFFER_SIZE];

int in = 0; //下一个待生产位置
int out = 0; //下一个待消费位置
/*int counter = 0; //会被两个线程同时操作的计数器*/
/*int pro_number = 1; //产品编号*/
int NUM_PRODUCER = 10; //number of producer
sem_t p_sem;
sem_t c_sem;
/*int die = 0;*/
pthread_mutex_t in_lock;

void * produce(void *);
void * consume(void *);

int main(int argc, char **argv) {
	//创建生产者、消费者线程
	pthread_t producer[NUM_PRODUCER], consumer;
    sem_init(&p_sem, 0, BUFFER_SIZE);
    sem_init(&c_sem, 0, 0);
    pthread_mutex_init(&in_lock, NULL);
	int ret1, ret2;

	printf("creating 2 threads----\n");
	ret2 = pthread_create(&consumer, NULL, consume, NULL );
    int i;
    for(i = 0; i < NUM_PRODUCER; i++) {
        ret1 = pthread_create(&producer[i], NULL, produce, (void *) i);
    }
	if (ret1 != 0 || ret2 != 0) {
        printf("create threads failure!\n");
        exit(EXIT_FAILURE);
	}
	printf("create threads success!\n");
	//启动两个线程
    /*sleep(5);*/
    /*die = 1;*/
    /*printf("die = %d\n", die);*/
    for(i = 0; i < NUM_PRODUCER; i++) {
        pthread_join(producer[i], NULL );
    }
	pthread_join(consumer, NULL );

	printf("main thread exit!\n");
	exit(EXIT_SUCCESS);
}

//生产者线程生产产品
void * produce(void *ptr) {
	item production;
    int tid = (int) ptr;
    /*while (1)*/
    int count;
    for(count = 0; count < 10; count++)
    {
        //在等待缓冲区可用之前提前生产好产品
        /*if(die == 1)*/
        /*{*/
            /*printf("producer die\n");*/
            /*break;*/
        /*}*/
        int len = sizeof(char) * 1024 * 4; //4KB
        char * data = (char *) malloc(len);
        int i;
        for(i = 0; i < len; i++)
        {
            data[i] = 'A' + tid % 26;
        }
        data[len] = '\0';
        production.id = tid;
        production.data = (void *)data;
        sem_wait(&p_sem);
        //缓冲区可用了
        //need lock in_lock as multiple producer may contend
        pthread_mutex_lock(&in_lock);
        buffer[in] = production;
        in = (in + 1) % BUFFER_SIZE;
        /*printf("in = %d\n", in);*/
        pthread_mutex_unlock(&in_lock);
        /*printf("tid = % d, 生产产品：%s\n", tid, production.data); //谁能够获取到lock是随机的*/
        /*printf("tid = %d, 生产产品", tid); //谁能够获取到lock是随机的*/
        sem_post(&c_sem);
        /*counter++;*/

	}

	return NULL ;
}

//消费者线程消费产品
void * consume(void * ptr) {
	item production;
    int count;
    for(count = 0; count < NUM_PRODUCER * 10; count++)
    /*while (1)*/
    /*int i;*/
    /*for(i = 0; i < 10; i++)*/
    {
        /*if(die == 1)*/
        /*{*/
            /*printf("consumer die\n");*/
            /*break;*/
        /*}*/
        sem_wait(&c_sem);
        //缓冲区有产品了
        production = buffer[out];
        void *data = production.data;
        buffer[out].id = 0;
        buffer[out].data = NULL;
        out = (out + 1) % BUFFER_SIZE;
        /*printf("消费产品：%p\n", data);*/
        free(data);
        /*counter--;*/
        sem_post(&p_sem);

	}
	return NULL ;
}
