#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-E-015-thread-error-propagation"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
