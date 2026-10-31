#!/usr/bin/env bash
# 把本地 devbox 同步到 215 并解包（在 WSL 里执行，Git Bash 侧不能直接碰 /mnt/d）
set -euo pipefail

SRC="${SRC:-/mnt/d/zeek/work/repo/devbox}"
DST="${DST:-jenkins@10.22.67.215}"
REMOTE="${REMOTE:-devbox}"

cd "$SRC"
echo "==> 打包 $SRC"
tar czf /tmp/devbox.tgz --exclude=.git --exclude=.dev --exclude=metrics .

echo "==> 同步到 $DST:~/$REMOTE"
ssh -o BatchMode=yes "$DST" "test -d ~/$REMOTE && echo 'REMOTE_EXISTS' || echo 'REMOTE_NEW'"
ssh -o BatchMode=yes "$DST" "rm -rf ~/$REMOTE && mkdir -p ~/$REMOTE"
scp -q /tmp/devbox.tgz "$DST:~/$REMOTE/"
ssh -o BatchMode=yes "$DST" "cd ~/$REMOTE && tar xzf devbox.tgz && rm -f devbox.tgz && find . -name '*.sh' -exec chmod +x {} + && echo '==> 文件数:' \$(find . -type f | wc -l)"
echo "==> 完成"
