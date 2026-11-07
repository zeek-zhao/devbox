#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-E-005-box-dyn-error"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
