#!/usr/bin/env bash
# ==================================================================
# apt 源 / locale / 时区 统一设置
# base 层和 runtime 层都调这个脚本（runtime 不能 FROM base，否则会带上编译器）
# 这是「换源逻辑只有一份」的唯一真本。
# ==================================================================
set -euo pipefail

APT_MIRROR="${APT_MIRROR:-mirrors.ustc.edu.cn}"
TZ_VALUE="${TZ:-Asia/Shanghai}"

echo "==> 切换 apt 源到 ${APT_MIRROR}"
# 24.04 是 deb822 格式（ubuntu.sources）；老格式一并处理，同一镜像要能跨版本复用
for f in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do
  if [ -f "$f" ]; then
    sed -i \
      -e "s@//archive.ubuntu.com@//${APT_MIRROR}@g" \
      -e "s@//security.ubuntu.com@//${APT_MIRROR}@g" \
      -e "s@//ports.ubuntu.com@//${APT_MIRROR}@g" "$f"
  fi
done

apt-get update
apt-get install -y --no-install-recommends ca-certificates locales tzdata

echo "==> 生成 locale en_US.UTF-8 与时区 ${TZ_VALUE}"
sed -i 's/^# *\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen
ln -snf "/usr/share/zoneinfo/${TZ_VALUE}" /etc/localtime
echo "${TZ_VALUE}" > /etc/timezone
