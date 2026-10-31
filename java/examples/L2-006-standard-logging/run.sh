#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L2-006-standard-logging"
rm -rf "$OUT"
mkdir -p "$OUT"
javac -d "$OUT" src/Main.java
java -cp "$OUT" Main 2> "$OUT/log.txt"
test "$(wc -l < "$OUT/log.txt")" -eq 1
grep -Fxq 'INFO:index-ready' "$OUT/log.txt"
