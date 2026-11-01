#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-035-if-let-while-let"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
