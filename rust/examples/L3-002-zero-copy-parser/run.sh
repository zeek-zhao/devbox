#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L3-002-zero-copy-parser"
rustc -O main.rs -o "$OUT"
"$OUT"
