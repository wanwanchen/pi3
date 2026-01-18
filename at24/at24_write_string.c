#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

static int write_byte(int fd, uint8_t memaddr, uint8_t value)
{
    // 一定要同一個 write() 送出 [memaddr][data]
    uint8_t buf[2] = { memaddr, value };
    if (write(fd, buf, 2) != 2)
        return -1;

    // AT24C02 寫入週期通常 ~5ms，保守用 6ms
    usleep(6000);
    return 0;
}

static int read_byte(int fd, uint8_t memaddr, uint8_t *out)
{
    // 讀：先寫 memaddr（指定位址），再 read 1 byte
    if (write(fd, &memaddr, 1) != 1)
        return -1;
    if (read(fd, out, 1) != 1)
        return -1;
    return 0;
}

int main(void)
{
    const char *dev  = "/dev/i2c-1";
    int chip = 0x50;

    uint8_t start = 0x00;           // 從 EEPROM 0x00 開始寫
    const char *s = "Hello World";  // 你要寫入的字串

    int fd = open(dev, O_RDWR);
    if (fd < 0) { perror("open"); return 1; }

    if (ioctl(fd, I2C_SLAVE, chip) < 0) {
        perror("ioctl I2C_SLAVE");
        return 1;
    }

    // 1) 寫入字串（含 '\0'，當作 C string）
    //    i <= strlen(s) => 最後會寫入結尾 '\0'
    for (size_t i = 0; i <= strlen(s); i++) {
        uint8_t addr = (uint8_t)(start + i);
        uint8_t val  = (uint8_t)s[i];   // s[strlen] 會是 '\0'

        if (write_byte(fd, addr, val) != 0) {
            perror("write_byte");
            return 1;
        }
    }

    // 2) 讀回並印出（遇到 '\0' 停）
    printf("Read back: ");
    for (int i = 0; i < 64; i++) { // 最多讀 64 bytes 防呆
        uint8_t b = 0;
        uint8_t addr = (uint8_t)(start + i);

        if (read_byte(fd, addr, &b) != 0) {
            perror("read_byte");
            return 1;
        }

        if (b == 0) break; // '\0' 結尾
        putchar((b >= 32 && b <= 126) ? b : '.');
    }
    putchar('\n');

    close(fd);
    return 0;
}

