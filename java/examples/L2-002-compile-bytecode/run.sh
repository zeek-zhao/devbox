#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L2-002-compile-bytecode"
rm -rf "$OUT"
mkdir -p "$OUT"
javac --release 21 -Xlint:all -Werror -d "$OUT" src/app/Main.java src/app/Helper.java
java -cp "$OUT" app.Main
BYTECODE="$(javap -c -classpath "$OUT" app.Main)"
if grep -Eq 'invokestatic.*app/Helper.value' <<<"$BYTECODE"; then
  echo "bytecode-call=app/Helper.value"
else
  echo "bytecode-call=missing" >&2
  exit 1
fi
MAJOR="$(javap -verbose -classpath "$OUT" app.Main | grep -F 'major version:')"
if [[ "$MAJOR" != "  major version: 65" ]]; then
  echo "bytecode-major=unexpected" >&2
  exit 1
fi
printf '%s\n' "$MAJOR"
