#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-004-mutable-borrows"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
