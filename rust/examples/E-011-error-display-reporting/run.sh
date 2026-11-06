#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-E-011-error-display-reporting"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
