#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# L1-031-export-environment: keep sorting and case conversion locale-independent.
export LC_ALL=C
workspace=''
children=()

cleanup() {
  local pid
  for pid in "${children[@]}"; do
    if kill -TERM -- "-$pid"; then :; else
      printf '[cleanup] worker group unavailable; stopping launcher\n' >&2
      if kill -TERM "$pid"; then :; else
        printf '[cleanup] worker already exited\n' >&2
      fi
    fi
    if wait "$pid"; then :; else
      printf '[cleanup] worker stopped\n' >&2
    fi
  done
  # Only delete the exact directory returned by mktemp.
  if [[ -n "$workspace" ]]; then rm -rf -- "$workspace"; fi
}

# L3-006-signal-cleanup
trap 'exit 130' INT
trap 'exit 143' TERM
# L1-029-trap-mktemp
trap cleanup EXIT
on_error() {
  local rc=$1 line=$2
  printf '[error] command failed (status %s, line %s)\n' "$rc" "$line" >&2
  exit "$rc"
}
# L2-011-failure-diagnostics
trap 'on_error "$?" "$LINENO"' ERR
set -E

new_workspace() {
  # L2-009-temporary-workspace
  workspace="$(mktemp -d)"
}

die() {
  # L1-024-stdout-stderr
  printf '[error] %s\n' "$1" >&2
  exit 2
}

require_command() {
  # L1-035-command-discovery
  command -v "$1" >/dev/null || die "required command unavailable: $1"
}

usage() {
  # L2-001-script-skeleton-usage
  cat <<'USAGE'
Usage: main.sh deploy --target DIR [--name NAME]
       main.sh inspect --target DIR [--config FILE]
       main.sh report --input FILE
       main.sh report -f FILE
       main.sh --self-check
NAME: 1-32 ASCII letters, digits or hyphens, starting with a letter.
Inspection emits TSV; report validates and sorts it. Failed checks exit 1.
USAGE
}

validate_name() {
  local value=$1
  # L1-009-length-uppercase
  [[ ${#value} -le 32 ]] || die 'name exceeds 32 characters'
  [[ "$value" =~ ^[a-zA-Z][a-zA-Z0-9-]*$ ]] || die 'invalid name'
}

payload() {
  # L1-023-functions-local-return
  local name=$1 key
  # L1-008-parameter-replacement
  key=${name//-/_}
  # L1-002-variable-expansion
  printf 'service=%s\nkey=%s\nstate=READY\n' "$name" "${key^^}"
  return 0
}

main() {
  local command target='' name=demo config='' input='' name_seen=0
  [[ $# -gt 0 ]] || {
    usage >&2
    exit 2
  }
  command=$1
  shift
  case "$command" in
    --help | -h)
      [[ $# -eq 0 ]] || die 'unexpected arguments'
      usage
      return
      ;;
    --self-check)
      [[ $# -eq 0 ]] || die 'unexpected arguments'
      self_check
      return
      ;;
    deploy | inspect | report) ;;
    *) die "unknown command: $command" ;;
  esac
  if [[ "$command" == report && ${1:-} == -* && ${1:-} != --* ]]; then
    report_short "$@"
    return
  fi
  # L1-015-while-loop
  while [ $# -gt 0 ]; do
    # L1-013-case-patterns
    case "$1" in
      --target | --name | --config | --input)
        # L2-008-cli-option-validation
        [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || die "missing value for $1"
        case "$command:$1" in
          deploy:--target | inspect:--target)
            [[ -z "$target" ]] || die 'duplicate target'
            target=$2
            ;;
          deploy:--name)
            [[ "$name_seen" -eq 0 ]] || die 'duplicate name'
            name=$2
            name_seen=1
            ;;
          inspect:--config)
            [[ -z "$config" ]] || die 'duplicate config'
            config=$2
            ;;
          report:--input)
            [[ -z "$input" ]] || die 'duplicate input'
            input=$2
            ;;
          *) die "option not valid for $command: $1" ;;
        esac
        shift 2
        ;;
      *) die "unknown option: $1" ;;
    esac
  done
  case "$command" in
    deploy)
      [[ -n "$target" ]] || die 'target is required'
      validate_name "$name"
      deploy "$target" "$name"
      ;;
    inspect)
      [[ -n "$target" ]] || die 'target is required'
      inspect "$target" "$config"
      ;;
    report)
      [[ -n "$input" ]] || die 'input is required'
      report "$input"
      ;;
  esac
}
