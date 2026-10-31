#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L2-004-api-javadoc"
rm -rf "$OUT"
mkdir -p "$OUT/api" "$OUT/classes"
javac --release 21 -d "$OUT/classes" src/api/TextPolicy.java
javadoc -quiet -Xdoclint:all -d "$OUT/api" src/api/TextPolicy.java
test -f "$OUT/api/index.html"
test -f "$OUT/api/api/TextPolicy.html"
grep -Fq 'Normalize a required label.' "$OUT/api/api/TextPolicy.html"
grep -Fq 'the normalized label' "$OUT/api/api/TextPolicy.html"
grep -Fq 'if the label is null or blank' "$OUT/api/api/TextPolicy.html"
java -cp "$OUT/classes" api.TextPolicy
