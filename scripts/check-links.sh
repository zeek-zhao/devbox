#!/usr/bin/env bash
# 文档相对链接检查（#393 · M13-DOC-01）
#
# 只查「本仓 Markdown 之间的相对链接」这一件事：
#   - 只看 git 跟踪的 *.md 里的 ](目标) 写法（跳过代码围栏内）；
#   - 跳过外链（http/https/mailto/ftp）、锚点（#…）、绝对路径（/…）；
#   - 目标去掉 #锚点 与 ?查询串后再 test -e（相对当前 md 所在目录，也接受相对仓库根）；
#   - 白名单 docs/link-check-baseline.txt 里登记的「已知历史问题」不算红
#     （每行 `<文件>:<行>:<链接>`，与 docs/79 §4 的登记一一对应）。
#
# 退出码：0 = 无白名单外死链；1 = 有死链（逐行打印 `文件:行 -> 目标 (缺失)`）。
# 零外部依赖：只用 bash + git + awk/sed/grep/coreutils。
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 2

BASELINE="docs/link-check-baseline.txt"
declare -A allow=()
if [ -f "$BASELINE" ]; then
  while IFS= read -r line; do
    case "$line" in '' | '#'*) continue ;; esac
    allow["$line"]=1
  done <"$BASELINE"
fi

# 中文文件名必须关掉 git 的八进制转义，否则 awk 拿到的会是 "c/docs/\345..." 这种串
missing=0
checked=0
while IFS= read -r file; do
  [ -n "$file" ] || continue
  while IFS=$'\t' read -r lineno target; do
    [ -n "${target:-}" ] || continue
    case "$target" in
      http://* | https://* | mailto:* | '#'* | '/'* | 'tel:'* | 'ftp://*' | 'ftp://'*) continue ;;
    esac
    path="${target%%#*}"
    path="${path%%\?*}"
    [ -n "$path" ] || continue
    path="${path//%20/ }"
    checked=$((checked + 1))
    dir="$(dirname "$file")"
    if [ -e "$dir/$path" ] || [ -e "$path" ]; then
      continue
    fi
    key="$file:$lineno:$target"
    if [ -n "${allow[$key]:-}" ]; then
      continue
    fi
    printf '%s:%s -> %s (缺失)\n' "$file" "$lineno" "$target"
    missing=$((missing + 1))
  done < <(
    awk '
      {
        line = $0
        if (line ~ /^[ ]{0,3}(```|~~~)/) { fence = !fence; next }
        if (fence) next
        rest = line
        while (match(rest, /\]\([^)]*\)/)) {
          target = substr(rest, RSTART + 2, RLENGTH - 3)
          sub(/[ ]+".*$/, "", target)
          print NR "\t" target
          rest = substr(rest, RSTART + RLENGTH)
        }
      }
    ' "$file"
  )
done < <(git -c core.quotePath=false ls-files '*.md' | sort)

printf '链接检查完成：扫描 %d 个相对链接，白名单外死链 %d 个\n' "$checked" "$missing"
[ "$missing" -eq 0 ] || exit 1
