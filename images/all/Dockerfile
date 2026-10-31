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
ARG CLANG_FORMAT_MAJOR=18
ARG CMAKE_MIN_VERSION=3.28
ARG GO_VERSION=1.27.3
ARG GO_SHA256=65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40
ARG GOPROXY=https://goproxy.cn,direct
ARG GOSUMDB=sum.golang.google.cn
ARG RUST_TOOLCHAIN=stable
ARG RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ARG RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
ARG PYTHON_VERSION=3.12
ARG PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ARG JAVA_MAJOR=21
ARG MAVEN_OPTS="-Dmaven.repo.local=/opt/m2 -Dfile.encoding=UTF-8"
ARG GJF_VERSION=1.22.0
ARG GJF_SHA256=16b2a1ee938686c8b1d88abf19eb83dfd0d623cee9de6fc6d09980214f816d3f
ARG NODE_VERSION=22.11.0
ARG NODE_SHA256=83bf07dd343002a26211cf1fcd46a9d9534219aad42ee02847816940bf610a72
ARG VUE_VERSION=3.5.44
ARG PRETTIER_VERSION=3.9.10
ARG NPM_REGISTRY=https://registry.npmmirror.com
ARG YQ_VERSION=4.44.3
ARG YQ_SHA256=a2c097180dd884a8d50c956ee16a9cec070f30a7947cf4ebf87d5f36213e9ed7

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
RUN bash /opt/devbox/scripts/install/vue.sh

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
    NODE_PATH=/usr/local/lib/node_modules \
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
