#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-010-custom-errors"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
