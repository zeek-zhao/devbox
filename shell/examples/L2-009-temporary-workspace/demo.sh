#!/usr/bin/env bash
set -euo pipefail

workspace="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-009-temporary-workspace.XXXXXX")"
trap 'rm -rf "$workspace"' EXIT
printf '%s\n' "$workspace" >"$1"
printf '%s\n' 'workspace: created'
