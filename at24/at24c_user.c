#include <errno.h>
#include <fcntl.h>
#include <linux/i2c-dev.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

static void die(const char *msg) {
    perror(msg);
    exit(1);
}

/*
 * ACK polling (safe, portable, no SMBus dependency):
 * After EEPROM write, it NACKs address until internal write cycle completes.
 *
 * We "probe" by doing a 0-length write (supported on i2c-dev) or 1-byte write
 * if 0-length isn't accepted on your adapter.
 *
 * Implementation:
 *   - Try write(fd, NULL, 0). If it returns 0 => likely ACK.
 *   - If that fails, try a 1-byte dummy write. If it succeeds => ACK.
 *   - Sleep 1ms and retry until timeout.
 *
 * NOTE: The 1-byte dummy write will send 1 data byte, but for AT24C EEPROM
 * this won't corrupt your content because AT24C expects word-address first.
 * However some devices might interpret it differently; if you want absolute
 * purity, use fixed sleep instead.
 */
static int at24c_ack_poll(int fd, int timeout_ms) {
    const int step_us = 1000; // 1ms
    uint8_t dummy = 0x00;

    for (int i = 0; i < timeout_ms; i++) {
        errno = 0;

        // try 0-length write probe
        ssize_t r0 = write(fd, NULL, 0);
        if (r0 == 0) return 0;

        // fallback: 1-byte probe
        ssize_t r1 = write(fd, &dummy, 1);
        if (r1 == 1) return 0;

        usleep(step_us);
    }
    return -1;
}

/*
 * Build address bytes for AT24C word address.
 * addr16 = 0 => 1-byte address
 * addr16 = 1 => 2-byte address (big-endian: high then low)
 */
static int at24c_set_memaddr(uint8_t *buf, size_t buflen, uint32_t memaddr, int addr16) {
    if (!buf) return -1;
    if (!addr16) {
        if (buflen < 1) return -1;
        buf[0] = (uint8_t)(memaddr & 0xFF);
        return 1;
    } else {
        if (buflen < 2) return -1;
        buf[0] = (uint8_t)((memaddr >> 8) & 0xFF);
        buf[1] = (uint8_t)(memaddr & 0xFF);
        return 2;
    }
}

/*
 * Random read:
 * 1) write word address
 * 2) read data
 */
static int at24c_read(int fd, uint32_t memaddr, uint8_t *out, size_t len, int addr16) {
    uint8_t abuf[2];
    int alen = at24c_set_memaddr(abuf, sizeof(abuf), memaddr, addr16);
    if (alen < 0) return -1;

    if (write(fd, abuf, alen) != alen) return -1;
    if (read(fd, out, len) != (ssize_t)len) return -1;
    return 0;
}

/*
 * Page-aware write:
 * - Never cross page boundary in one write transaction.
 * - After each chunk, do ACK polling.
 */
static int at24c_write_paged(int fd,
                            uint32_t memaddr,
                            const uint8_t *data,
                            size_t len,
                            int addr16,
                            size_t page_size,
                            int poll_timeout_ms)
{
    if (page_size == 0) {
        errno = EINVAL;
        return -1;
    }

    size_t off = 0;
    while (off < len) {
        size_t page_off = (memaddr + off) % page_size;
        size_t chunk = page_size - page_off;
        if (chunk > (len - off)) chunk = (len - off);

        // address(2) + data(up to 256)
        uint8_t wbuf[2 + 256];
        if (chunk > 256) {
            errno = EOVERFLOW;
            return -1;
        }

        int alen = at24c_set_memaddr(wbuf, sizeof(wbuf), memaddr + off, addr16);
        if (alen < 0) return -1;

        memcpy(wbuf + alen, data + off, chunk);

        ssize_t need = (ssize_t)alen + (ssize_t)chunk;
        if (write(fd, wbuf, need) != need) return -1;

        if (at24c_ack_poll(fd, poll_timeout_ms) != 0) {
            errno = ETIMEDOUT;
            return -1;
        }

        off += chunk;
    }
    return 0;
}

static int hexval(int c) {
    if ('0' <= c && c <= '9') return c - '0';
    if ('a' <= c && c <= 'f') return 10 + (c - 'a');
    if ('A' <= c && c <= 'F') return 10 + (c - 'A');
    return -1;
}

static int parse_hexbytes(const char *hex, uint8_t **out, size_t *outlen) {
    size_t n = strlen(hex);
    if (n == 0 || (n % 2) != 0) return -1;

    size_t len = n / 2;
    uint8_t *buf = (uint8_t *)malloc(len);
    if (!buf) return -1;

    for (size_t i = 0; i < len; i++) {
        int hi = hexval((unsigned char)hex[2*i]);
        int lo = hexval((unsigned char)hex[2*i + 1]);
        if (hi < 0 || lo < 0) { free(buf); return -1; }
        buf[i] = (uint8_t)((hi << 4) | lo);
    }
    *out = buf;
    *outlen = len;
    return 0;
}

