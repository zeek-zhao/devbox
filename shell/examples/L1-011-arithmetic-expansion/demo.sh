#!/usr/bin/env bash
set -euo pipefail

attempts=7
divisor=2
next_attempt=$((attempts + 1))
quotient=$((attempts / divisor))

printf 'next attempt: %s\n' "$next_attempt"
printf 'integer quotient: %s\n' "$quotient"
