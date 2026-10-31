#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DEFAULT_LANGS=(cpp go rust shell python java)
LANGS=()
if [ "$#" -eq 0 ]; then
  LANGS=("${DEFAULT_LANGS[@]}")
else
  for lang in "$@"; do
    case "$lang" in
      cpp|go|rust|shell|python|java) LANGS+=("$lang") ;;
      *) printf '未知语言：%s\n' "$lang" >&2; exit 2 ;;
    esac
  done
fi

TAG="${TAG:-latest}"
passed=0
skipped=0
failed=0

for lang in "${LANGS[@]}"; do
  printf '==> %s\n' "$lang"
  check_script="$lang/project/check-runtime.sh"
  if [ ! -f "$check_script" ]; then
    printf '[skip] %s 未提供 check-runtime.sh\n' "$lang"
    skipped=$((skipped + 1))
    continue
  fi

  if output="$(TAG="$TAG" bash "$check_script" 2>&1)"; then
    if printf '%s\n' "$output" | grep -q '^\[skip\]'; then
      printf '%s\n' "$output"
      skipped=$((skipped + 1))
    elif printf '%s\n' "$output" | grep -q '^\[pass\]'; then
      printf '%s\n' "$output"
      passed=$((passed + 1))
    else
      printf '%s\n' "$output" | tail -n 10
      printf '[fail] %s check-runtime.sh 未输出 [pass] 或 [skip]\n' "$lang"
      failed=$((failed + 1))
    fi
  else
    rc=$?
    printf '%s\n' "$output" | tail -n 10
    printf '[fail] %s check-runtime.sh 退出码 %s\n' "$lang" "$rc"
    failed=$((failed + 1))
  fi
done

printf '%s\n' '------------------------------------------------------------------'
printf 'M4 检查点：通过 %s / 跳过 %s / 失败 %s\n' "$passed" "$skipped" "$failed"

if [ "$failed" -gt 0 ]; then
  exit 1
fi
