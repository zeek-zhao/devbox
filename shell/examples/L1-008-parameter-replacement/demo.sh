#!/usr/bin/env bash
set -euo pipefail

value=aba
printf 'first=%s\n' "${value/a/x}"
printf 'all=%s\n' "${value//a/x}"
