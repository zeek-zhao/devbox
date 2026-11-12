#!/usr/bin/env bash
# 符号链接：解析、悬空检测与重链恢复三种状态必须分得清。
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-010-symlink-handling.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

printf 'orig\n' >"$WORK/target.conf"
ln -s "$WORK/target.conf" "$WORK/link.conf"

[[ -L "$WORK/link.conf" && -f "$WORK/link.conf" ]]
[[ "$(readlink -f "$WORK/link.conf")" == "$WORK/target.conf" ]]
[[ "$(cat "$WORK/link.conf")" == orig ]]

rm "$WORK/target.conf"
[[ -L "$WORK/link.conf" ]]
[[ ! -e "$WORK/link.conf" ]]

printf 'new\n' >"$WORK/target.conf"
[[ "$(cat "$WORK/link.conf")" == new ]]
printf 'symlink=resolved dangling-detected relink-ok\n'
