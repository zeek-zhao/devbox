#!/usr/bin/env bash
set -euo pipefail

versions_file="images/versions.env"
image_dir="images"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --versions)
      [ "$#" -ge 2 ] || { echo "缺少 --versions 的文件参数" >&2; exit 2; }
      versions_file="$2"
      shift 2
      ;;
    --dir)
      [ "$#" -ge 2 ] || { echo "缺少 --dir 的目录参数" >&2; exit 2; }
      image_dir="$2"
      shift 2
      ;;
    *)
      echo "未知参数：$1" >&2
      exit 2
      ;;
  esac
done

if [ ! -f "$versions_file" ]; then
  echo "找不到版本真本：$versions_file" >&2
  exit 1
fi
if [ ! -d "$image_dir" ]; then
  echo "找不到镜像目录：$image_dir" >&2
  exit 1
fi

declare -A versions=()
version_entries="$(grep -E '^[A-Z0-9_]+=' "$versions_file")"
while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  key="${entry%%=*}"
  versions["$key"]="${entry#*=}"
done <<< "$version_entries"

shopt -s nullglob
dockerfiles=("$image_dir"/*/Dockerfile)
if [ "${#dockerfiles[@]}" -eq 0 ]; then
  echo "找不到 Dockerfile：$image_dir" >&2
  exit 1
fi

fail=0
for file in "${dockerfiles[@]}"; do
  line_number=0
  while IFS= read -r line || [ -n "$line" ]; do
    line_number=$((line_number + 1))

    if [[ "$line" =~ ^ARG\ ([A-Z0-9_]+)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      docker_value="${BASH_REMATCH[2]}"
      if [[ ${versions[$key]+present} ]]; then
        if [ "${#docker_value}" -ge 2 ]; then
          first_char="${docker_value:0:1}"
          last_char="${docker_value: -1}"
          if { [ "$first_char" = '"' ] && [ "$last_char" = '"' ]; } || { [ "$first_char" = "'" ] && [ "$last_char" = "'" ]; }; then
            docker_value="${docker_value:1:${#docker_value}-2}"
          fi
        fi
        if [ "$docker_value" != "${versions[$key]}" ]; then
          printf '%s:%s  %s  Dockerfile 值 ≠ 真本值（%s ≠ %s）\n' \
            "$file" "$line_number" "$key" "$docker_value" "${versions[$key]}" >&2
          fail=1
        fi
      fi
    fi

    if [[ "$line" =~ FROM\ .*:[0-9]+\.[0-9]+\.[0-9]+ ]]; then
      printf '%s:%s  Dockerfile 里写死了镜像 tag\n' "$file" "$line_number" >&2
      fail=1
    fi
    if [[ "$line" =~ (gcc|clang|go|rust|python|java)[-_]?[0-9]+\.[0-9]+\.[0-9]+ ]]; then
      printf '%s:%s  Dockerfile 里写死了具体补丁号\n' "$file" "$line_number" >&2
      fail=1
    fi
  done < "$file"
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "版本真本与 Dockerfile ARG 默认值一致"
