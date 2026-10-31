#!/usr/bin/env bash
set -euo pipefail

# Go 在模块模式下会把 git 版本信息烙进二进制（VCS stamping）。两个问题：
#   1) 二进制里嵌入 commit hash，同一份源码在不同 commit 上产出不同二进制，违反确定性；
#   2) CI 里 .git 属主与容器用户不一致时 git 以 exit 128 拒绝，go build 直接失败。
# 所以显式关闭。
export GOFLAGS="-buildvcs=false"
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
