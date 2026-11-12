#!/usr/bin/env bash
# 只加载白名单内的配置键，白名单外的键一律拒绝。
set -euo pipefail

ALLOWED=(server port retries)

main() {
  local config="$1"
  declare -A loaded
  local rejected=""

  while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    local ok=""
    local a
    for a in "${ALLOWED[@]}"; do
      [[ "$key" == "$a" ]] && {
        ok=1
        break
      }
    done
    if [[ -n "$ok" ]]; then
      loaded["$key"]="$value"
    else
      rejected="${rejected:+$rejected,}$key"
    fi
  done <"$config"

  [[ "${#loaded[@]}" -eq 3 ]]
  [[ "${loaded[server]}" == "db.internal" ]]
  [[ "${loaded[port]}" == "5432" ]]
  printf 'config=loaded keys=%d rejected=%s\n' "${#loaded[@]}" "$rejected"
}

main "$@"
