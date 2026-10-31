#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-017-static-dynamic-dispatch"
rustc -O main.rs -o "$OUT"
"$OUT"
