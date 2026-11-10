#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-java-E-013-exit-code-protocol"
rm -rf "$OUT"
mkdir -p "$OUT"
javac -d "$OUT" src/Main.java src/Probe.java
java -cp "$OUT" Main
java -cp "$OUT" Probe usage && probe_rc=0 || probe_rc=$?
echo "probe-usage-exit: $probe_rc"
java -cp "$OUT" Probe data && probe_rc=0 || probe_rc=$?
echo "probe-data-exit: $probe_rc"
java -cp "$OUT" Probe ok && probe_rc=0 || probe_rc=$?
echo "probe-ok-exit: $probe_rc"
