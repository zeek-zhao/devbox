#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-008-option-values"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
