#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-019-manifest-install-uninstall.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/root/pkgs"
printf 'unrelated\n' >"$WORK/root/pkgs/extra.txt"

[[ "$(bash demo.sh "$WORK/root" install manifest.txt)" == 'installed=3' ]]
[[ -f "$WORK/root/pkgs/nginx/marker" ]]

[[ "$(bash demo.sh "$WORK/root" uninstall manifest.txt)" == 'removed=3' ]]
[[ ! -e "$WORK/root/pkgs/nginx" ]]
[[ ! -e "$WORK/root/pkgs/redis" ]]
[[ ! -e "$WORK/root/pkgs/node" ]]
[[ -f "$WORK/root/pkgs/extra.txt" ]]
printf 'manifest=install-3 uninstall-3 extra-untouched\n'
