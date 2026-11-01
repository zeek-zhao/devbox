# ==================================================================
# L2  cpp —— C / C++ 语言镜像  (FROM tool，与其他 5 个语言镜像横向并列)
# ==================================================================
ARG BASE_IMAGE=devbox-tool:local
FROM ${BASE_IMAGE}

ARG GCC_MAJOR=14
ARG CLANG_MAJOR=18
ARG CLANG_FORMAT_MAJOR=18
ARG CMAKE_MIN_VERSION=3.28

LABEL org.opencontainers.image.title="devbox-cpp" \
      devbox.layer="lang" \
      devbox.language="cpp"

COPY images/scripts/ /opt/devbox/scripts/
RUN bash /opt/devbox/scripts/install/cpp.sh

ENV CC=gcc \
    CXX=g++ \
    CMAKE_GENERATOR=Ninja \
    CMAKE_EXPORT_COMPILE_COMMANDS=ON

WORKDIR /work/cpp
