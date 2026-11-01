#!/usr/bin/env bash
set -euo pipefail

work=$1
cat >"$work/child.sh" <<'CHILD'
#!/usr/bin/env bash
set -euo pipefail

work=$1
status=$2
temp=$(mktemp "$work/item.XXXXXX")
trap 'rm -f "$temp"' EXIT
printf 'temporary data\n' > "$temp"
exit "$status"
CHILD

bash "$work/child.sh" "$work" 0
if [ -z "$(find "$work" -mindepth 1 -maxdepth 1 -type f ! -name child.sh -print -quit)" ]; then
  printf 'normal exit cleaned temporary file: true\n'
else
  printf 'normal exit cleaned temporary file: false\n'
fi

if bash "$work/child.sh" "$work" 7; then
  printf 'nonzero exit status preserved: false\n'
else
  printf 'nonzero exit status preserved: true\n'
fi
if [ -z "$(find "$work" -mindepth 1 -maxdepth 1 -type f ! -name child.sh -print -quit)" ]; then
  printf 'nonzero exit cleaned temporary file: true\n'
else
  printf 'nonzero exit cleaned temporary file: false\n'
fi
