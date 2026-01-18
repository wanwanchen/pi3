#include <fcntl.h>
#include <stdio.h>
#include <linux/i2c-dev.h>
#include <stdint.h>
#include <sys/ioctl.h>
#include <unistd.h>

int main(void)
{
    const char *dev = "/dev/i2c-1";
    int chip = 0x50;
    uint8_t memaddr = 0x00;
    uint8_t data = 0;

    int fd = open(dev, O_RDWR);
    if(fd < 0){
        perror("open");
        return 1;
    }

    if(ioctl(fd, I2C_SLAVE, chip) <0){
        perror("ioctl");
        return 1;
    
    }

    if(write(fd, &memaddr, 1) != 1){
        perror("write memaddr");
        return 1;
    }


    if(read(fd, &data, 1) != 1){
        perror("read memaddr");
        return 1;
    }
    printf("EEPROM [0x%02X] = 0x%02X\n", memaddr, data);

    close(fd);
    return 0;
}
