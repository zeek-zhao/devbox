#!/usr/bin/env bash
set -euo pipefail

name=service

printf 'expanded='
cat <<EOF
$name
EOF

printf 'literal='
cat <<'EOF'
$name
EOF

IFS= read -r line <<< "single line"
printf 'here_string=%s\n' "$line"
