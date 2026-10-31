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
      shellcheck shfmt \
    ; \
    # Ubuntu 把 fd/bat 装成 fdfind/batcat，建兼容软链
    ln -sf /usr/bin/fdfind /usr/local/bin/fd; \
    ln -sf /usr/bin/batcat /usr/local/bin/bat; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 用 /etc/skel 预置交互环境：新建用户自动继承，root 也直接生效
RUN set -eux; \
    mkdir -p /etc/skel; \
    cat > /etc/skel/.zshrc <<'EOF'
# devbox tool 层默认 zsh 配置（改这里会重建 tool 层）
export LANG=en_US.UTF-8
export EDITOR=nvim
export PAGER=less
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS INTERACTIVE_COMMENTS
autoload -Uz compinit && compinit
autoload -U colors && colors
PROMPT='%F{cyan}%n@devbox%f:%F{yellow}%~%f %# '
alias ll='ls -lahF --color=auto --time-style=long-iso'
alias la='ls -A --color=auto'
alias gs='git status -sb'
alias gd='git diff'
alias dc='docker compose'
alias rg='rg --smart-case'
# 快速在容器里看某命令怎么用
alias ?='compgen -c | sort -u | fzf'
EOF
    cat > /etc/skel/.tmux.conf <<'EOF'
set -g mouse on
set -g history-limit 10000
set -g base-index 1
setw -g pane-base-index 1
set -g default-terminal "screen-256color"
set -g status-style 'bg=colour236 fg=colour250'
set -g status-left '#[fg=colour51][#S] '
set -g status-right '#[fg=colour250]%Y-%m-%d %H:%M '
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
EOF
    cp /etc/skel/.zshrc /root/.zshrc; \
    cp /etc/skel/.tmux.conf /root/.tmux.conf

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
    zsh --version
