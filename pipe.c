#include <unistd.h>
#include <stdio.h>
#include <string.h>



int main(){
    int fd[2]; //0 = read, 1 = write
    char inbuffer[10];
    char charbuffer[10];
    
    memset(&charbuffer, 0,sizeof(charbuffer));

    if(pipe(fd) == -1)
    {
      return -1;  
    }
    
    printf("Please input message...\n");
    //scanf("%s", &inbuffer);
    
    fgets(inbuffer, sizeof(inbuffer), stdin);
    write(fd[1], &inbuffer, sizeof(inbuffer));
    read(fd[0], &charbuffer, sizeof(charbuffer));

    printf("read buffer= %s\n", charbuffer);

    return 0;



}
