#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L3-006-atomics-ordering"
rustc -O main.rs -o "$OUT"
"$OUT"
