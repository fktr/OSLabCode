#include<string.h>
#include<errno.h>
#include<asm/segment.h>

char msg[24];

int sys_iam(const char* name){
	char temp[24];
	int i;
	for(i=0;i<24;i++){
		temp[i]=get_fs_byte(name+i);
		if(temp[i]=='\0')
			break;
	}

	int len=strlen(temp);
	if(len>23)
		return -EINVAL;
	strcpy(msg,temp);
	return i;
}

int sys_whoami(char* name, unsigned int size){
	int len=strlen(msg);
	if(len>=size)
		return -EINVAL;

	int i;
	for(i=0;i<size;i++){
		put_fs_byte(msg[i],name+i);
		if(msg[i]=='\0')
			break;
	}
	return i;
}

