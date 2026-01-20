````md
# AT24C02 EEPROM on Raspberry Pi (I2C) Quick Guide

This README shows how to scan the I2C bus, dump EEPROM contents, and access an AT24C02 EEPROM using Linux tools and the kernel `at24` driver. It also includes an example workflow to convert a JSON config into a `.bin` and flash it into EEPROM.

---

## Environment

- Board: Raspberry Pi 3 (or compatible)
- I2C Bus: `i2c-1`
- EEPROM: AT24C02 (address `0x50`)
- Optional I2C Mux: TCA9548A (address `0x70`)

> EEPROM size reminder: AT24C02 is **2 Kbit = 256 bytes**.

---

## 1) Scan I2C Bus

Scan all devices on I2C bus 1:

```bash
sudo i2cdetect -y 1 -r
````

Expected example:

* `0x50` → AT24C02
* `0x70` → TCA9548A (if used)

---

## 2) Dump EEPROM Data (Userspace)

### Quick dump

```bash
sudo i2cdump -y 1 0x50
```

### Dump in byte mode

```bash
sudo i2cdump -y 1 0x50 b
```

Example output:

```text
sudo i2cdump -y 1 0x50 b
 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f    0123456789abcdef
00: 53 65 6c 6c 6f 20 57 6f 72 6c 64 00 ff ff ff ff    Sello World.....
10: bb ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ?...............
20: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
30: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
40: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
50: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
60: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
70: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
80: ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff    ................
```

Notes:

* `0xFF` is common for empty/unwritten EEPROM bytes.

---

## 3) Use Linux Kernel Driver (`at24`)

### 3.1 Load driver module

```bash
sudo modprobe at24
```

### 3.2 Bind EEPROM device (`24c02 @ 0x50`)

This will create a device node like: `/sys/bus/i2c/devices/1-0050`

```bash
echo 24c02 0x50 | sudo tee /sys/bus/i2c/devices/i2c-1/new_device
```

Check:

```bash
ls -l /sys/bus/i2c/devices/ | grep 1-0050
```

---

### 3.3 Unbind driver (optional)

If you want to detach the driver:

```bash
echo 1-0050 | sudo tee /sys/bus/i2c/drivers/at24/unbind
```

---

### 3.4 Dump EEPROM via sysfs

The EEPROM data is exposed as a binary file:

```bash
sudo hexdump -C /sys/bus/i2c/devices/1-0050/eeprom | head
```

---

### 3.5 Write EEPROM via `dd` (Flash a .bin file)

Example: write `config.bin` into EEPROM from offset 0:

```bash
sudo dd if=config.bin of=/sys/bus/i2c/devices/1-0050/eeprom bs=1 seek=0 conv=fsync
```

Tips:

* `bs=1` means write byte-by-byte (safe but slower)
* `seek=0` means start writing at EEPROM address 0
* `conv=fsync` ensures data is flushed

Warnings:

* AT24C02 uses **page write** internally (commonly 8 or 16 bytes/page depending on variant)
* EEPROM has limited write endurance; avoid excessive repeated writes

---

## 4) Raspberry Pi 3 <-> TCA9548A <-> AT24C02

If your EEPROM is behind a TCA9548A I2C multiplexer:

### 4.1 Detect TCA9548A

```bash
sudo i2cdetect -y 1
```

You should see:

* `0x70` → TCA9548A

---

### 4.2 Select TCA9548A channel

TCA9548A is controlled by writing **1 byte bitmask** to its I2C address:

* `bit0 = channel 0`
* `bit1 = channel 1`
* ...
* `bit7 = channel 7`

Examples:

```bash
sudo i2cset -y 1 0x70 0x01   # enable channel 0
sudo i2cset -y 1 0x70 0x02   # enable channel 1
sudo i2cset -y 1 0x70 0x04   # enable channel 2
```

After selecting a channel, the downstream EEPROM (0x50) becomes visible.

---

## 5) Rescan I2C Bus (after switching channel)

```bash
sudo i2cdetect -y 1 -r
```

You should see `0x50` on `i2c-1` after the channel is enabled.

---

## 6) JSON -> BIN -> Flash EEPROM (Example Workflow)

This example stores a JSON config as raw bytes (ASCII/UTF-8) into EEPROM.

### 6.1 Create `config.json`

```json
{
  "board": "at24",
  "serial": "SN12345678",
  "mac": "sandy"
}
```

### 6.2 Convert JSON to BIN (raw bytes)

```bash
cat config.json > config.bin
```

Verify:

```bash
hexdump -C config.bin
```

### 6.3 Bind EEPROM (if not bound yet)

```bash
sudo modprobe at24
echo 24c02 0x50 | sudo tee /sys/bus/i2c/devices/i2c-1/new_device
```

### 6.4 Flash `config.bin` into EEPROM (sysfs)

```bash
sudo dd if=config.bin of=/sys/bus/i2c/devices/1-0050/eeprom bs=1 seek=0 conv=fsync
```

### 6.5 Read back and confirm

Binary view:

```bash
sudo hexdump -C /sys/bus/i2c/devices/1-0050/eeprom | head
```

Plain text view (for JSON-as-text use case):

```bash
sudo cat /sys/bus/i2c/devices/1-0050/eeprom | head
```

---

## 7) Notes / Common Issues

### 7.1 Cannot see `0x50`

* If using TCA9548A, you **must enable a channel first**
* Check wiring: SDA/SCL + pull-up resistors
* Make sure I2C is enabled:

  * `sudo raspi-config`
  * Interfacing Options → I2C

### 7.2 `hexdump` output doesn't look like text

* `hexdump -C` shows **raw binary bytes**
* If your program prints `48 65 6C ...` as **text characters** (ASCII), `hexdump` will show `34 38 20 36 35 ...` because it's dumping the characters `'4' '8' ' '` etc.

### 7.3 EEPROM capacity

AT24C02 total capacity is **256 bytes**. Keep your `config.bin` <= 256 bytes:

```bash
ls -l config.bin
```

---

## Quick Summary

| Task                      | Command                                                                              |
| ------------------------- | ------------------------------------------------------------------------------------ |
| Scan I2C devices          | `sudo i2cdetect -y 1 -r`                                                             |
| Dump EEPROM via userspace | `sudo i2cdump -y 1 0x50 b`                                                           |
| Load kernel driver        | `sudo modprobe at24`                                                                 |
| Bind EEPROM               | `echo 24c02 0x50 \| sudo tee /sys/bus/i2c/devices/i2c-1/new_device`                  |
| Read EEPROM (sysfs)       | `sudo hexdump -C /sys/bus/i2c/devices/1-0050/eeprom`                                 |
| Write EEPROM (sysfs)      | `sudo dd if=config.bin of=/sys/bus/i2c/devices/1-0050/eeprom bs=1 seek=0 conv=fsync` |
| Enable TCA9548A channel   | `sudo i2cset -y 1 0x70 0x01`                                                         |

```
```

