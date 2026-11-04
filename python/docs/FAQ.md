---
track: python
guide: G5
dimensions: [D2, D5, D8]
level: P1
status: draft
links: [知识点清单.md, 开发指南.md, 工具指南.md]
examples: [L0-hello, L2-005-ruff-check, L2-002-pytest-basics]
---

# Python 轨道 FAQ（G5）

> 按主题分组的短问答。每条先结论、再一步命令、最后给详见。
> G3 问题指南属 M8 未建，文中「详见 G3」均为占位指向，建好后自然生效。

## 环境与镜像

### Q: devbox-python 里 Python 到底是什么版本？
A: 主次版本由 `images/versions.env` 的 `${PYTHON_VERSION}` 锁定（当前 3.12 系），补丁号以容器实测为准。一步验证：`docker run --rm ghcr.io/zeek-zhao/devbox-python:${TAG:-latest} python3 --version`。详见 [工具指南](工具指南.md) §1。

### Q: 语言层和 runtime 层差在哪？为什么 src 不能用 pytest？
A: `devbox-python` 带完整工具链（ruff/mypy/pytest/uv 等），`devbox-runtime` 只有 python3 解释器与最小运行库（实测连 `import json` 都失败），无 pip/ruff/mypy/pytest。所以毕业项目 `src/` 只依赖标准库，构建与测试都在语言层镜像里离线跑。验证命令：`docker run --rm ghcr.io/zeek-zhao/devbox-runtime:${TAG:-latest} python3 -c 'import json'`（实测报 ModuleNotFoundError）。详见 [开发指南](开发指南.md) §1。

### Q: 容器里能 pip install 吗？
A: 不能依赖它：用例容器 `--network none` 离线启动，且运行时装的包不进镜像。要加依赖改 `images/scripts/install/python.sh` 走镜像重建。详见 [工具指南](工具指南.md) §4。

## 跑用例

### Q: 一条命令跑一个用例？
A: `TAG=latest scripts/run-example.sh python L0-hello`；列全部用例 `scripts/run-example.sh python --list`。失败排查顺序见 [开发指南](开发指南.md) §3。

### Q: TAG 和 IMAGE_TAG 是什么关系？
A: 同一个值的两个名字：本地用 `TAG`，CI 传 `IMAGE_TAG`，runner 两者都认。本地调试若宿主机已有本地构建的镜像，把 `TAG` 换成 `local`。详见 [开发指南](开发指南.md) §1。

### Q: 跑用例报镜像拉取失败（manifest unknown）？
A: 本机没有该 tag 的镜像。先 `docker images | grep devbox-python` 看本地有什么，再决定拉 CI 发布 tag 或本地 `scripts/build-images.sh` 构建。详见 [开发指南](开发指南.md) §3。

### Q: 输出和 expected.txt 对不上，怎么进容器复现？
A: `scripts/run-example.sh python <ID> --keep` 保留容器，然后 `docker exec` 进去单独跑目录里的 `run.sh` 对比输出。详见 [开发指南](开发指南.md) §3。

## 工具链

### Q: ruff / pytest / mypy 版本和知识点清单里写的不一致？
A: 清单与本文的数字是快照；这三个工具未在 `images/versions.env` 锁补丁号，以容器 `--version` 实测为准。命令：`docker run --rm ghcr.io/zeek-zhao/devbox-python:${TAG:-latest} bash -lc 'ruff --version && pytest --version && mypy --version'`。详见 [工具指南](工具指南.md) §1。

### Q: 格式化本地过了 CI 却报差异？
A: 本地与 CI 的 ruff 版本或入口不一致。统一走仓库入口：`make fmt` 改、`make fmt-check` 查；规则只认仓库根 `ruff.toml`，不要另建 pyproject.toml。详见 [工具指南](工具指南.md) §2/§4。

### Q: mypy --strict 报错太多，从哪开始修？
A: 这是毕业项目口径（src 严格、tests 不强求）。按文件从报错最少的开始收敛，类型知识用例是 L2-003-typing-protocols、L2-004-mypy-check。详见 [工具指南](工具指南.md) §2。

## 毕业项目

### Q: 项目怎么构建/自检？
A: `bash python/project/build.sh`（容器内 ruff check → mypy --strict → pytest），运行自检 `bash python/project/check-runtime.sh`。详见 [开发指南](开发指南.md) §4。

### Q: 金额为什么用整数分？
A: 避免浮点误差：输入最多两位小数，内部以非负整数分存储与聚合。这是项目约定，不是通用规则；对应测试在 `python/project/tests/`。详见知识点清单 L1-026-numbers-bool 与 `python/project/COVERAGE.md`。

## 查不到时去哪查

1. 仓库内：先查 [知识点清单](知识点清单.md) 与用例 `README.md`，再查 [ROADMAP](../ROADMAP.md) 的 KI 段与 [40-问题清单](../40-问题清单.md) 的 `Q-G-*`/`Q-S-*` 定案。
2. 出错现象要「现象 → 定位 → 修复」路径的：等 G3 问题指南（M8 未建）；在那之前用 [工具指南](工具指南.md) §4 的误用清单对照。
3. 上游文档：Python 官方 docs（docs.python.org）、ruff（docs.astral.sh/ruff）、pytest（docs.pytest.org）、mypy（mypy.readthedocs.io）——注意以本仓 `ruff.toml` / `versions.env` 的口径优先。
4. 都没有：仓库 issue 搜索，带关键词（如 `devbox-python`、`run-example`、`ruff`）。
