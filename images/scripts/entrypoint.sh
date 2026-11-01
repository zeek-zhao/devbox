#!/usr/bin/env bash
set -euo pipefail

# 默认以非 root 用户 dev 运行。需要 root 时可用 -e DEVBOX_AS_ROOT=1、
# -e HOST_UID=0，或 docker run --entrypoint bash 显式绕过入口脚本。

if [ "$#" -eq 0 ]; then
  set -- bash
fi

# 非 root 启动（例如 docker run --user 2000:2000）：已经是目标身份，直接执行。
if [ "$(id -u)" -ne 0 ]; then
  exec "$@"
fi

# 显式要求 root；容器内无法区分镜像默认 root 与 --user root。
if [ "${DEVBOX_AS_ROOT:-0}" = "1" ] || [ "${HOST_UID:-}" = "0" ]; then
  exec "$@"
fi

HOST_UID="${HOST_UID:-1000}"
HOST_GID="${HOST_GID:-1000}"

getent passwd dev >/dev/null || { echo "镜像里没有 dev 用户，入口脚本无法降权" >&2; exit 1; }

if [ "$(id -g dev)" != "$HOST_GID" ]; then
  groupmod -o -g "$HOST_GID" dev
fi
if [ "$(id -u dev)" != "$HOST_UID" ]; then
  usermod -o -u "$HOST_UID" dev
fi
chown -R "$HOST_UID:$HOST_GID" /home/dev
exec gosu dev "$@"
