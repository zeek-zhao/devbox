#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-019-iterator-adaptors"
rustc -O main.rs -o "$OUT"
"$OUT"
