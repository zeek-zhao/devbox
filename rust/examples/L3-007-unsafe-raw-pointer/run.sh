#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L3-007-unsafe-raw-pointer"
rustc --edition=2021 -O -D warnings main.rs -o "$OUT"
"$OUT"
