#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-001-script-skeleton-usage.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh deploy >"$WORK/valid.out"
if bash demo.sh --unknown >"$WORK/invalid.out" 2>"$WORK/invalid.err"; then
  echo "invalid arguments were accepted" >&2
  exit 1
fi

grep -Fxq 'usage: demo.sh deploy' "$WORK/invalid.err"
test ! -s "$WORK/invalid.out"
cat "$WORK/valid.out"
printf 'invalid=usage-and-nonzero\n'
