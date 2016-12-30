#define __LIBRARY__
#include<stdio.h>
#include<fcntl.h>
#include<unistd.h>

_syscall2(sem_t*,sem_open,const char*,name,int,value);
_syscall1(int,sem_wait,sem_t*,sem);
_syscall1(int,sem_post,sem_t*,sem);
_syscall1(int,sem_unlink,const char*,name);

#define TOTALNUMS 512
#define CHILDPROCS 8
#define BUFSIZE 10
#define OPENFLAG (O_CREAT|O_TRUNC|O_RDWR)

int main(int argc,char* argv[]){
  sem_t *empty,*full,*mutex;
  int fd;
  pid_t p;
  int buf_in=0;
  int buf_out=0;
  int i,j,data;

  if((empty=sem_open("empty",BUFSIZE))==SEM_FAILED){
    perror("sem_open() error");
    return -1;
  }
  if((full=sem_open("full",0))==SEM_FAILED){
    perror("sem_open() error");
    return -1;
  }
  if((mutex=sem_open("mutex",1))==SEM_FAILED){
    perror("sem_open() error");
    return -1;
  }
  if((fd=open("buffer", OPENFLAG, 0666))==-1){
    perror("open() error");
    return -1;
  }

  lseek(fd, sizeof(int)*BUFSIZE, SEEK_SET);
  write(fd,&buf_out,sizeof(int));

  if((p=fork())==0){
    for(i=0;i<TOTALNUMS;i++){
      sem_wait(empty);
      sem_wait(mutex);
      lseek(fd, sizeof(int)*buf_in, SEEK_SET);
      write(fd,&i,sizeof(int));
      buf_in=(buf_in+1)%BUFSIZE;
      sem_post(mutex);
      sem_post(full);
    }
    return 0;
  }else if(p<0){
    perror("fork() error");
    return -1;
  }

  for(i=0;i<CHILDPROCS;i++){
    if((p=fork())==0){
      for(j=0;j<TOTALNUMS/CHILDPROCS;j++){
	sem_wait(full);
	sem_wait(mutex);
	lseek(fd, sizeof(int)*BUFSIZE, SEEK_SET);
	read(fd, &buf_out, sizeof(int));
	lseek(fd, sizeof(int)*buf_out, SEEK_SET);
	read(fd,&data,sizeof(int));
	buf_out=(buf_out+1)%BUFSIZE;
	lseek(fd, sizeof(int)*BUFSIZE, SEEK_SET);
	write(fd,&buf_out,sizeof(int));
	sem_post(mutex);
	sem_post(empty);
	printf("%d: %d\n", getpid(),data);
	fflush(stdout);
      }
      return 0;
    }else if(p<0){
      perror("fork() error");
      return -1;
    }
  }

  wait(NULL);
  sem_unlink("empty");
  sem_unlink("full");
  sem_unlink("mutex");
  close(fd);

  return 0;
}
