#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L1-019-lambda-method-reference"
rm -rf "$OUT"
mkdir -p "$OUT/classes"
javac -encoding UTF-8 -d "$OUT/classes" src/Main.java
java -cp "$OUT/classes" Main "$OUT"
