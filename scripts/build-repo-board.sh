#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != "--stdout" ]; }; then
  echo "用法: bash scripts/build-repo-board.sh [--stdout]" >&2
  exit 2
fi

tracks="docs/board-tracks.tsv"
roadmap="docs/ROADMAP.md"
template="docs/board-template.html"
for file in "$tracks" "$roadmap" "$template"; do
  if [ ! -f "$file" ]; then
    echo "缺少看板生成输入：$file" >&2
    exit 2
  fi
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

declare -A declared=()
track_rows="$tmp/tracks"
total=0
projects=0
while IFS=$'\t' read -r dir name project layer; do
  [ -n "$dir" ] || continue
  [[ "$dir" == \#* ]] && continue
  if [ -z "$name" ] || [ -z "$project" ] || [ -z "$layer" ]; then
    echo "board-tracks.tsv 行缺少字段：$dir" >&2
    exit 2
  fi
  if [ -n "${declared[$dir]+x}" ]; then
    echo "board-tracks.tsv 轨道重复：$dir" >&2
    exit 2
  fi
  declared["$dir"]=1
  examples="$dir/examples"
  if [ ! -d "$examples" ]; then
    echo "board-tracks.tsv 声明的轨道不存在：$dir/examples" >&2
    exit 2
  fi
  mapfile -t dirs < <(find "$examples" -mindepth 1 -maxdepth 1 -type d -print | sort)
  count="${#dirs[@]}"
  total=$((total + count))
  if [ -d "$dir/project" ]; then projects=$((projects + 1)); fi
  levels=(0 0 0 0 0 0)
  for path in "${dirs[@]}"; do
    base="${path##*/}"
    if [[ "$base" =~ ^L([0-4])- ]]; then
      level="${BASH_REMATCH[1]}"
      levels[level]=$((levels[level] + 1))
    else
      levels[5]=$((levels[5] + 1))
    fi
  done
  distribution=""
  for level in 0 1 2 3 4; do
    if [ "${levels[$level]}" -gt 0 ]; then
      [ -z "$distribution" ] || distribution+=" · "
      distribution+="L$level ${levels[$level]}"
    fi
  done
  if [ "${levels[5]}" -gt 0 ]; then
    [ -z "$distribution" ] || distribution+=" · "
    distribution+="其他 ${levels[5]}"
  fi
  printf '          <tr><th scope="row">%s</th><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n' \
    "$name" "$count" "$distribution" "$project" "$layer" >> "$track_rows"
done < "$tracks"

if [ "${#declared[@]}" -eq 0 ]; then
  echo "board-tracks.tsv 没有轨道" >&2
  exit 2
fi

while IFS= read -r examples; do
  [ -n "$examples" ] || continue
  dir="${examples#./}"
  dir="${dir%/examples}"
  if [ -z "${declared[$dir]+x}" ]; then
    echo "磁盘上存在未在 board-tracks.tsv 声明的轨道：$dir/examples" >&2
    exit 2
  fi
done < <(find . -mindepth 2 -maxdepth 2 -type d -name examples -print | sort)

milestone_rows="$tmp/milestones"
awk -F'|' '
  function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
  function render(s,    i,c,in_code,out) {
    out = ""
    in_code = 0
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (c == "`") {
        out = out (in_code ? "</code>" : "<code>")
        in_code = !in_code
      } else if (c == "&") out = out "&amp;"
      else if (c == "<") out = out "&lt;"
      else if (c == ">") out = out "&gt;"
      else out = out c
    }
    if (in_code) out = out "</code>"
    return out
  }
  # 只认「里程碑」那一张表：表头开启、遇到非表格行关闭。
  # 不看表头、只按「凑够 5 列」来认，会同时错两头：
  #   - ROADMAP 里新增别的 5 列表格 → 被当成里程碑混进看板；
  #   - 里程碑行少写一列（比如将来加里程碑忘写依据）→ 被静默丢掉，看板悄悄少一行。
  # 所以表内任何一行不完整都必须报错退出，不许 next 吞掉。
  BEGIN { in_table = 0; err = 0 }
  /^\|/ {
    if ($0 ~ /^\|[[:space:]]*里程碑[[:space:]]*\|/) { in_table = 1; next }
    if (!in_table) next
    if ($0 ~ /^\|[[:space:]]*[-:]+/) next
    n = split($0, cells, "|")
    if (n != 7) {
      printf "docs/ROADMAP.md:%d 里程碑行应为 5 列，实际 %d 列：%s\n", NR, n - 2, $0 > "/dev/stderr"
      err = 1; next
    }
    id = trim(cells[2]); name = trim(cells[3]); standard = trim(cells[4])
    state = trim(cells[5]); basis = trim(cells[6])
    if (id == "" || name == "" || standard == "" || state == "" || basis == "") {
      printf "docs/ROADMAP.md:%d 里程碑行有空列（里程碑/名字/通过标准/状态/依据都不许空）：%s\n", NR, $0 > "/dev/stderr"
      err = 1; next
    }
    status_class = (state == "✅" ? "status-done" : "status-todo")
    status_text = (state == "✅" ? "已完成" : "未完成")
    gsub(/^\*\*/, "", id); gsub(/\*\*$/, "", id)
    printf "          <tr><th scope=\"row\">%s</th><td>%s：%s</td><td class=\"%s\">%s</td><td>%s</td></tr>\n", \
      render(id), render(name), render(standard), status_class, status_text, render(basis)
    count++
    next
  }
  { in_table = 0 }
  END { if (err) exit 3; if (count == 0) exit 2 }
' "$roadmap" > "$milestone_rows" || {
  echo "无法从 docs/ROADMAP.md 的「里程碑」表解析出里程碑行（逐行原因见上）" >&2
  exit 2
}

summary="${#declared[@]} 条轨道 · $total 个用例 · $projects 个已有毕业项目"
awk -v summary="$summary" -v tracks="$track_rows" -v milestones="$milestone_rows" '
  function insert_file(path,    line) {
    while ((getline line < path) > 0) print line
    close(path)
  }
  {
    if ($0 ~ /\{\{SUMMARY\}\}/) {
      sub(/\{\{SUMMARY\}\}/, summary)
      print
    } else if ($0 ~ /\{\{TRACK_ROWS\}\}/) insert_file(tracks)
    else if ($0 ~ /\{\{MILESTONE_ROWS\}\}/) insert_file(milestones)
    else print
  }
' "$template" > "$tmp/output"

if grep -qE '\{\{(SUMMARY|TRACK_ROWS|MILESTONE_ROWS)\}\}' "$tmp/output"; then
  echo "模板有未替换的看板占位符" >&2
  exit 2
fi

if [ "$#" -eq 1 ]; then
  cat "$tmp/output"
else
  cat "$tmp/output" > docs/进度看板.html
fi
