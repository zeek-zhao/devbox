#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-L2-009-module-layers"
rm -rf "$OUT"
mkdir -p "$OUT/classes"
trap 'rm -rf "$OUT"' EXIT

mapfile -t SOURCES < <(find src -name '*.java' -print | sort)
javac -encoding UTF-8 -d "$OUT/classes" "${SOURCES[@]}"
java -cp "$OUT/classes" client.Main "$OUT"
