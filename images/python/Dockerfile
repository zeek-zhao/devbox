# ==================================================================
# L2  python —— Python 语言镜像  (FROM tool，与其他 5 个语言镜像横向并列)
# ==================================================================
ARG BASE_IMAGE=devbox-tool:local
FROM ${BASE_IMAGE}

ARG PYTHON_VERSION=3.12
ARG PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple

LABEL org.opencontainers.image.title="devbox-python" \
      devbox.layer="lang" \
      devbox.language="python"

COPY images/scripts/ /opt/devbox/scripts/
RUN bash /opt/devbox/scripts/install/python.sh

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_INDEX_URL=${PIP_INDEX_URL} \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /work/python
