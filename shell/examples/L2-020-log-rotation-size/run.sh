#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-020-log-rotation-size.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

printf 'old-1\n' >"$WORK/app.log.1"

bash demo.sh "$WORK/app.log" >"$WORK/out"
[[ "$(cat "$WORK/out")" == 'rotation=kept2 current=empty' ]]

[[ -s "$WORK/app.log.2" ]]
[[ "$(wc -c <"$WORK/app.log.1")" -le 512 ]]
[[ ! -s "$WORK/app.log" ]]
[[ ! -e "$WORK/app.log.3" ]]
printf 'rotation=kept2 current=empty\n'
