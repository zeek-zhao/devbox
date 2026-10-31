#!/usr/bin/env bats

# 日志库测试。注意：这里绝对不能 source 一个定义了 run() 的库，
# 否则 bats 的 run 被覆盖，所有 `run xxx; [ "$status" ... ]` 断言都会错乱。
# 下面「不覆盖 bats 的 run」那条用例就是这道防线的守卫。

load '../lib/log.sh'

strip_colors() {
  # shellcheck disable=SC2001
  echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

setup() {
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
  export TEST_LOG="$TEST_DIR/test.log"
}

teardown() {
  rm -rf "$TEST_DIR"
  unset LOG_DEBUG
}

@test "log_info: 输出信息日志" {
  run log_info "Test info message"
  [ "$status" -eq 0 ]
  [[ "$(strip_colors "$output")" =~ \[INFO\] ]]
  [[ "$(strip_colors "$output")" =~ "Test info message" ]]
}

@test "log_success: 输出成功日志" {
  run log_success "Operation completed"
  [ "$status" -eq 0 ]
  [[ "$(strip_colors "$output")" =~ \[SUCCESS\] ]]
}

@test "log_warn: 输出警告日志" {
  run log_warn "This is a warning"
  [ "$status" -eq 0 ]
  [[ "$(strip_colors "$output")" =~ \[WARN\] ]]
}

@test "log_error: 输出错误日志" {
  run log_error "This is an error"
  [ "$status" -eq 0 ]
  [[ "$(strip_colors "$output")" =~ \[ERROR\] ]]
}

@test "log_debug: 未设置 LOG_DEBUG 时不输出且返回 0" {
  unset LOG_DEBUG
  run log_debug "Debug message"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "log_debug: LOG_DEBUG 非空时输出" {
  export LOG_DEBUG=1
  run log_debug "Debug message"
  [ "$status" -eq 0 ]
  [[ "$(strip_colors "$output")" =~ \[DEBUG\] ]]
}

@test "log_debug: LOG_DEBUG=0 也算设置（只要非空就输出）" {
  export LOG_DEBUG=0
  run log_debug "Should appear"
  [[ "$(strip_colors "$output")" =~ \[DEBUG\] ]]
}

@test "log_debug: LOG_DEBUG 为空字符串时不输出" {
  export LOG_DEBUG=""
  run log_debug "Should not appear"
  [ -z "$output" ]
}

@test "日志包含时间戳" {
  run log_info "Test timestamp"
  [[ "$(strip_colors "$output")" =~ \[[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\] ]]
}

@test "log_info: 处理多个参数" {
  run log_info "Message" "with" "multiple" "parts"
  [[ "$(strip_colors "$output")" =~ "Message with multiple parts" ]]
}

@test "log_error: 处理特殊字符" {
  run log_error "Error: file not found!"
  [[ "$(strip_colors "$output")" =~ "Error: file not found!" ]]
}

@test "log_error: 百分号不会被当成格式串" {
  run log_error "100% done, %s stays literal"
  [[ "$(strip_colors "$output")" =~ "100% done, %s stays literal" ]]
}

@test "日志输出到 stderr 而不是 stdout" {
  # stdout 必须干净，否则 `x=$(json_read ...)` 会被日志污染
  local stdout_only
  stdout_only="$(log_info "to-stderr" 2> /dev/null)"
  [ -z "$stdout_only" ]
}

@test "die: 输出错误并退出 1" {
  run bash -c 'source "'"$BATS_TEST_DIRNAME"'/../lib/log.sh" && die "Fatal error occurred"'
  [ "$status" -eq 1 ]
  [[ "$(strip_colors "$output")" =~ \[ERROR\] ]]
  [[ "$(strip_colors "$output")" =~ "Fatal error occurred" ]]
}

@test "log_run: 执行命令并打印命令行" {
  run log_run echo "test output"
  [ "$status" -eq 0 ]
  [[ "$(strip_colors "$output")" =~ "+ echo test output" ]]
  [[ "$output" =~ "test output" ]]
}

@test "log_run: 透传命令的非零退出码" {
  run log_run false
  [ "$status" -eq 1 ]
}

@test "不覆盖 bats 的 run 函数" {
  # 回归守卫：库一旦再次定义 run()，上面所有断言都会静默失真
  run true
  [ "$status" -eq 0 ]
  run bash -c 'exit 7'
  [ "$status" -eq 7 ]
}

@test "NO_COLOR=1 时不输出颜色码" {
  # 颜色在 source 时求值，所以 NO_COLOR 要在 source 之前生效（子 shell 里 source 最直观）
  run bash -c 'export NO_COLOR=1; source "'"$BATS_TEST_DIRNAME"'/../lib/log.sh"; log_info plain'
  [ "$status" -eq 0 ]
  [[ "$output" != *$'\033'* ]]
  [[ "$output" =~ "plain" ]]
}

@test "默认输出带颜色码" {
  # 必须显式 unset NO_COLOR：load 是在文件被 source 时求值的，
  # 外层环境设了 NO_COLOR 的话 $RED 在测试里天然是空的，这条会假红。
  run bash -c 'unset NO_COLOR; source "'"$BATS_TEST_DIRNAME"'/../lib/log.sh"; log_info colored'
  [[ "$output" =~ $'\033' ]]
}

@test "可以重复 source 而不重复定义" {
  run bash -c 'source "'"$BATS_TEST_DIRNAME"'/../lib/log.sh"; source "'"$BATS_TEST_DIRNAME"'/../lib/log.sh"; log_info ok'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "ok" ]]
}

@test "颜色变量已定义" {
  run bash -c 'unset NO_COLOR; source "'"$BATS_TEST_DIRNAME"'/../lib/log.sh";
    [ -n "$RED" ] && [ -n "$GREEN" ] && [ -n "$YELLOW" ] && [ -n "$BLUE" ] && [ -n "$NC" ]'
  [ "$status" -eq 0 ]
}
