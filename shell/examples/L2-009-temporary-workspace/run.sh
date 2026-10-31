#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-009-temporary-workspace.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh "$WORK/first.path" >"$WORK/first.out" &
first_pid=$!
bash demo.sh "$WORK/second.path" >"$WORK/second.out" &
second_pid=$!
wait "$first_pid"
wait "$second_pid"

first_path="$(cat "$WORK/first.path")"
second_path="$(cat "$WORK/second.path")"
[[ "$first_path" != "$second_path" ]]
[[ ! -e "$first_path" && ! -e "$second_path" ]]
printf '%s\n' 'workspace: unique and cleaned'
