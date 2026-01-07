// Compile with $ gcc gpio.c -o gpio
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// Pin modes:
#define INPUT (0)
#define OUTPUT (1)
#define LOW (0)
#define HIGH (1)

typedef struct {
        int     pin;
        char*   fn;
} pin_t;

static pin_t pinopen(int pin, int mode);
static void pinclose(pin_t pin);
static void pinwrite(pin_t pin, int value);
static int pinread(pin_t pin);

int main(int argc, char** argv)
{
        int time = 0;

        if (argc > 1) {
                time = atoi(argv[1]);
        }

        if (time == 0) {
                printf("Usage: water <SECONDS>\n");
                printf("Runs the water pump for the specified number of seconds.\n");
                printf("The pump control signal must be connected to GPIO17!\n");
                return 1;
        }

        // Use GPIO17.
        pin_t waterpin = pinopen(17, OUTPUT);

        pinwrite(waterpin, HIGH);
        sleep(time);
        pinwrite(waterpin, LOW);

        pinclose(waterpin);
        return 0;
}

pin_t pinopen(int pin, int mode)
{
        char*   pinfn = malloc(1024);
        char    dirfn[1024];
        FILE*   dir = NULL;
        FILE*   fp = fopen("/sys/class/gpio/export", "w");
        fprintf(fp, "%d", pin);
        fclose(fp);
        snprintf(dirfn, 1024, "/sys/class/gpio/gpio%d/direction", pin);
        snprintf(pinfn, 1024, "/sys/class/gpio/gpio%d/value", pin);
        while (dir == NULL) {
                dir = fopen(dirfn, "w");
        }
        if (mode == INPUT) {
                fprintf(dir, "in");
        } else {
                fprintf(dir, "out");
        }
        fclose(dir);
        return (pin_t) { pin, pinfn };
}

void pinclose(pin_t pin)
{
        FILE*   fp = fopen("/sys/class/gpio/unexport", "w");
        fprintf(fp, "%d", pin.pin);
        fclose(fp);
        free(pin.fn);
}

void pinwrite(pin_t pin, int value)
{
        FILE*   fp = fopen(pin.fn, "w");
        if (value == LOW) {
                fprintf(fp, "0");
        } else {
                fprintf(fp, "1");
        }
        fclose(fp);
}

int pinread(pin_t pin)
{
        char    buf[2];
        FILE*   fp = fopen(pin.fn, "r");
        size_t  read = fread(buf, 1, 2, fp);
        fclose(fp);
        if (read != 2) {
                return -1;
        } else {
                return (buf[0] == '1') ? HIGH : LOW;
        }
}
