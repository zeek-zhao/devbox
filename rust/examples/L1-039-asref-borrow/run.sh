#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-039-asref-borrow"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
