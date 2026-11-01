# ==================================================================
# L2  java —— Java 语言镜像  (FROM tool，与其他 5 个语言镜像横向并列)
# ==================================================================
ARG BASE_IMAGE=devbox-tool:local
FROM ${BASE_IMAGE}

ARG JAVA_MAJOR=21
ARG MAVEN_OPTS="-Dmaven.repo.local=/opt/m2 -Dfile.encoding=UTF-8"
# 格式化器版本与校验和必须成对出现，缺一个 install/java.sh 会直接报错退出
ARG GJF_VERSION=1.22.0
ARG GJF_SHA256=16b2a1ee938686c8b1d88abf19eb83dfd0d623cee9de6fc6d09980214f816d3f

LABEL org.opencontainers.image.title="devbox-java" \
      devbox.layer="lang" \
      devbox.language="java"

COPY images/scripts/ /opt/devbox/scripts/
RUN bash /opt/devbox/scripts/install/java.sh

# /opt/java-home 由 install/java.sh 从 javac 反解生成，不靠猜路径
ENV JAVA_HOME=/opt/java-home \
    MAVEN_OPTS="${MAVEN_OPTS}" \
    PATH=/opt/java-home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /work/java
