#!/usr/bin/env bash
set -euo pipefail

WORK="$(mktemp -d "${TMPDIR:-/tmp}/devbox-shell-L2-002-shellcheck-warning-gate.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

shellcheck -S warning run.sh demo.sh
cat >"$WORK/has-warning.sh" <<'SCRIPT'
#!/usr/bin/env bash
cd "$1"
SCRIPT

if shellcheck -S warning "$WORK/has-warning.sh" >"$WORK/warnings.txt" 2>&1; then
  echo "warning-level issue passed the gate" >&2
  exit 1
fi
grep -Fq 'SC2164' "$WORK/warnings.txt"
printf 'clean=pass\nwarning=blocked\n'
