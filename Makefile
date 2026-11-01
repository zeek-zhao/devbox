# devbox 常用命令（Windows 上请用 Git Bash 或 WSL 执行）
SHELL := /bin/bash
TAG ?= latest

.PHONY: help images build-base build-tool build-lang examples coverage lint fmt fmt-check check-docs sha-modes

help:
	@echo "make images                 逐层构建全部镜像（需要 docker）"
	@echo "make build-base / build-tool 只建某一层"
	@echo "make build-lang LANG=cpp     只建某门语言"
	@echo "make examples LANG=cpp      跑某门语言全部用例（需镜像已存在）"
	@echo "make coverage               校验 COVERAGE.md"
	@echo "make lint                   静态检查"
	@echo "make fmt                    格式化全部语言（走容器，宿主无需装格式化器）"
	@echo "make fmt-check              只检查格式，有差异 exit 1（CI 用这个）"
	@echo "make check-docs             校验文档里的 <!-- verify: ... --> 命令"
	@echo "make sha-modes              修复脚本可执行位（Windows 上必备）"

images:
	bash scripts/build-images.sh --tag $(TAG)

build-base:
	bash scripts/build-images.sh --only base --tag $(TAG)

build-tool:
	bash scripts/build-images.sh --only tool --tag $(TAG)

build-lang:
	@test -n "$(LANG)" || { echo "用法: make build-lang LANG=cpp"; exit 2; }
	bash scripts/build-images.sh --only $(LANG) --tag $(TAG)

examples:
	@test -n "$(LANG)" || { echo "用法: make examples LANG=cpp"; exit 2; }
	TAG=$(TAG) bash scripts/run-example.sh $(LANG) --all

coverage:
	bash scripts/coverage-check.sh

lint:
	@command -v shellcheck >/dev/null && shellcheck -S warning scripts/*.sh images/scripts/*.sh images/scripts/install/*.sh || \
		echo "未安装 shellcheck，跳过（CI 里会跑）"

# 格式化器只装在语言镜像里，宿主没有 —— 所以这两个目标都走 docker。
# 不加 TAG 会去找 :local 标签（只有 base 层打过），六门语言镜像全是 :latest。
fmt:
	TAG=$(TAG) bash scripts/fmt.sh

fmt-check:
	TAG=$(TAG) bash scripts/fmt.sh --check

check-docs:
	bash scripts/check-docs.sh

# Windows 的 NTFS 会让 chmod 失效，脚本进 git 后是 100644，Linux 侧静默不执行。
# 这个目标把可执行位写进 git 索引，是跨平台仓库的必备补丁。
sha-modes:
	git ls-files -z '*.sh' | xargs -0 git update-index --chmod=+x
	git update-index --chmod=+x scripts/*.sh images/scripts/*.sh images/scripts/install/*.sh
