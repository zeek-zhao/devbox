#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-036-loop-labels"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
