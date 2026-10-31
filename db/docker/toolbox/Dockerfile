# toolbox —— 用例的执行体：所有客户端 + Python 驱动
# ------------------------------------------------------------------
# 用例的 run.sh 跑在宿主上，通过 docker compose exec 进到这个容器执行 SQL / 脚本。
# 这样用例不用假设宿主装了什么客户端。
ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

# Ubuntu 24.04 用 deb822 格式的源文件；同时兼容老格式
RUN set -eux; \
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
      sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g; s@//.*security.ubuntu.com@//mirrors.ustc.edu.cn@g' \
        /etc/apt/sources.list.d/ubuntu.sources; \
    fi; \
    if [ -f /etc/apt/sources.list ]; then \
      sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g; s@//.*security.ubuntu.com@//mirrors.ustc.edu.cn@g' \
        /etc/apt/sources.list; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates curl default-mysql-client postgresql-client redis-tools \
      sqlite3 python3 python3-pip procps; \
    rm -rf /var/lib/apt/lists/*

# 驱动：Mongo 没有稳定的 CLI 客户端包，统一用 pymongo；其余也用驱动做复杂断言
RUN pip3 install --break-system-packages --no-cache-dir \
      -i https://pypi.tuna.tsinghua.edu.cn/simple \
      pymysql psycopg2-binary redis pymongo

WORKDIR /workspace/db
CMD ["sleep", "infinity"]
