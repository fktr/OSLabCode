#include<stdio.h>
#include<unistd.h>
#include<time.h>
#include<sys/times.h>
#include<sys/types.h>

#define NUM_CPROC 50
#define LAST_TIME 25 
#define RATE (LAST_TIME/NUM_CPROC)
#define HZ 100

void cpuio_bound(int last,int cpu_time,int io_time);

int main(int argc, char *argv[]){
  pid_t n_cproc[NUM_CPROC];
  int i;

  for(i=0;i<NUM_CPROC;i++){
    n_cproc[i]=fork();
    if(n_cproc[i]==0){
      cpuio_bound(LAST_TIME, RATE*i, LAST_TIME-RATE*i);
      return 0;
    }else if(n_cproc[i]<0){
      printf("Failed to fork child process %d!", i+1);
      return -1;
    }
  }

  for(i=0;i<NUM_CPROC;i++)
    printf("Child PID: %d\n", n_cproc[i]);
  wait(NULL);
  return 0;
}

void cpuio_bound(int last,int cpu_time,int io_time){
  clock_t beg_time,end_time;
  int sleep_time;
  double num;

  while(last>0){
    beg_time=times(NULL);
    num=1.012345;
    do{
      num*=3.141592653;
      end_time=times(NULL);
    }while(((end_time-beg_time)/HZ)<cpu_time);
    last-=(end_time-beg_time)/HZ;
    if(last<0)
      break;

    sleep_time=0;
    while(sleep_time<io_time){
      sleep(1);
      sleep_time++;
    }
    last-=sleep_time;
  }
}
