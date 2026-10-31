#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-010-idempotent-steps.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh "$WORK/config"
first_state="$(cat "$WORK/config")"
bash demo.sh "$WORK/config"
second_state="$(cat "$WORK/config")"
[[ "$first_state" == "$second_state" ]]
[[ "$(grep -Fc 'managed=ready' "$WORK/config")" -eq 1 ]]
printf '%s\n' "$second_state"
