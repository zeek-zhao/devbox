#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-020-iterator-ownership"
rustc -O main.rs -o "$OUT"
"$OUT"
