#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-016-resume-state-marker.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

if FAIL_AT=3 bash demo.sh "$WORK"; then
  echo 'first run should fail' >&2
  exit 1
fi
[[ "$(cat "$WORK/state")" -eq 3 ]]

bash demo.sh "$WORK"
[[ "$(sort -u "$WORK/done.log" | wc -l)" -eq 5 ]]
[[ "$(wc -l <"$WORK/done.log")" -eq 5 ]]
printf 'resume=completed redone=0\n'
