# ==================================================================
# L2  java —— Java 语言镜像  (FROM tool，与其他 5 个语言镜像横向并列)
# ==================================================================
ARG BASE_IMAGE=devbox-tool:local
FROM ${BASE_IMAGE}

ARG JAVA_MAJOR=21
ARG MAVEN_OPTS="-Dmaven.repo.local=/opt/m2 -Dfile.encoding=UTF-8"

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
