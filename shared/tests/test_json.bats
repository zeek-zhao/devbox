#!/usr/bin/env bats

# JSON 库测试，依赖 jq

load '../lib/json.sh'

setup() {
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
  export TEST_JSON="$TEST_DIR/test.json"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "创建基本JSON文件" {
  run json_create "$TEST_JSON" '{"name": "test", "version": "1.0"}'
  [ "$status" -eq 0 ]
  [ -f "$TEST_JSON" ]
}

@test "读取完整JSON" {
  json_create "$TEST_JSON" '{"name": "test", "version": "1.0"}' > /dev/null
  run json_read "$TEST_JSON"
  [ "$status" -eq 0 ]
  [ "$output" = $'{\n  "name": "test",\n  "version": "1.0"\n}' ]
}

@test "读取name字段" {
  json_create "$TEST_JSON" '{"name": "test", "version": "1.0"}' > /dev/null
  run json_read "$TEST_JSON" '.name'
  [ "$status" -eq 0 ]
  [ "$output" = '"test"' ]
}

@test "更新version字段" {
  json_create "$TEST_JSON" '{"name": "test", "version": "1.0"}' > /dev/null
  run json_update "$TEST_JSON" '.version' '"2.0"'
  [ "$status" -eq 0 ]
}

@test "验证version更新" {
  json_create "$TEST_JSON" '{"name": "test", "version": "1.0"}' > /dev/null
  json_update "$TEST_JSON" '.version' '"2.0"' > /dev/null
  run json_read "$TEST_JSON" '.version'
  [ "$status" -eq 0 ]
  [ "$output" = '"2.0"' ]
}

@test "添加author字段" {
  json_create "$TEST_JSON" '{"name": "test", "version": "1.0"}' > /dev/null
  run json_update "$TEST_JSON" '.author' '"zeek"'
  [ "$status" -eq 0 ]
  run json_read "$TEST_JSON" '.author'
  [ "$output" = '"zeek"' ]
}

@test "创建包含数组的JSON" {
  run json_create "$TEST_JSON" '{"items": ["item1", "item2"]}'
  [ "$status" -eq 0 ]
  [ -f "$TEST_JSON" ]
}

@test "向数组添加元素" {
  json_create "$TEST_JSON" '{"items": ["item1", "item2"]}' > /dev/null
  run json_array_add "$TEST_JSON" '.items' '"item3"'
  [ "$status" -eq 0 ]
}

@test "验证数组长度" {
  json_create "$TEST_JSON" '{"items": ["item1", "item2"]}' > /dev/null
  json_array_add "$TEST_JSON" '.items' '"item3"' > /dev/null
  run json_read "$TEST_JSON" '.items | length'
  [ "$status" -eq 0 ]
  [ "$output" = "3" ]
}

@test "删除items数组中的第一个元素" {
  json_create "$TEST_JSON" '{"items": ["item1", "item2"]}' > /dev/null
  run json_delete "$TEST_JSON" '.items[0]'
  [ "$status" -eq 0 ]
}

@test "验证删除后数组长度" {
  json_create "$TEST_JSON" '{"items": ["item1", "item2", "item3"]}' > /dev/null
  json_delete "$TEST_JSON" '.items[0]' > /dev/null
  run json_read "$TEST_JSON" '.items | length'
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "处理不存在的文件" {
  run json_read '/nonexistent/file.json'
  [ "$status" -eq 1 ]
}

@test "处理无效JSON创建" {
  run json_create "$TEST_DIR/invalid.json" '{invalid json}'
  [ "$status" -eq 1 ]
  # 失败时不许留下半成品文件
  [ ! -f "$TEST_DIR/invalid.json" ]
}

@test "查询不存在的路径返回 1" {
  json_create "$TEST_JSON" '{"name": "test"}' > /dev/null
  run json_read "$TEST_JSON" '.nope'
  [ "$status" -eq 1 ]
}

@test "json_read 的 stdout 只有数据，日志走 stderr" {
  json_create "$TEST_JSON" '{"a": 1}' > /dev/null
  local out
  out="$(json_read "$TEST_JSON" '.a' 2> /dev/null)"
  [ "$out" = "1" ]
}

@test "json_create 会创建缺失的父目录" {
  run json_create "$TEST_DIR/deep/nested/x.json" '{"a": 1}'
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/deep/nested/x.json" ]
}
