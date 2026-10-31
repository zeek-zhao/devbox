#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

deploy() {
  local target=$1 name=$2
  require_command flock
  require_command sha256sum
  # L1-033-command-lists
  mkdir -p -- "$target" && [[ -d "$target" ]] || die 'cannot create target'
  [[ ! -L "$target/.deploy.lock" && ! -L "$target/release" ]] || die 'unsafe target'
  # L1-032-redirections
  exec 9>"$target/.deploy.lock"
  # L2-006-flock-reentrancy: keep this descriptor open until process exit.
  flock -n 9 || die 'deployment is locked'
  new_workspace
  # L1-003-quoting-word-splitting
  payload "$name" >"$workspace/service.txt"
  if [[ -e "$target/release" ]]; then
    # L2-010-idempotent-steps: repeated deployment never rewrites matching files.
    if [[ -f "$target/release/service.txt" && ! -L "$target/release/service.txt" ]] &&
       cmp -s -- "$workspace/service.txt" "$target/release/service.txt" &&
       check_files "$target" && check_layout "$target" && check_integrity "$target"; then
      printf 'deploy\tunchanged\n'
      return
    fi
    die 'existing release differs or has invalid integrity'
  fi
  # Staging on the target filesystem makes publication an atomic directory rename.
  rm -rf -- "$workspace"
  workspace="$(mktemp -d -- "$target/.stage.XXXXXXXX")"
  payload "$name" >"$workspace/service.txt"
  (cd -- "$workspace" && sha256sum service.txt > SHA256SUMS)
  # L1-034-command-argument-safety
  mv -T -- "$workspace" "$target/release"
  workspace=''
  # L2-005-log-stream-separation
  printf '[deploy] release ready\n' >&2
  printf 'deploy\tcreated\n'
}

check_files() {
  local target=$1 file count=0
  find "$target/release" \( -type f -o -type l \) -print0 >"$workspace/paths" || return 1
  # L2-012-null-delimited-paths
  while IFS= read -r -d '' file; do
    [[ ! -L "$file" ]] || return 1
    # L1-011-arithmetic-expansion
    count=$((count + 1))
  done <"$workspace/paths"
  [[ "$count" -eq 2 ]]
}

