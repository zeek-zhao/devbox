#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-004-bats-fixtures.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

export TMPDIR="$WORK"
export FIXTURE_ROOT="$WORK/fixtures"
mkdir -p "$FIXTURE_ROOT"
bats --tap fixtures.bats
test -z "$(find "$FIXTURE_ROOT" -mindepth 1 -print -quit)"
printf 'fixtures=cleaned\n'
