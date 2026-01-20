#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <linux/i2c-dev.h>
#include <stdint.h>

int read_byte(int fd, char *mem_buffer, int len_count)
{
    if(fd == -1){
        return -1;
    }
    read(fd, mem_buffer, len_count);
    return 1;

}

int main()
{
    const char *dev = "/dev/i2c-1";
    char buffer[256];
    int fd = open(dev, O_RDWR);
    ioctl(fd, I2C_SLAVE, 0x50);

    uint8_t start = 0x00;
   
   uint8_t buf[4] = {start, 0x41, 0x42, 0x43}; 

    //Write 1 byte
    write(fd, buf ,sizeof(buf));
    usleep(10000);


    //Read 256 byte
    write(fd, &start,1);
    //read(fd, &buffer, 256);
    read_byte(fd, buffer, sizeof(buffer));
    
    printf("Read data = %s\n", buffer);
    close(fd);
    return 0;


}
