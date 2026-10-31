#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-015-generic-bounds"
rustc -O main.rs -o "$OUT"
"$OUT"
