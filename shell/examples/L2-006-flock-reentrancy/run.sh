#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-006-flock-reentrancy.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

mkfifo "$WORK/ready" "$WORK/release"
bash demo.sh hold "$WORK/lock" "$WORK/ready" "$WORK/release" &
worker=$!
exec 8<"$WORK/ready"
IFS= read -r ready <&8
test "$ready" = "locked"

held="$(bash demo.sh compete "$WORK/lock")"
printf 'while-held=%s\n' "$held"
printf 'release\n' >"$WORK/release"
wait "$worker"

released="$(bash demo.sh compete "$WORK/lock")"
printf 'after-release=%s\n' "$released"
