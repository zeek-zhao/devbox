#!/usr/bin/env bash
# umask 决定新文件的默认权限位；077 与 022 两种掩码的落点必须可预测。
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L3-009-umask-file-perms.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

(
  umask 077
  : >"$WORK/secret.txt"
  mkdir "$WORK/secret.d"
)
(
  umask 022
  : >"$WORK/public.txt"
  mkdir "$WORK/public.d"
)

f1="$(stat -c %a "$WORK/secret.txt")"
d1="$(stat -c %a "$WORK/secret.d")"
f2="$(stat -c %a "$WORK/public.txt")"
d2="$(stat -c %a "$WORK/public.d")"
[[ "$f1" == 600 && "$d1" == 700 ]]
[[ "$f2" == 644 && "$d2" == 755 ]]
printf 'umask=077-file-600-dir-700 022-file-644-dir-755\n'
