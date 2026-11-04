---
track: shell
guide: G5
dimensions: [D2, D5, D8]
level: P1
status: draft
links: [知识点清单.md, 开发指南.md, 工具指南.md]
examples: [L0-hello, L1-003-quoting-word-splitting, L1-030-strict-mode, L2-002-shellcheck-warning-gate]
---

# Shell 轨道 FAQ（G5）

> 按主题分组的短问答。每条先结论、再一步命令、最后给详见。
> G3 问题指南属 M8 未建，文中「详见 G3」均为占位指向，建好后自然生效。

## 环境与镜像

### Q: devbox-shell 里有哪些工具？yq 装了吗？
A: 实测预装 bash 5.2、dash(sh)、shellcheck 0.9.0、shfmt 3.8.0、bats 1.10.0、jq 1.7；**yq 未预装**（虽然 install/shell.sh 声明安装，属镜像与脚本漂移）。验证命令：`docker run --rm ghcr.io/zeek-zhao/devbox-shell:${TAG:-latest} bash -lc 'command -v shellcheck shfmt bats jq yq'`。详见 [工具指南](工具指南.md) §1。

### Q: shellcheck 的告警口径是什么级别？
A: 仓库门禁统一 `-S warning`（来自 `images/versions.env` 的 `${SHELLCHECK_SEVERITY}`），Makefile 与项目 build.sh 同口径，别在自己机器上用默认级别自测后提交。命令：`shellcheck -S warning <文件>`。详见 [工具指南](工具指南.md) §2。

### Q: bash 版本有锁吗？
A: 没锁——Ubuntu 24.04 系统自带 5.2 系，版本随基镜像走。验证命令：`docker run --rm ghcr.io/zeek-zhao/devbox-shell:${TAG:-latest} bash --version | head -1`。需要版本敏感的行为差异写成用例（如 L2-007-posix-bash-portability）。

## 跑用例

### Q: 一条命令跑一个用例？
A: `TAG=latest scripts/run-example.sh shell L0-hello`；列全部用例 `scripts/run-example.sh shell --list`。失败排查顺序见 [开发指南](开发指南.md) §3。

### Q: TAG 和 IMAGE_TAG 什么关系？
A: 同一个值的两个名字：本地用 `TAG`，CI 传 `IMAGE_TAG`，runner 两者都认。宿主机已有本地构建镜像时把 `TAG` 换成 `local`。详见 [开发指南](开发指南.md) §1。

### Q: 报镜像拉取失败（manifest unknown）？
A: 本机没有该 tag。`docker images | grep devbox-shell` 看本地有哪些，再拉 CI 发布 tag 或本地构建。详见 [开发指南](开发指南.md) §3。

### Q: 输出和 expected.txt 对不上，怎么复现？
A: `scripts/run-example.sh shell <ID> --keep` 保留容器，`docker exec` 进去单独跑该用例的 `run.sh` 逐行比对。详见 [开发指南](开发指南.md) §3。

## 工具链与语言行为

### Q: 变量加了值却变成多个参数？
A: 未引用的展开会按 IFS 拆词并做路径名展开，含空格的值必须 `"$value"`，转发参数用 `"$@"`。复现命令与讲解见 [工具指南](工具指南.md) §4 和用例 L1-003-quoting-word-splitting。

### Q: set -e 了为什么脚本没退出？
A: `if` 条件、`&&` 左侧、无 `pipefail` 的管道、命令替换内都不触发。基准写 `set -euo pipefail`（L1-030-strict-mode、L1-021-pipeline-pipefail）；可复现反例见 [工具指南](工具指南.md) §4。定位「哪步真失败了」可用 `bash -x script.sh`。

### Q: 脚本挂了留下临时目录怎么办？
A: `mktemp` 之后立刻 `trap 'rm -rf "$tmp"' EXIT`，信号场景补 `INT TERM`（L1-029-trap-mktemp、L3-006-signal-cleanup）。详见 [工具指南](工具指南.md) §4。

### Q: shfmt 用什么参数？
A: 仓库口径是 `shfmt -i 2 -ci -ln bash`，真本在 `scripts/fmt.sh`；日常直接 `make fmt` / `make fmt-check`，不要手拍参数。详见 [工具指南](工具指南.md) §2。

### Q: bats 测试怎么跑？
A: 进容器 `bats shell/project/tests/commands.bats`；筛选单个用例 `bats --filter <名字>`。用例写法见 L2-003-bats-run-assertions、L2-004-bats-fixtures。详见 [工具指南](工具指南.md) §2。

### Q: JSON 处理用什么？
A: jq（预装 1.7），`jq -r '.key'` 起步；教学用例 L3-003-jq-json-processing。YAML 侧 yq 当前镜像未预装，详见 [工具指南](工具指南.md) §2。

## 毕业项目

### Q: 项目怎么构建/自检？
A: `docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/work" -w /work ghcr.io/zeek-zhao/devbox-shell:${TAG:-latest} bash shell/project/build.sh`（bash -n + shellcheck warning 门禁）；运行自检 `bash shell/project/src/main.sh --self-check`。详见 [开发指南](开发指南.md) §4。

### Q: 幂等性是什么意思，怎么验收？
A: Shell 的「回滚」就是重复执行不产生副作用（docs/20 §3.4 R6）；项目里 deploy 步骤可重复跑且结果一致。对应用例 L2-010-idempotent-steps、L2-006-flock-reentrancy。

## 查不到时去哪查

1. 仓库内：先查 [知识点清单](知识点清单.md) 与用例 `README.md`，再查 [ROADMAP](../ROADMAP.md) KI 段与 [40-问题清单](../40-问题清单.md) 的 `Q-*` 定案；镜像与脚本不一致类问题（如 yq 缺失）可对照 `images/scripts/install/shell.sh`。
2. 要「现象 → 定位 → 修复」路径的：等 G3 问题指南（M8 未建）；在那之前用 [工具指南](工具指南.md) §4 的误用清单对照。
3. 上游文档：ShellCheck 官网（shellcheck.net，可在线贴脚本）、Bats 文档（github.com/bats-core）、shfmt（github.com/mvdan/sh）、GNU Bash 手册（gnu.org/software/bash/manual）——以本仓 `scripts/fmt.sh` / `versions.env` 口径优先。
4. 都没有：仓库 issue 搜索，带关键词（`devbox-shell`、`shellcheck`、`bats`、`run-example`）。
