#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
BIN="$WORK/e-003-unwrap-expect-hygiene"
rustc --edition=2021 -O -D warnings main.rs -o "$BIN"

"$BIN" good

set +e
stderr="$("$BIN" unwrap-bad 2>&1 >/dev/null)"
rc=$?
set -e

echo "unwrap-mode: exit=$rc (101 = panic)"
if grep -q 'panicked at' <<<"$stderr"; then
  echo "unwrap-mode: stderr-panicked=yes"
else
  echo "unwrap-mode: stderr-panicked=no"
fi
if grep -q 'RUST_BACKTRACE' <<<"$stderr"; then
  echo "unwrap-mode: backtrace-hint=yes"
else
  echo "unwrap-mode: backtrace-hint=no"
fi
if grep -q 'context attached' <<<"$stderr"; then
  echo "unwrap-mode: context-in-message=yes"
else
  echo "unwrap-mode: context-in-message=no"
fi
