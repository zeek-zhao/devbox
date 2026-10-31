# syntax=docker/dockerfile:1.7
# ==================================================================
# L2  rust —— Rust 语言镜像  (FROM tool，与其他 5 个语言镜像横向并列)
# ==================================================================
ARG BASE_IMAGE=devbox-tool:local
FROM ${BASE_IMAGE}

ARG RUST_TOOLCHAIN=stable
ARG RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ARG RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup

LABEL org.opencontainers.image.title="devbox-rust" \
      devbox.layer="lang" \
      devbox.language="rust"

COPY images/scripts/ /opt/devbox/scripts/
RUN bash /opt/devbox/scripts/install/rust.sh

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    RUSTUP_DIST_SERVER=${RUSTUP_DIST_SERVER} \
    RUSTUP_UPDATE_ROOT=${RUSTUP_UPDATE_ROOT} \
    CARGO_TERM_COLOR=always \
    PATH=/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /work/rust
