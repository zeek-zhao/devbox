#!/usr/bin/env bash
set -euo pipefail

OUT="${TMPDIR:-/tmp}/devbox-go-L2-012-test-exit-status"
mkdir -p "$OUT"
go build -o "$OUT/program" .
"$OUT/program"

if (cd failing && go test ./... >"$OUT/go-test.log" 2>&1); then
  echo "go test exit: unexpectedly zero"
  exit 1
else
  grep -q 'intentional failure for exit-status demonstration' "$OUT/go-test.log"
  printf 'go test exit: nonzero\n'
fi

cat >"$OUT/test-gate.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$1"
go test ./...
EOF
if bash "$OUT/test-gate.sh" "$PWD/failing" >"$OUT/gate.log" 2>&1; then
  echo "strict gate exit: unexpectedly zero"
  exit 1
else
  grep -q 'intentional failure for exit-status demonstration' "$OUT/gate.log"
  printf 'strict gate exit: nonzero\n'
fi
