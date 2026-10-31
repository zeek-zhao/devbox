#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-003-bats-run-assertions.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

export TMPDIR="$WORK"
bats --tap assertions.bats
