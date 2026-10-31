# ==================================================================
# L2  shell —— Shell 语言镜像  (FROM tool，与其他 5 个语言镜像横向并列)
# ==================================================================
ARG BASE_IMAGE=devbox-tool:local
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="devbox-shell" \
      devbox.layer="lang" \
      devbox.language="shell"

COPY images/scripts/ /opt/devbox/scripts/
RUN bash /opt/devbox/scripts/install/shell.sh

WORKDIR /work/shell
