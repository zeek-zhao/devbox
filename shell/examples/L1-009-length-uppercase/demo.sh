#!/usr/bin/env bash
set -euo pipefail

value=ab
printf 'length=%s uppercase=%s\n' "${#value}" "${value^^}"
