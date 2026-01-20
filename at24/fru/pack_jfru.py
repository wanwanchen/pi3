#!/usr/bin/env python3
import json, struct, zlib, sys

TOTAL_LEN = 512
HDR_LEN   = 0x40
MAGIC     = b"JFRU"
VERSION   = 0x0001

def put_ascii(buf: bytearray, off: int, size: int, s: str):
    b = (s or "").encode("ascii", errors="ignore")[:size]
    buf[off:off+size] = b + b"\x00" * (size - len(b))

def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} a.json a.bin")
        sys.exit(1)

    jpath, outpath = sys.argv[1], sys.argv[2]
    obj = json.load(open(jpath, "r", encoding="utf-8"))

    img = bytearray(b"\x00" * TOTAL_LEN)

    # --- payload (0x40~end) ---
    payload = memoryview(img)[HDR_LEN:TOTAL_LEN]
    put_ascii(img, HDR_LEN + 0x00, 16, obj.get("serial",""))
    put_ascii(img, HDR_LEN + 0x10, 16, obj.get("part",""))
    put_ascii(img, HDR_LEN + 0x20, 16, obj.get("mac",""))
    mfg_date = int(obj.get("mfg_date", 0))
    flags    = int(obj.get("flags", 0)) & 0xFF
    img[HDR_LEN + 0x30:HDR_LEN + 0x34] = struct.pack("<I", mfg_date)
    img[HDR_LEN + 0x34] = flags

    payload_crc = zlib.crc32(payload) & 0xFFFFFFFF

    # --- header (0x00~0x3F) ---
    img[0x00:0x04] = MAGIC
    img[0x04:0x06] = struct.pack("<H", VERSION)
    img[0x06:0x08] = struct.pack("<H", HDR_LEN)
    img[0x08:0x0C] = struct.pack("<I", TOTAL_LEN)
    img[0x0C:0x10] = struct.pack("<I", payload_crc)

    # header_crc field 清 0 再算
    img[0x10:0x14] = b"\x00\x00\x00\x00"
    header_crc = zlib.crc32(img[0x00:HDR_LEN]) & 0xFFFFFFFF
    img[0x10:0x14] = struct.pack("<I", header_crc)

    with open(outpath, "wb") as f:
        f.write(img)

    print("OK:", outpath)
    print(f"payload_crc=0x{payload_crc:08X} header_crc=0x{header_crc:08X}")

if __name__ == "__main__":
    main()

