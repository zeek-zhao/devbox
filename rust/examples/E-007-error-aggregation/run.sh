#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-E-007-error-aggregation"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
