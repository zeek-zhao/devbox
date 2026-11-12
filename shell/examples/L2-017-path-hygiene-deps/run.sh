#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-017-path-hygiene-deps.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh >"$WORK/ok.out"
[[ "$(cat "$WORK/ok.out")" == 'deps=ok' ]]

mkdir -p "$WORK/fakebin"
ln -s "$(command -v bash)" "$WORK/fakebin/bash"
if PATH="$WORK/fakebin" bash demo.sh >"$WORK/bad.out" 2>"$WORK/bad.err"; then
  echo 'missing deps should fail' >&2
  exit 1
fi
grep -q 'missing: awk sed grep' "$WORK/bad.err"
[[ ! -s "$WORK/bad.out" ]]
printf 'deps=ok missing-detected=awk+sed+grep\n'
