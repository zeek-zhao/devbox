#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-011-data-enums"
rustc -O main.rs -o "$OUT"
"$OUT"
