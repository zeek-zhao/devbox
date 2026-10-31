#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L2-008-files-utf-eight"
rm -rf "$OUT"
mkdir -p "$OUT/classes"
trap 'rm -rf "$OUT"' EXIT

javac -encoding UTF-8 -d "$OUT/classes" src/Main.java
java -cp "$OUT/classes" Main "$OUT/data"
