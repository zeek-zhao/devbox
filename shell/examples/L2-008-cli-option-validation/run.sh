#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-008-cli-option-validation.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh -a -b value
for option in -x -b; do
  if bash demo.sh "$option" >"$WORK/stdout" 2>"$WORK/stderr"; then
    printf 'unexpected success for %s\n' "$option" >&2
    exit 1
  fi
  grep -Fq 'usage: demo.sh [-a] [-b value]' "$WORK/stderr"
  printf 'rejected %s with usage\n' "$option"
done
