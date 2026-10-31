#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-031-drop-order"
rustc --edition=2021 -O main.rs -o "$OUT"
"$OUT"
