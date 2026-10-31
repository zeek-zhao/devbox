#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-011-failure-diagnostics.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

if bash demo.sh "$WORK/missing-config" "$WORK/result" >"$WORK/stdout" 2>"$WORK/stderr"; then
  printf '%s\n' 'expected config read failure' >&2
  exit 1
fi
grep -Fq 'operation failed: read-config' "$WORK/stderr"
[[ ! -s "$WORK/stdout" ]]
printf '%s\n' 'failure: read-config diagnosed; nonzero status preserved'
