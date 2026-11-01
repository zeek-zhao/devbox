# ==================================================================
# L0  base —— 所有镜像的公共底座
# ------------------------------------------------------------------
# 只放「任何语言都需要」的东西：国内 apt 源、locale、时区、基础工具链。
# 这一层被 6 个语言镜像共享，它的每一 MB 都会乘 6，所以严禁往这里塞语言相关的东西。
# ==================================================================
ARG UBUNTU_TAG=24.04
FROM ubuntu:${UBUNTU_TAG}

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_MIRROR=mirrors.ustc.edu.cn

LABEL org.opencontainers.image.title="devbox-base" \
      org.opencontainers.image.description="Ubuntu 24.04 公共底座：国内源 + locale + 基础工具" \
      devbox.layer="base"

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

# 换源 + locale + 时区（脚本与 runtime 层共享同一份，避免两处漂移）
COPY images/scripts/setup-apt.sh /opt/devbox/setup-apt.sh
RUN bash /opt/devbox/setup-apt.sh

# 基础工具：只装「确定在 main/universe 里存在」的，避免因包名错误整层失败
RUN set -eux; \
    apt-get install -y --no-install-recommends \
      curl wget gnupg \
      git openssh-client \
      build-essential pkg-config make \
      vim-tiny less file tree \
      jq zip unzip xz-utils tar gzip bzip2 zstd \
      procps psmisc iproute2 net-tools dnsutils iputils-ping \
      sudo rsync gosu passwd \
    ; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 复用 Ubuntu 自带的 uid/gid 1000 用户，并移除其附加组；默认非 root，见 entrypoint.sh。
RUN set -eux; \
    groupmod -n dev ubuntu; \
    usermod -l dev -d /home/dev -m -c devbox ubuntu; \
    usermod -G '' dev; \
    id dev
COPY images/scripts/entrypoint.sh /usr/local/bin/devbox-entrypoint
RUN chmod +x /usr/local/bin/devbox-entrypoint

# git 默认值写进系统级配置：容器里没有 ~/.gitconfig，避免每个仓库重复设置
RUN git config --system init.defaultBranch main \
 && git config --system core.autocrlf input \
 && git config --system pull.rebase true

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/devbox-entrypoint"]
CMD ["bash"]

# 自检：这一层必须能跑通最基础的三件事
RUN set -eux; \
    echo "==> base smoke test"; \
    curl --version >/dev/null; \
    git --version; \
    locale | grep -q 'LANG=en_US.UTF-8'; \
    test -s /usr/share/zoneinfo/Asia/Shanghai
