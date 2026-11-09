#!/usr/bin/env bash
# 错误上下文链：多层调用失败时，每一层把「自己是谁、在干什么」追加进同一条诊断，
# 最上层拿到的消息是一条可定位的链，而不是 N 段互不相关的报错。
set -euo pipefail

CHAIN=''

fetch() {
  # 最底层：只有它知道具体的技术原因。
  printf 'fetch: connection refused\n' >&2
  return 7
}

download() {
  local rc=0
  fetch || rc=$?
  CHAIN="download: ${CHAIN}"
  return "$rc"
}

deploy() {
  local rc=0
  download || rc=$?
  CHAIN="deploy: ${CHAIN}"
  return "$rc"
}

main() {
  local rc=0
  deploy || rc=$?
  local layers
  local matches
  matches="$(grep -o ': ' <<<"$CHAIN" | wc -l)"
  layers=$((matches + 1))
  printf 'context chain: %sfetch: connection refused (rc=%d)\n' "$CHAIN" "$rc"
  printf 'chain layers: %d\n' "$layers"
}

main "$@"
