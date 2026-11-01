#!/usr/bin/env bash
# ==================================================================
# Java 工具链安装（Temurin 等价物：Ubuntu 官方 openjdk + Maven）
# 项目统一用 Maven + Spring Boot，不装 Gradle（24.04 源里是 4.4，太旧）
# ==================================================================
set -euo pipefail

: "${JAVA_MAJOR:?需要 JAVA_MAJOR}"
: "${GJF_VERSION:?需要 GJF_VERSION}"
: "${GJF_SHA256:?需要 GJF_SHA256}"

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

# Maven 的共享依赖仓库需要允许任意运行 uid 写入。
mkdir -p /opt/m2
chmod -R a+rwX /opt/m2

# ------------------------------------------------------------------
# google-java-format：Java 的格式化器，apt 源里没有，只能下 jar。
# 1) JDK 16+ 上必须用 --add-exports 打开 jdk.compiler 的内部包，
#    否则启动就 IllegalAccessError，报错信息还看不出是缺参数。
# 2) --aosp 用 4 空格缩进，与仓库现有 Java 代码一致；Google 默认是 2 空格，
#    不加这个参数会把 407 个用例的 Java 文件整体缩进重排。
# ------------------------------------------------------------------
GJF_URL="https://repo1.maven.org/maven2/com/google/googlejavaformat/google-java-format/${GJF_VERSION}/google-java-format-${GJF_VERSION}-all-deps.jar"
mkdir -p /opt/gjf
echo "==> 下载 google-java-format ${GJF_VERSION}"
curl -fsSL --retry 3 --retry-delay 2 -o /opt/gjf/google-java-format.jar "$GJF_URL"
echo "${GJF_SHA256}  /opt/gjf/google-java-format.jar" | sha256sum -c -

cat > /usr/local/bin/gjf <<'GJF_WRAPPER'
#!/usr/bin/env bash
# google-java-format 的固定入口：把 JDK 内部包访问权限一次写死，
# 免得每个调用方各自记一遍 --add-exports。
exec java \
  --add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED \
  --add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED \
  --add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED \
  --add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED \
  --add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED \
  -jar /opt/gjf/google-java-format.jar "$@"
GJF_WRAPPER
chmod +x /usr/local/bin/gjf

echo "==> 自检"
java -version
javac -version
mvn -version
gjf --version
echo "==> JAVA_HOME 预期路径:"
ls -d /usr/lib/jvm/java-${JAVA_MAJOR}-openjdk-* 2>/dev/null || true
