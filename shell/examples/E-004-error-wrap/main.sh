#!/usr/bin/env bash
# 错误包装：底层命令失败时，外层函数保留它的退出码，再把自己的上下文追加进去。
# 吞码或换码都会让上层拿到一个「不像原错误」的新错误。
set -euo pipefail

fetch_artifact() {
  # 模拟底层命令：网络类失败，rc=22（HTTP >= 400）。
  printf 'fetch-artifact: HTTP 404\n' >&2
  return 22
}

download() {
  local rc=0
  fetch_artifact || rc=$?
  if [ "$rc" -ne 0 ]; then
    printf 'download: fetch-artifact failed while downloading manifest\n' >&2
    return "$rc"
  fi
  return 0
}

deploy() {
  local rc=0
  download || rc=$?
  if [ "$rc" -ne 0 ]; then
    printf 'deploy: download failed while preparing release\n' >&2
    return "$rc"
  fi
  return 0
}

main() {
  local rc=0
  deploy || rc=$?
  printf 'chain: deploy -> download -> fetch-artifact\n'
  printf 'preserved exit code: %d\n' "$rc"
}

main "$@"
