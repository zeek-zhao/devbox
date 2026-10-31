#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L3-001-binary-format"
rustc -O main.rs -o "$OUT"
"$OUT"