static void usage(const char *p) {
    fprintf(stderr,
        "Usage:\n"
        "  %s r   <i2c-dev> <chip-addr-hex> <memaddr-hex> <len-dec> <addr16:0|1>\n"
        "  %s w   <i2c-dev> <chip-addr-hex> <memaddr-hex> <hex-bytes> <addr16:0|1> <page_size_dec>\n"
        "  %s ws  <i2c-dev> <chip-addr-hex> <memaddr-hex> \"<string>\" <addr16:0|1> <page_size_dec>\n"
        "  %s wsc <i2c-dev> <chip-addr-hex> <memaddr-hex> \"<string>\" <addr16:0|1> <page_size_dec>\n"
        "\n"
        "Notes:\n"
        "  - ws  writes the string WITHOUT the trailing NUL (\\\\0)\n"
        "  - wsc writes the string WITH the trailing NUL (\\\\0)\n"
        "\n"
        "Examples:\n"
        "  %s r   /dev/i2c-1 0x50 0x00 16 0\n"
        "  %s w   /dev/i2c-1 0x50 0x00 DEADBEEF 0 8\n"
        "  %s ws  /dev/i2c-1 0x50 0x00 \"Hello World\" 0 8\n"
        "  %s wsc /dev/i2c-1 0x50 0x10 \"Hello\" 0 8\n",
        p, p, p, p, p, p, p, p);
}

int main(int argc, char **argv) {
    if (argc < 2) { usage(argv[0]); return 2; }

    const char *cmd = argv[1];

    // -------- read --------
    if (!strcmp(cmd, "r")) {
        if (argc != 7) { usage(argv[0]); return 2; }
        const char *dev = argv[2];
        int chip = (int)strtol(argv[3], NULL, 0);
        uint32_t memaddr = (uint32_t)strtoul(argv[4], NULL, 0);
        size_t len = (size_t)strtoul(argv[5], NULL, 0);
        int addr16 = atoi(argv[6]);

        int fd = open(dev, O_RDWR);
        if (fd < 0) die("open i2c-dev");
        if (ioctl(fd, I2C_SLAVE, chip) < 0) die("ioctl I2C_SLAVE");

        uint8_t *buf = (uint8_t *)malloc(len);
        if (!buf) die("malloc");
        if (at24c_read(fd, memaddr, buf, len, addr16) != 0) die("at24c_read");

        for (size_t i = 0; i < len; i++) {
            printf("%02X%s", buf[i], (i + 1) % 16 == 0 ? "\n" : " ");
        }
        if (len % 16 != 0) printf("\n");

        free(buf);
        close(fd);
        return 0;
    }

    // -------- write hex bytes --------
    if (!strcmp(cmd, "w")) {
        if (argc != 8) { usage(argv[0]); return 2; }
        const char *dev = argv[2];
        int chip = (int)strtol(argv[3], NULL, 0);
        uint32_t memaddr = (uint32_t)strtoul(argv[4], NULL, 0);
        const char *hexbytes = argv[5];
        int addr16 = atoi(argv[6]);
        size_t page_size = (size_t)strtoul(argv[7], NULL, 0);

        uint8_t *data = NULL;
        size_t len = 0;
        if (parse_hexbytes(hexbytes, &data, &len) != 0) {
            fprintf(stderr, "Invalid hex-bytes. Example: DEADBEEF\n");
            return 2;
        }

        int fd = open(dev, O_RDWR);
        if (fd < 0) die("open i2c-dev");
        if (ioctl(fd, I2C_SLAVE, chip) < 0) die("ioctl I2C_SLAVE");

        if (at24c_write_paged(fd, memaddr, data, len, addr16, page_size, 50) != 0)
            die("at24c_write_paged");

        free(data);
        close(fd);
        printf("OK\n");
        return 0;
    }

    // -------- write string (ws/wsc) --------
    if (!strcmp(cmd, "ws") || !strcmp(cmd, "wsc")) {
        if (argc != 8) { usage(argv[0]); return 2; }
        const char *dev = argv[2];
        int chip = (int)strtol(argv[3], NULL, 0);
        uint32_t memaddr = (uint32_t)strtoul(argv[4], NULL, 0);
        const char *str = argv[5];
        int addr16 = atoi(argv[6]);
        size_t page_size = (size_t)strtoul(argv[7], NULL, 0);

        const uint8_t *data = (const uint8_t *)str;
        size_t len = strlen(str);
        if (!strcmp(cmd, "wsc")) len += 1; // include trailing '\0'

        int fd = open(dev, O_RDWR);
        if (fd < 0) die("open i2c-dev");
        if (ioctl(fd, I2C_SLAVE, chip) < 0) die("ioctl I2C_SLAVE");

        if (at24c_write_paged(fd, memaddr, data, len, addr16, page_size, 50) != 0)
            die("at24c_write_paged");

        close(fd);
        printf("OK\n");
        return 0;
    }

    usage(argv[0]);
    return 2;
}

