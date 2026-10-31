# ==================================================================
# L3  all —— 总环境镜像（你要的「满足各种语言运行环境」的那一个）
# ------------------------------------------------------------------
# 设计取舍：用 6 个独立 RUN 把同一套 install 脚本再跑一遍，而不是
# 从 6 个语言镜像 COPY 产物。原因：
#   1) COPY 出来的工具链缺 apt 依赖，会得到「能跑但一编译就缺头文件」的残废环境
#   2) 每层独立缓存，改 java 不会让 cpp 层失效
# 代价：这是唯一一个 8G 级镜像，只在需要「一个容器里切语言」时用。
# ==================================================================
ARG BASE_IMAGE=devbox-tool:local
FROM ${BASE_IMAGE}

ARG GCC_MAJOR=14
ARG CLANG_MAJOR=18
ARG GO_VERSION=1.27.3
ARG GO_SHA256=
ARG GOPROXY=https://goproxy.cn,direct
ARG GOSUMDB=sum.golang.google.cn
ARG RUST_TOOLCHAIN=stable
ARG RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ARG RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
ARG PYTHON_VERSION=3.12
ARG PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ARG JAVA_MAJOR=21
ARG MAVEN_OPTS="-Dmaven.repo.local=/opt/m2 -Dfile.encoding=UTF-8"

LABEL org.opencontainers.image.title="devbox-all" \
      org.opencontainers.image.description="C/C++ Go Rust Shell Python Java 六语言总环境" \
      devbox.layer="all"

COPY images/scripts/ /opt/devbox/scripts/

RUN bash /opt/devbox/scripts/install/cpp.sh
RUN bash /opt/devbox/scripts/install/go.sh
RUN bash /opt/devbox/scripts/install/rust.sh
RUN bash /opt/devbox/scripts/install/python.sh
RUN bash /opt/devbox/scripts/install/java.sh
RUN bash /opt/devbox/scripts/install/shell.sh

ENV CC=gcc \
    CXX=g++ \
    CMAKE_GENERATOR=Ninja \
    GOROOT=/usr/local/go \
    GOPATH=/go \
    GOCACHE=/go/cache \
    GOTOOLCHAIN=local \
    GOFLAGS=-mod=mod \
    GOPROXY=${GOPROXY} \
    GOSUMDB=${GOSUMDB} \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    RUSTUP_DIST_SERVER=${RUSTUP_DIST_SERVER} \
    RUSTUP_UPDATE_ROOT=${RUSTUP_UPDATE_ROOT} \
    JAVA_HOME=/opt/java-home \
    MAVEN_OPTS="${MAVEN_OPTS}" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_INDEX_URL=${PIP_INDEX_URL} \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    PATH=/usr/local/cargo/bin:/usr/local/go/bin:/go/bin:/opt/java-home/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /work

# 总环境自检：六种语言都必须能编能跑
RUN set -eux; \
    echo "==> all smoke test"; \
    gcc --version | head -1; \
    go version; \
    rustc --version; \
    python3 --version; \
    javac -version; \
    bats --version