check_layout() {
  local target=$1 file relative
  # L1-016-glob-options
  shopt -s nullglob globstar
  local files=()
  # L3-005-globstar-recursion
  files=("$target/release"/**/*.txt)
  [[ ${#files[@]} -eq 1 ]] || return 1
  file=${files[0]}
  # L1-007-prefix-suffix-removal
  relative=${file#"$target/release/"}
  [[ "${relative%.txt}" == service && ! -L "$file" ]]
}

check_integrity() {
  local target=$1 manifest
  [[ -f "$target/release/SHA256SUMS" && ! -L "$target/release/SHA256SUMS" &&
     -f "$target/release/service.txt" && ! -L "$target/release/service.txt" ]] || return 1
  manifest=$(cat -- "$target/release/SHA256SUMS") || return 1
  [[ "$manifest" =~ ^[a-f0-9]{64}'  service.txt'$ ]] || return 1
  # L3-004-sha256-integrity
  (cd -- "$target/release" && sha256sum --status -c SHA256SUMS)
}

check_policy() {
  # L3-003-jq-json-processing: nested policy fields and boolean selection.
  jq -e '.policy.services | any(.[]; .name == "demo" and .enabled == true)' "$2" >/dev/null
}

run_check() {
  local check=$1 target=$2 config=$3
  # L1-012-if-exit-status
  if "check_$check" "$target" "$config"; then
    printf '%s\tPASS\n' "$check"
  else
    printf '%s\tFAIL\n' "$check"
    return 1
  fi
}

inspect() {
  local target=$1 config=$2 check pid failed=0
  require_command setsid
  # L1-010-conditional-tests
  [[ -d "$target/release" && ! -L "$target/release" ]] || die 'release directory is required'
  if [[ -n "$config" ]]; then
    [[ -f "$config" ]] || die 'config file is required'
    require_command jq
  fi
  new_workspace
  # L1-017-indexed-arrays
  local checks=(files integrity layout)
  [[ -z "$config" ]] || checks+=(policy)
  # L1-019-array-at-star: join names for diagnostics, preserve arguments below.
  printf '[inspect] checks: %s\n' "$(IFS=,; printf '%s' "${checks[*]}")" >&2
  # L1-014-for-list
  for check in "${checks[@]}"; do
    # Each worker owns a process group so signals also stop external commands.
    setsid bash -c '
      source "$1/lib/commands.sh"
      workspace=$2
      run_check "$3" "$4" "$5"
    ' bash "$ROOT" "$workspace" "$check" "$target" "$config" \
      >"$workspace/$check.tsv" 2>"$workspace/$check.err" &
    children+=("$!")
  done
  # L3-001-background-wait-sort
  for pid in "${children[@]}"; do
    if wait "$pid"; then :; else failed=1; fi
  done
  children=()
  for check in "${checks[@]}"; do
    cat -- "$workspace/$check.err" >&2
  done
  sort -- "$workspace"/*.tsv
  rm -rf -- "$workspace"
  workspace=''
  # L1-022-exit-status
  return "$failed"
}

report_short() {
  local OPTIND=1 OPTARG option input='' help=0
  # L1-028-getopts: report also accepts a validated short-option interface.
  while getopts ':f:h' option; do
    case "$option" in
      f) [[ -z "$input" && -n "$OPTARG" ]] || die 'invalid or duplicate -f'; input=$OPTARG ;;
      h) help=1 ;;
      :) die "missing value for -$OPTARG" ;;
      \?) die "unknown option: -$OPTARG" ;;
    esac
  done
  shift "$((OPTIND - 1))"
  if [[ "$help" -eq 1 ]]; then
    [[ $# -eq 0 && -z "$input" ]] || die 'unexpected arguments with -h'
    usage
    return
  fi
  [[ $# -eq 0 && -n "$input" ]] || die 'report requires -f FILE and no operands'
  report "$input"
}

report() {
  local input=$1 line check status row total=0 passed=0
  [[ -f "$input" ]] || die 'input file is required'
  # L1-018-associative-arrays
  local -A results=()
  # L1-026-read-lines
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == *$'\t'* && "$line" != *$'\t'*$'\t'* ]] || die 'expected two TSV columns'
    # L1-005-ifs-field-splitting
    IFS=$'\t' read -r check status <<< "$line"
    [[ "$check" =~ ^[a-z][a-z0-9_-]*$ && "$status" =~ ^(PASS|FAIL)$ ]] || die 'invalid report row'
    [[ ! -v "results[$check]" ]] || die "duplicate check: $check"
    results[$check]=$status
    total=$((total + 1))
    if [[ "$status" == PASS ]]; then passed=$((passed + 1)); fi
  done <"$input"
  [[ "$total" -gt 0 ]] || die 'empty report'
  # L1-025-printf-echo
  printf '%-12s %s\n' CHECK STATUS
  # L1-021-pipeline-pipefail
  printf '%s\n' "${!results[@]}" | sort | while IFS= read -r row; do
    printf '%-12s %s\n' "$row" "${results[$row]}"
  done
  printf 'TOTAL %s PASS %s FAIL %s\n' "$total" "$passed" "$((total - passed))"
}

self_check() {
  new_workspace
  local fixture=$workspace
  # L1-006-parameter-default
  local bash_command=${BASH:-bash}
  local created
  # L1-020-command-substitution-subshell
  created=$("$bash_command" "$ROOT/src/main.sh" deploy --target "$fixture/target")
  printf '%s\n' "$created"
  "$bash_command" "$ROOT/src/main.sh" deploy --target "$fixture/target"
  "$bash_command" "$ROOT/src/main.sh" inspect --target "$fixture/target" >"$fixture/checks.tsv"
  "$bash_command" "$ROOT/src/main.sh" report --input "$fixture/checks.tsv"
  # L1-027-heredoc-herestring: verify report against a literal fixture.
  cat >"$fixture/expected.tsv" <<'EXPECTED'
files	PASS
integrity	PASS
layout	PASS
EXPECTED
  cmp -- "$fixture/expected.tsv" "$fixture/checks.tsv"
  # L3-002-streaming-text-processing
  awk -F '\t' '$2 == "PASS" {n++} END {printf "checks=%d\n", n}' "$fixture/checks.tsv"
  printf 'self-check OK\n'
}
