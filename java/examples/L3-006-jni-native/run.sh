#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L3-006-jni-native"
rm -rf "$OUT"
mkdir -p "$OUT/classes" "$OUT/include"
trap 'rm -rf "$OUT"' EXIT

javac -encoding UTF-8 -h "$OUT/include" -d "$OUT/classes" src/NativeProbe.java src/Main.java
JH="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"
gcc -shared -fPIC -I"$JH/include" -I"$JH/include/linux" \
  -I"$OUT/include" -o "$OUT/libprobe.so" src/probe.c
java -Djava.library.path="$OUT" -cp "$OUT/classes" Main "$OUT"
