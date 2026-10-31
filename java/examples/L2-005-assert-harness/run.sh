#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L2-005-assert-harness"
rm -rf "$OUT"
mkdir -p "$OUT"
javac -d "$OUT" src/Harness.java
java -ea -cp "$OUT" Harness > "$OUT/passing.txt"
grep -Fxq 'passed: 3 failed: 0' "$OUT/passing.txt"
cat "$OUT/passing.txt"
if java -ea -cp "$OUT" Harness injected > "$OUT/injected.txt" 2> "$OUT/injected.err"; then
  echo "injected failure unexpectedly passed" >&2
  exit 1
fi
grep -Fxq 'passed: 2 failed: 1' "$OUT/injected.txt"
test ! -s "$OUT/injected.err"
cat "$OUT/injected.txt"
if java -cp "$OUT" Harness > "$OUT/disabled.txt" 2> "$OUT/disabled.err"; then
  echo "assertions-disabled launch unexpectedly passed" >&2
  exit 1
fi
test ! -s "$OUT/disabled.txt"
grep -Fxq 'assertions-disabled' "$OUT/disabled.err"
echo "assertions-disabled=rejected"
if java -ea -cp "$OUT" Harness direct > "$OUT/direct.txt" 2> "$OUT/direct.err"; then
  echo "direct assertion unexpectedly passed" >&2
  exit 1
fi
test ! -s "$OUT/direct.txt"
grep -Fq 'AssertionError: direct assertion' "$OUT/direct.err"
echo "direct-assertion=failed"
