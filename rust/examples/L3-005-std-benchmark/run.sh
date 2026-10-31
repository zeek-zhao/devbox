#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L3-005-std-benchmark"
rustc -O main.rs -o "$OUT"
"$OUT"
