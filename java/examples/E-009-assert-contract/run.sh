#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-E-009-assert-contract"
rm -rf "$OUT"
mkdir -p "$OUT"
javac -d "$OUT" src/Main.java
java -ea -cp "$OUT" Main
