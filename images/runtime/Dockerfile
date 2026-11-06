# ==================================================================
# L3  runtime —— 毕业项目部署镜像（不含任何编译器）
# ------------------------------------------------------------------
# 刻意不 FROM base：base 带 build-essential（约 +200MB）和一堆容器内才需要的工具。
# 这里只要「能跑起来」的最小集合：
#   C/C++   -> libstdc++6 / libgcc-s1（动态链接产物需要）
#   Go/Rust -> 静态链接，无需运行时（关掉 CGO 时）
#   Python  -> python3（注释与实际 apt install 对齐，#227）
#   Java    -> jre-headless（不是 jdk）
# 用法：脚本会把编译好的产物 COPY 到 /opt/app/bin
# ==================================================================
ARG UBUNTU_TAG=24.04
FROM ubuntu:${UBUNTU_TAG}

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_MIRROR=mirrors.ustc.edu.cn
ARG JAVA_MAJOR=21

LABEL org.opencontainers.image.title="devbox-runtime" \
      org.opencontainers.image.description="毕业项目部署运行时（无编译器）" \
      devbox.layer="runtime"

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

COPY images/scripts/setup-apt.sh /opt/devbox/setup-apt.sh
RUN bash /opt/devbox/setup-apt.sh

RUN set -eux; \
    apt-get install -y --no-install-recommends \
      libstdc++6 libgcc-s1 libssl3 zlib1g \
      python3 \
      "openjdk-${JAVA_MAJOR}-jre-headless" \
      tini gosu passwd \
    ; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 复用 Ubuntu 自带的 uid/gid 1000 用户，并移除其附加组。
RUN set -eux; \
    groupmod -n dev ubuntu; \
    usermod -l dev -d /home/dev -m -c devbox ubuntu; \
    usermod -G '' dev; \
    id dev
COPY images/scripts/entrypoint.sh /usr/local/bin/devbox-entrypoint
RUN chmod +x /usr/local/bin/devbox-entrypoint

COPY --chmod=0755 images/scripts/runtime-verify.sh /usr/local/bin/runtime-verify

WORKDIR /opt/app

ENTRYPOINT ["/usr/local/bin/devbox-entrypoint"]
CMD ["/usr/bin/tini", "--", "/usr/local/bin/runtime-verify"]

RUN /usr/local/bin/runtime-verify
