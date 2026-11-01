#!/usr/bin/env bats

# YAML 库测试，依赖 mikefarah/yq v4

load '../lib/yaml.sh'

BASE_YAML='name: test
version: "1.0"
features: []'

setup() {
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
  export TEST_YAML="$TEST_DIR/test.yaml"
  export TEST_YAML2="$TEST_DIR/test2.yaml"
  export TEST_JSON="$TEST_DIR/test.json"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "创建基本YAML文件" {
  run yaml_create "$TEST_YAML" "$BASE_YAML"
  [ "$status" -eq 0 ]
  [ -f "$TEST_YAML" ]
}

@test "读取完整YAML" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  run yaml_read "$TEST_YAML"
  [ "$status" -eq 0 ]
  [[ "$output" == *"name: test"* ]]
}

@test "读取name字段" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  run yq eval '.name' "$TEST_YAML" -o=json
  [ "$status" -eq 0 ]
  [ "$output" = '"test"' ]
}

@test "读取version字段" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  run yq eval '.version' "$TEST_YAML" -o=json
  [ "$status" -eq 0 ]
  [ "$output" = '"1.0"' ]
}

@test "更新version字段" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  run yaml_update "$TEST_YAML" '.version' '"2.0"'
  [ "$status" -eq 0 ]
}

@test "验证version更新" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  yaml_update "$TEST_YAML" '.version' '"2.0"' > /dev/null
  run yq eval '.version' "$TEST_YAML" -o=json
  [ "$status" -eq 0 ]
  [ "$output" = '"2.0"' ]
}

@test "添加author字段" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  run yaml_update "$TEST_YAML" '.author' '"zeek"'
  [ "$status" -eq 0 ]
}

@test "验证author字段" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  yaml_update "$TEST_YAML" '.author' '"zeek"' > /dev/null
  run yq eval '.author' "$TEST_YAML" -o=json
  [ "$status" -eq 0 ]
  [ "$output" = '"zeek"' ]
}

@test "向features数组添加元素" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  run yaml_array_add "$TEST_YAML" '.features' '"logging"'
  [ "$status" -eq 0 ]
}

@test "验证数组长度" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  yaml_array_add "$TEST_YAML" '.features' '"logging"' > /dev/null
  yaml_array_add "$TEST_YAML" '.features' '"monitoring"' > /dev/null
  run yq eval '.features | length' "$TEST_YAML"
  [ "$status" -eq 0 ]
  [ "$output" = "2" ]
}

@test "验证数组第一个元素" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  yaml_array_add "$TEST_YAML" '.features' '"logging"' > /dev/null
  run yq eval '.features[0]' "$TEST_YAML" -o=json
  [ "$status" -eq 0 ]
  [ "$output" = '"logging"' ]
}

@test "删除author字段" {
  yaml_create "$TEST_YAML" 'name: test
version: "1.0"
author: zeek
features: []' > /dev/null
  run yaml_delete "$TEST_YAML" '.author'
  [ "$status" -eq 0 ]
}

@test "验证author字段已删除" {
  yaml_create "$TEST_YAML" 'name: test
version: "1.0"
author: zeek
features: []' > /dev/null
  yaml_delete "$TEST_YAML" '.author' > /dev/null
  run yq eval '.author' "$TEST_YAML"
  [ "$status" -eq 0 ]
  [ "$output" = "null" ]
}

@test "合并YAML文件" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  yaml_create "$TEST_YAML2" 'database:
  host: localhost
  port: 5432' > /dev/null
  run yaml_merge "$TEST_YAML" "$TEST_YAML2"
  [ "$status" -eq 0 ]
}

@test "验证合并后的database.host" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  yaml_create "$TEST_YAML2" 'database:
  host: localhost
  port: 5432' > /dev/null
  yaml_merge "$TEST_YAML" "$TEST_YAML2" > /dev/null
  run yq eval '.database.host' "$TEST_YAML" -o=json
  [ "$status" -eq 0 ]
  [ "$output" = '"localhost"' ]
}

@test "YAML转JSON" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  run yaml_to_json "$TEST_YAML" "$TEST_JSON"
  [ "$status" -eq 0 ]
  [ -f "$TEST_JSON" ]
}

@test "JSON转YAML" {
  yaml_create "$TEST_YAML" "$BASE_YAML" > /dev/null
  yaml_to_json "$TEST_YAML" "$TEST_JSON" > /dev/null
  run json_to_yaml "$TEST_JSON" "$TEST_DIR/converted.yaml"
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/converted.yaml" ]
}

@test "yaml_to_json 不传输出文件时打到 stdout" {
  yaml_create "$TEST_YAML" 'a: 1' > /dev/null
  run yaml_to_json "$TEST_YAML"
  [ "$status" -eq 0 ]
  # yq 默认美化输出，不是单行
  [ "$output" = $'{\n  "a": 1\n}' ]
}

@test "处理不存在的文件" {
  run yaml_read '/nonexistent/file.yaml'
  [ "$status" -eq 1 ]
}

@test "处理无效YAML创建" {
  run yaml_create "$TEST_DIR/invalid.yaml" 'invalid: yaml: content: [unclosed'
  [ "$status" -eq 1 ]
  [ ! -f "$TEST_DIR/invalid.yaml" ]
}

@test "创建带嵌套结构的YAML" {
  run yaml_create "$TEST_DIR/nested.yaml" 'app:
  name: myapp
  config:
    debug: true
    database:
      host: localhost
      port: 3306'
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/nested.yaml" ]
}

@test "更新嵌套字段" {
  yaml_create "$TEST_DIR/nested.yaml" 'app:
  name: myapp
  config:
    database:
      port: 3306' > /dev/null
  run yaml_update "$TEST_DIR/nested.yaml" '.app.config.database.port' '5432'
  [ "$status" -eq 0 ]
  run yq eval '.app.config.database.port' "$TEST_DIR/nested.yaml"
  [ "$output" = "5432" ]
}

@test "yaml_read 的 stdout 只有数据" {
  yaml_create "$TEST_YAML" 'a: 1' > /dev/null
  local out
  out="$(yaml_read "$TEST_YAML" '.a' 2> /dev/null)"
  [ "$out" = "1" ]
}
