#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-015-dry-run-plan-apply.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

bash demo.sh "$WORK/target" --dry-run >"$WORK/plan"
grep -q 'would create' "$WORK/plan"
[[ ! -e "$WORK/target" ]]

bash demo.sh "$WORK/target"
[[ -f "$WORK/target/app.conf" ]]
printf 'dryrun=plan-only apply=applied\n'
