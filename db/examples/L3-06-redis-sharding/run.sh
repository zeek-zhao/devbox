#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
. scripts/lib/common.sh

tb python3 - <<'PY'
def slot(key):
    start = key.find("{")
    if start >= 0:
        end = key.find("}", start + 1)
        if end > start + 1:
            key = key[start + 1:end]
    crc = 0
    for byte in key.encode():
        crc ^= byte << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xffff if crc & 0x8000 else (crc << 1) & 0xffff
    return crc % 16384

cases = [("user:1", slot("user:1")), ("order:{42}:items", slot("order:{42}:items")),
         ("user:{42}:profile", slot("user:{42}:profile"))]
assert cases[1][1] == cases[2][1]
assert cases[0][1] != cases[1][1]
for key, value in cases:
    print(f"{key} -> slot {value}")
print("hash-tag co-location: yes")
PY
