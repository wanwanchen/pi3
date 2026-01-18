#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <stdint.h>
#include <sys/ioctl.h>
#include <unistd.h>


static int eeprom_wait_ready(int fd, int timeout_ms)
{
    for(int i =0; i<timeout_ms; i++)
    {
        if(write(fd, NULL, 0) == 0)
            return 0;
        usleep(1000);

    }
    return -1;

}


int main()
{
    const char *dev = "/dev/i2c-1";
    int chip = 0x50;

    uint8_t memaddr = 0x00;
    uint8_t value = 0x41; //'A'

    int fd = open(dev, O_RDWR);

    ioctl(fd, I2C_SLAVE, chip);
    
    uint8_t buf[2] = {memaddr, value};

    write(fd, &buf,2);


    usleep(1000);

    close(fd);
    return 0;

}
