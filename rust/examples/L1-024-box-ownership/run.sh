#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-024-box-ownership"
rustc --edition=2021 -O main.rs -o "$OUT"
"$OUT"
