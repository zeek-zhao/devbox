#!/usr/bin/env bash
# ==================================================================
# Java 工具链安装（Temurin 等价物：Ubuntu 官方 openjdk + Maven）
# 项目统一用 Maven + Spring Boot，不装 Gradle（24.04 源里是 4.4，太旧）
# ==================================================================
set -euo pipefail

: "${JAVA_MAJOR:?需要 JAVA_MAJOR}"

apt-get update
apt-get install -y --no-install-recommends \
  "openjdk-${JAVA_MAJOR}-jdk" "openjdk-${JAVA_MAJOR}-jdk-headless" \
  maven \
  libfreetype6 fontconfig
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 统一的 JAVA_HOME 入口：不猜路径，直接从 javac 反解（update-alternatives 也能穿透）
JAVAC_REAL="$(readlink -f /usr/bin/javac)"
JAVA_HOME_REAL="$(dirname "$(dirname "$JAVAC_REAL")")"
ln -sfn "$JAVA_HOME_REAL" /opt/java-home
echo "==> JAVA_HOME=${JAVA_HOME_REAL} -> /opt/java-home"

echo "==> 自检"
java -version
javac -version
mvn -version
echo "==> JAVA_HOME 预期路径:"
ls -d /usr/lib/jvm/java-${JAVA_MAJOR}-openjdk-* 2>/dev/null || true
