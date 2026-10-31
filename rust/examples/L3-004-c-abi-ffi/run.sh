#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-rust-L3-004-c-abi-ffi"
mkdir -p "$WORK"
cc -Wall -Wextra -Werror -c native.c -o "$WORK/native.o"
rustc --edition=2021 main.rs -C "link-arg=$WORK/native.o" -o "$WORK/program"
"$WORK/program"
