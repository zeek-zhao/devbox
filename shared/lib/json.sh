#!/usr/bin/env bash
# JSON 读写封装，依赖 jq。source 之后可用：
#   json_create    <file> <json>        写文件并校验格式
#   json_read      <file> [jq查询]      读，默认整份
#   json_update    <file> <jq路径> <值> 改/加字段（值要自带 JSON 引号）
#   json_delete    <file> <jq路径>      删字段或数组元素
#   json_array_add <file> <数组路径> <元素>
#   check_jq                            缺 jq 时返回 1（不再 exit，避免 source 后炸掉调用方）
#
# 返回值约定：0 成功；1 失败（文件不存在 / jq 报错 / 结果为空）。失败时不留半成品文件。

_json_sh_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./log.sh
source "$_json_sh_dir/log.sh"
unset _json_sh_dir

check_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    log_error "需要安装 jq 工具"
    log_info "安装方法: apt-get install jq / brew install jq"
    return 1
  fi
  return 0
}

json_create() {
  local file_path="$1"
  local json_content="$2"

  check_jq || return 1
  mkdir -p "$(dirname "$file_path")"

  # 先写临时文件，jq 校验通过再落盘，避免失败时留下半截 JSON
  local tmp
  tmp="$(mktemp)" || return 1
  if ! printf '%s\n' "$json_content" | jq '.' >"$tmp"; then
    rm -f "$tmp"
    log_error "JSON 文件创建失败（内容不是合法 JSON）: $file_path"
    return 1
  fi
  mv "$tmp" "$file_path"
  log_debug "JSON 文件创建成功: $file_path"
  return 0
}

json_read() {
  local file_path="$1"
  local query="${2:-.}"

  check_jq || return 1
  if [[ ! -f "$file_path" ]]; then
    log_error "文件不存在: $file_path"
    return 1
  fi

  local result
  if ! result="$(jq "$query" "$file_path" 2>/dev/null)"; then
    log_error "jq 查询失败: $query"
    return 1
  fi

  # 路径不存在时 jq 返回 null，调用方基本都当失败处理
  if [[ "$result" == "null" && "$query" != "." ]]; then
    log_warn "路径不存在: $query"
    return 1
  fi

  printf '%s\n' "$result"
  return 0
}

json_update() {
  local file_path="$1"
  local path="$2"
  local value="$3"

  check_jq || return 1
  if [[ ! -f "$file_path" ]]; then
    log_error "文件不存在: $file_path"
    return 1
  fi

  local tmp
  tmp="$(mktemp)" || return 1
  if jq "$path = $value" "$file_path" >"$tmp"; then
    mv "$tmp" "$file_path"
    log_debug "JSON 更新成功: $file_path ($path)"
    return 0
  fi
  rm -f "$tmp"
  log_error "JSON 更新失败: $file_path ($path)"
  return 1
}

json_delete() {
  local file_path="$1"
  local field_path="$2"

  check_jq || return 1
  if [[ ! -f "$file_path" ]]; then
    log_error "文件不存在: $file_path"
    return 1
  fi

  local tmp
  tmp="$(mktemp)" || return 1
  if jq "del($field_path)" "$file_path" >"$tmp"; then
    mv "$tmp" "$file_path"
    log_debug "JSON 字段删除成功: $field_path"
    return 0
  fi
  rm -f "$tmp"
  log_error "JSON 字段删除失败: $field_path"
  return 1
}

json_array_add() {
  local file_path="$1"
  local array_path="$2"
  local element="$3"

  check_jq || return 1
  if [[ ! -f "$file_path" ]]; then
    log_error "文件不存在: $file_path"
    return 1
  fi

  local tmp
  tmp="$(mktemp)" || return 1
  if jq "$array_path += [$element]" "$file_path" >"$tmp"; then
    mv "$tmp" "$file_path"
    log_debug "JSON 数组元素添加成功: $array_path"
    return 0
  fi
  rm -f "$tmp"
  log_error "JSON 数组元素添加失败: $array_path"
  return 1
}
