#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-E-008-oom-taxonomy"
rm -rf "$OUT"
mkdir -p "$OUT"
javac -d "$OUT" src/Main.java
java -Xmx16m -cp "$OUT" Main
