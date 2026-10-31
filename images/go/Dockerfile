# ==================================================================
# L2  go —— Go 语言镜像  (FROM tool，与其他 5 个语言镜像横向并列)
# ==================================================================
ARG BASE_IMAGE=devbox-tool:local
FROM ${BASE_IMAGE}

ARG GO_VERSION=1.27.3
ARG GO_SHA256=65efbc80fdc1fa2cd2631cad5b481777a68e8725f34e89f50fc6ac714e379b40
ARG GOPROXY=https://goproxy.cn,direct
ARG GOSUMDB=sum.golang.google.cn

LABEL org.opencontainers.image.title="devbox-go" \
      devbox.layer="lang" \
      devbox.language="go"

COPY images/scripts/ /opt/devbox/scripts/
RUN bash /opt/devbox/scripts/install/go.sh

# GOTOOLCHAIN=local 是关键：否则 go.mod 里写更高的 go 版本时，
# go 命令会自作主张联网下新工具链，镜像就不可重现了
ENV GOROOT=/usr/local/go \
    GOPATH=/go \
    GOCACHE=/go/cache \
    GOTOOLCHAIN=local \
    GOFLAGS=-mod=mod \
    GOPROXY=${GOPROXY} \
    GOSUMDB=${GOSUMDB} \
    PATH=/usr/local/go/bin:/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /work/go
