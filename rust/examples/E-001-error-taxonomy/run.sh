#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-E-001-error-taxonomy"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
