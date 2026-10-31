#!/usr/bin/env bash
# YAML 读写封装，依赖 mikefarah/yq v4。source 之后可用：
#   yaml_create    <file> <yaml>         写文件并校验格式
#   yaml_read      <file> [yq查询]       读，默认整份
#   yaml_update    <file> <yq路径> <值>  改/加字段（值要自带 JSON 引号）
#   yaml_delete    <file> <yq路径>       删字段
#   yaml_array_add <file> <数组路径> <元素>
#   yaml_merge     <目标> <源>           深合并，源覆盖目标
#   yaml_to_json   <yaml> [输出json]     不传输出文件则打到 stdout
#   json_to_yaml   <json> [输出yaml]     同上
#   check_yq                             缺 yq 时返回 1
#
# 注意：yq v4 的路径表达式和 jq 基本一致，但 `-i` 才是原地写，
# 不带 `-i` 只打到 stdout —— 这是 v3 迁移过来最容易错的地方。

_yaml_sh_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./log.sh
source "$_yaml_sh_dir/log.sh"
unset _yaml_sh_dir

check_yq() {
  if ! command -v yq >/dev/null 2>&1; then
    log_error "需要安装 yq (https://github.com/mikefarah/yq)"
    log_info "安装方法: images/scripts/install/shell.sh 里已经装了；宿主可用 apt-get install yq"
    return 1
  fi
  # 只认 v4：v3 的 `yq read/write` 语法完全不同，混用会静默写坏文件
  local major
  major="$(yq --version 2>/dev/null | grep -oE 'v[0-9]+' | head -1 | tr -d 'v')"
  if [[ -n "$major" && "$major" -lt 4 ]]; then
    log_error "yq 版本过旧（需要 v4，当前 v$major）"
    return 1
  fi
  return 0
}

yaml_create() {
  local file_path="$1"
  local yaml_content="$2"

  check_yq || return 1
  mkdir -p "$(dirname "$file_path")"

  local tmp
  tmp="$(mktemp)" || return 1
  printf '%s\n' "$yaml_content" >"$tmp"
  if ! yq eval '.' "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    log_error "YAML 文件创建失败（内容不是合法 YAML）: $file_path"
    return 1
  fi
  mv "$tmp" "$file_path"
  log_debug "YAML 文件创建成功: $file_path"
  return 0
}

yaml_read() {
  local file_path="$1"
  local query="${2:-.}"

  check_yq || return 1
  if [[ ! -f "$file_path" ]]; then
    log_error "文件不存在: $file_path"
    return 1
  fi

  yq eval "$query" "$file_path"
}

yaml_update() {
  local file_path="$1"
  local path="$2"
  local value="$3"

  check_yq || return 1
  if [[ ! -f "$file_path" ]]; then
    log_error "文件不存在: $file_path"
    return 1
  fi

  if yq eval "$path = $value" "$file_path" -i; then
    log_debug "YAML 更新成功: $file_path ($path)"
    return 0
  fi
  log_error "YAML 更新失败: $file_path ($path)"
  return 1
}

yaml_delete() {
  local file_path="$1"
  local field_path="$2"

  check_yq || return 1
  if [[ ! -f "$file_path" ]]; then
    log_error "文件不存在: $file_path"
    return 1
  fi

  if yq eval "del($field_path)" "$file_path" -i; then
    log_debug "YAML 字段删除成功: $field_path"
    return 0
  fi
  log_error "YAML 字段删除失败: $field_path"
  return 1
}

yaml_array_add() {
  local file_path="$1"
  local array_path="$2"
  local element="$3"

  check_yq || return 1
  if [[ ! -f "$file_path" ]]; then
    log_error "文件不存在: $file_path"
    return 1
  fi

  if yq eval "$array_path += [$element]" "$file_path" -i; then
    log_debug "YAML 数组元素添加成功: $array_path"
    return 0
  fi
  log_error "YAML 数组元素添加失败: $array_path"
  return 1
}

yaml_merge() {
  local target_file="$1"
  local source_file="$2"

  check_yq || return 1
  if [[ ! -f "$target_file" ]]; then
    log_error "目标文件不存在: $target_file"
    return 1
  fi
  if [[ ! -f "$source_file" ]]; then
    log_error "源文件不存在: $source_file"
    return 1
  fi

  local tmp
  tmp="$(mktemp)" || return 1
  if yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
    "$target_file" "$source_file" >"$tmp"; then
    mv "$tmp" "$target_file"
    log_debug "YAML 文件合并成功: $target_file <- $source_file"
    return 0
  fi
  rm -f "$tmp"
  log_error "YAML 文件合并失败: $target_file <- $source_file"
  return 1
}

yaml_to_json() {
  local yaml_file="$1"
  local json_file="${2:-}"

  check_yq || return 1
  if [[ ! -f "$yaml_file" ]]; then
    log_error "YAML 文件不存在: $yaml_file"
    return 1
  fi

  if [[ -n "$json_file" ]]; then
    yq eval -o=json "$yaml_file" >"$json_file" || return 1
    log_debug "YAML 转 JSON 成功: $json_file"
    return 0
  fi
  yq eval -o=json "$yaml_file"
}

json_to_yaml() {
  local json_file="$1"
  local yaml_file="${2:-}"

  check_yq || return 1
  if [[ ! -f "$json_file" ]]; then
    log_error "JSON 文件不存在: $json_file"
    return 1
  fi

  if [[ -n "$yaml_file" ]]; then
    yq eval -P "$json_file" >"$yaml_file" || return 1
    log_debug "JSON 转 YAML 成功: $yaml_file"
    return 0
  fi
  yq eval -P "$json_file"
}
