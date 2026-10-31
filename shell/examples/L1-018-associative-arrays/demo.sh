#!/usr/bin/env bash
set -euo pipefail

declare -A status=(
  [api]=ready
  [worker]=idle
)

printf 'api status: %s\n' "${status[api]}"
printf 'worker status: %s\n' "${status[worker]}"

keys=()
while IFS= read -r key; do
  keys+=("$key")
done < <(printf '%s\n' "${!status[@]}" | sort)

printf 'sorted keys:\n'
printf '  %s\n' "${keys[@]}"
