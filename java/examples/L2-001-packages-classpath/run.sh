#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L2-001-packages-classpath"
rm -rf "$OUT"
mkdir -p "$OUT"
javac -d "$OUT" src/app/Main.java src/model/Label.java
java -cp "$OUT" app.Main
