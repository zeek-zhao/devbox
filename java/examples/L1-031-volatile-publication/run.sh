#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L1-031-volatile-publication"
rm -rf "$OUT"
mkdir -p "$OUT"
javac -d "$OUT" src/Main.java
java -cp "$OUT" Main
BYTECODE="$(javap -c -p -classpath "$OUT" Main)"
if grep -Eq 'getfield.*counter' <<<"$BYTECODE" \
  && grep -Eq 'iadd' <<<"$BYTECODE" \
  && grep -Eq 'putfield.*counter' <<<"$BYTECODE"; then
  echo "volatile-increment=read-add-write"
else
  echo "volatile-increment=unexpected-bytecode" >&2
  exit 1
fi
