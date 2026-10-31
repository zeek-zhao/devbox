#!/usr/bin/env bash
# ==================================================================
# apt 源 / locale / 时区 统一设置
# base 层和 runtime 层都调这个脚本（runtime 不能 FROM base，否则会带上编译器）
# 这是「换源逻辑只有一份」的唯一真本。
# ==================================================================
set -euo pipefail

# 注意是 ${VAR-default} 不是 ${VAR:-default}：冒号版本会把「显式传入的空串」
# 也当成未设置，结果 CI 里想用官方源反而被改回国内源。
APT_MIRROR="${APT_MIRROR-mirrors.ustc.edu.cn}"
TZ_VALUE="${TZ:-Asia/Shanghai}"

# APT_MIRROR 为空 / official / default 时保持官方源不动。
# 用途：CI runner 在境外，套国内源会慢到超时；本地与 215 在境内，才需要换源。
case "$APT_MIRROR" in
  ''|official|default)
    echo "==> 保持官方 apt 源（APT_MIRROR='$APT_MIRROR'）"
    ;;
esac
# 24.04 是 deb822 格式（ubuntu.sources）；老格式一并处理，同一镜像要能跨版本复用
case "$APT_MIRROR" in
  ''|official|default) : ;;
  *)
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do
      if [ -f "$f" ]; then
        sed -i \
          -e "s@//archive.ubuntu.com@//${APT_MIRROR}@g" \
          -e "s@//security.ubuntu.com@//${APT_MIRROR}@g" \
          -e "s@//ports.ubuntu.com@//${APT_MIRROR}@g" "$f"
      fi
    done
    ;;
esac

apt-get update
apt-get install -y --no-install-recommends ca-certificates locales tzdata

echo "==> 生成 locale en_US.UTF-8 与时区 ${TZ_VALUE}"
sed -i 's/^# *\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen
ln -snf "/usr/share/zoneinfo/${TZ_VALUE}" /etc/localtime
echo "${TZ_VALUE}" > /etc/timezone
