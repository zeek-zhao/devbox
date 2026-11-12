#!/usr/bin/env bash
# L1-001-shebang-execution: execute with Bash, not sh.
# L1-030-strict-mode
set -euo pipefail
IFS=$'\n\t' # L0-hello: image and runner path anchor.

# L2-007-posix-bash-portability: arrays and source require Bash.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "$ROOT/lib/common.sh"
# shellcheck source=../lib/commands.sh
source "$ROOT/lib/commands.sh"
# shellcheck source=../lib/advanced.sh
source "$ROOT/lib/advanced.sh"

# L1-004-positional-parameters
main "$@"
