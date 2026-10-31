#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L4-005-prototype"
rm -rf "$OUT"
mkdir -p "$OUT"
javac --release 21 -Xlint:all -Werror -d "$OUT" src/Main.java
java -cp "$OUT" Main
