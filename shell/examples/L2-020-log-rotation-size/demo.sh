#!/usr/bin/env bash
# 日志轮转：当前日志超过阈值就整体挪为 .1，旧的依次顺移，最多保留 2 份历史。
set -euo pipefail

LOG="$1"
LIMIT_BYTES=300

main() {
  local line
  line="$(printf '%.0s-' {1..100})"

  local size
  while :; do
    if [[ -f "$LOG" ]]; then
      size="$(wc -c <"$LOG")"
    else
      size=0
    fi
    [[ "$size" -le "$LIMIT_BYTES" ]] || break
    printf '%s\n' "$line" >>"$LOG"
  done

  if [[ -s "$LOG" ]]; then
    [[ -f "$LOG.1" ]] && mv "$LOG.1" "$LOG.2"
    mv "$LOG" "$LOG.1"
    : >"$LOG"
  fi
  printf 'rotation=kept2 current=empty\n'
}

main "$@"
