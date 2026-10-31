#!/usr/bin/env bash
set -euo pipefail

WORK="${TMPDIR:-/tmp}/devbox-go-L3-003-cpu-profile"
OUT="$WORK/program"
PROFILE="$WORK/cpu.pprof"
TOP="$WORK/top.txt"
mkdir -p "$WORK"
go build -o "$OUT" main.go
PROFILE_PATH="$PROFILE" "$OUT"
go tool pprof -top "$PROFILE" >"$TOP"
if grep -q 'profileWorkload' "$TOP"; then
  echo "profile-samples: present"
else
  echo "profile-samples: missing"
  exit 1
fi
