#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-rust-L1-026-arc-mutex"
rustc --edition=2021 -O main.rs -o "$OUT"
"$OUT"
