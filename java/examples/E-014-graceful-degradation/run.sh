#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-E-014-graceful-degradation"
rm -rf "$OUT"
mkdir -p "$OUT"
javac -d "$OUT" src/Main.java
java -cp "$OUT" Main
