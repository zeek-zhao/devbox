#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
BIN="$WORK/e-002-main-return-result"
rustc --edition=2021 -O -D warnings main.rs -o "$BIN"

echo "== case: ok =="
"$BIN" ok
echo "ok-exit=$?"

echo "== case: bad-config =="
set +e
stderr="$("$BIN" bad-config 2>&1 >/dev/null)"
rc=$?
set -e
echo "bad-config-exit=$rc"
echo "$stderr"
