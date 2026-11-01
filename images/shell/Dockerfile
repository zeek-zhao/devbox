# ==================================================================
# L2  shell —— Shell 语言镜像  (FROM tool，与其他 5 个语言镜像横向并列)
# ==================================================================
ARG BASE_IMAGE=devbox-tool:local
FROM ${BASE_IMAGE}

# yq 用于 shared/lib/yaml.sh；版本与校验和成对出现
ARG YQ_VERSION=4.44.3
ARG YQ_SHA256=a2c097180dd884a8d50c956ee16a9cec070f30a7947cf4ebf87d5f36213e9ed7

LABEL org.opencontainers.image.title="devbox-shell" \
      devbox.layer="lang" \
      devbox.language="shell"

COPY images/scripts/ /opt/devbox/scripts/
RUN bash /opt/devbox/scripts/install/shell.sh

WORKDIR /work/shell
