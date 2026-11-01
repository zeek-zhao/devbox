#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

profiles=()
compose_args=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --profile)
      [ "$#" -ge 2 ] || { echo "ERROR: --profile requires a profile name" >&2; exit 2; }
      profiles+=(--profile "$2")
      shift 2
      ;;
    --profile=*)
      profiles+=("$1")
      shift
      ;;
    *)
      compose_args+=("$1")
      shift
      ;;
  esac
done

docker compose -f docker/docker-compose.yml "${profiles[@]}" up -d --build "${compose_args[@]}"
