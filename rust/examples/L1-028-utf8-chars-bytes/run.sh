#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-028-utf8-chars-bytes"
rustc --edition=2021 -O main.rs -o "$OUT"
"$OUT"
