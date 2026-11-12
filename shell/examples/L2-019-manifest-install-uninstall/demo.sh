#!/usr/bin/env bash
# 清单式安装/卸载：只动清单内的条目，清单外的文件不受影响。
set -euo pipefail

ROOT="$1"
OP="$2"
MANIFEST="$3"

items() {
  grep -v '^#' "$MANIFEST" | grep -v '^$'
}

case "$OP" in
  install)
    local_count=0
    while IFS= read -r pkg; do
      mkdir -p "$ROOT/pkgs/$pkg"
      printf 'installed\n' >"$ROOT/pkgs/$pkg/marker"
      local_count=$((local_count + 1))
    done < <(items)
    printf 'installed=%d\n' "$local_count"
    ;;
  uninstall)
    removed=0
    while IFS= read -r pkg; do
      [[ -e "$ROOT/pkgs/$pkg" ]] || continue
      rm -rf "$ROOT/pkgs/$pkg"
      removed=$((removed + 1))
    done < <(items)
    printf 'removed=%d\n' "$removed"
    ;;
  *)
    echo "unknown op: $OP" >&2
    exit 1
    ;;
esac
