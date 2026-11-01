# ==================================================================
# L1  tool —— 通用开发调试工具层
# ------------------------------------------------------------------
# 这就是你说的「单独的技术页面体 / 调试工具镜像」：
# 一个独立可用的镜像，装齐调试与排障工具，同时作为 6 个语言镜像的共同父层。
#
# 体积代价：约 +600MB，被 6 个语言镜像共享，所以摊到每个镜像只算 100MB。
# 严禁在这里装语言工具链（那是 L2 的事），否则 6 个镜像全被拖胖。
# ==================================================================
ARG BASE_IMAGE=devbox-base:local
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
ARG ACTIONLINT_VERSION=1.7.12
ARG ACTIONLINT_SHA256=8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8
ARG GIT_FILTER_REPO_VERSION=2.47.0
ARG GIT_FILTER_REPO_SHA256=67447413e273fc76809289111748870b6f6072f08b17efe94863a92d810b7d94

LABEL org.opencontainers.image.title="devbox-tool" \
      org.opencontainers.image.description="Ubuntu 24.04 调试工具层：gdb/lldb/strace/valgrind/tcpdump + zsh/tmux/fzf" \
      devbox.layer="tool"

# ------------------------------------------------------------------
# 调试与排障
#   gdb / lldb      —— 源码级调试（C++/Rust/Go 都用得上）
#   strace / ltrace —— 系统调用 / 库调用跟踪
#   valgrind        —— 内存错误与泄漏（C++ 主力）
#   tcpdump / socat —— 抓包与端口转发
#   sysstat / iotop —— 系统与 IO 观测
# 注意：perf 依赖宿主内核版本，容器内装了也大概率跑不了，
#       真要用 perf 走 `docker run --privileged --pid=host`，见 docs/01-镜像体系.md
# ------------------------------------------------------------------
# 交互环境
#   zsh + tmux + fzf + ripgrep + fd + bat  —— 不装 oh-my-zsh（省体积且免 GitHub 依赖）
#   neovim + universal-ctags               —— 容器内看代码
#   shellcheck + shfmt                     —— Shell 静态检查（shell 语言层复用）
# ------------------------------------------------------------------
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      gdb lldb \
      strace ltrace valgrind \
      tcpdump socat telnet \
      lsof htop sysstat iotop ncdu \
      httpie \
      zsh tmux fzf ripgrep fd-find bat \
      neovim universal-ctags graphviz \
      shellcheck shfmt gosu python3 \
    ; \
    # Ubuntu 把 fd/bat 装成 fdfind/batcat，建兼容软链
    ln -sf /usr/bin/fdfind /usr/local/bin/fd; \
    ln -sf /usr/bin/batcat /usr/local/bin/bat; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 固定版本与校验和来自 images/versions.env。
RUN set -eux; \
    case "$(uname -m)" in \
      x86_64) actionlint_arch=amd64 ;; \
      *) echo "actionlint 未锁定该架构的校验和: $(uname -m)" >&2; exit 1 ;; \
    esac; \
    curl -fsSL --retry 3 --retry-delay 2 \
      -o /tmp/actionlint.tar.gz \
      "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_${actionlint_arch}.tar.gz"; \
    echo "${ACTIONLINT_SHA256}  /tmp/actionlint.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/actionlint.tar.gz -C /tmp actionlint; \
    install -m 0755 /tmp/actionlint /usr/local/bin/actionlint; \
    curl -fsSL --retry 3 --retry-delay 2 \
      -o /usr/local/bin/git-filter-repo \
      "https://raw.githubusercontent.com/newren/git-filter-repo/v${GIT_FILTER_REPO_VERSION}/git-filter-repo"; \
    echo "${GIT_FILTER_REPO_SHA256}  /usr/local/bin/git-filter-repo" | sha256sum -c -; \
    chmod 0755 /usr/local/bin/git-filter-repo; \
    rm -f /tmp/actionlint.tar.gz /tmp/actionlint

# 用 /etc/skel 预置交互环境：新建用户自动继承，root 也直接生效
# 注意：不在这里用 `cat > file <<EOF`。heredoc 需要 buildx 的 dockerfile frontend
# （`# syntax=docker/dockerfile:1.4+`），而我们刻意不依赖那个 frontend
# （国内镜像对 docker/dockerfile 拉取会 403），所以配置一律作为文件 COPY 进去。
COPY images/tool/dotfiles/zshrc     /etc/skel/.zshrc
COPY images/tool/dotfiles/tmux.conf /etc/skel/.tmux.conf
RUN set -eux; \
    cp /etc/skel/.zshrc /root/.zshrc; \
    cp /etc/skel/.tmux.conf /root/.tmux.conf; \
    cp /etc/skel/.zshrc /home/dev/.zshrc; \
    cp /etc/skel/.tmux.conf /home/dev/.tmux.conf; \
    chown dev:dev /home/dev/.zshrc /home/dev/.tmux.conf

ENV EDITOR=nvim \
    PAGER=less

SHELL ["/bin/bash", "-c"]

# 自检：工具层必须能跑通「解析符号 + 抓包 + 静态检查」
RUN set -eux; \
    echo "==> tool smoke test"; \
    gdb --version | head -1; \
    lldb --version | head -1; \
    valgrind --version; \
    shellcheck --version | head -2; \
    tmux -V; \
    zsh --version; \
    gosu --version; \
    actionlint --version; \
    git filter-repo --version
