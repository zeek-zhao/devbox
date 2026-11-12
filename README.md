# devbox

[![ci](https://github.com/zeek-zhao/devbox/actions/workflows/ci.yml/badge.svg)](https://github.com/zeek-zhao/devbox/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![用例](https://img.shields.io/badge/用例-821-success.svg)](docs/ROADMAP.md)
[![轨道](https://img.shields.io/badge/轨道-9-informational.svg)](#轨道一览)

用**可运行、可逐字验证**的用例讲清技术点，再用毕业项目把用例里的能力落到真实程序。
当前 **10 条轨道（9 条学习轨道 + 1 条 shared 工具箱）、821 个 examples 目录（659 存量用例 + 135 个 E 类错误处理示例 + 10 个排障演练 + 17 个 shell 轨补齐用例）、9 个毕业项目**：8 门编程语言 + 1 条数据库轨道 + 1 条工具箱轨道。

每个用例都是一个最小可跑单元：`run.sh` 执行、`expected.txt` 逐行比对。跑不通就是没学会，
不存在「看懂了但写不出来」的模糊地带。

## 轨道一览

| 轨道 | 用例数 | 毕业项目 | 一句话说明 | 镜像层 / 运行环境 |
|---|---:|---|---|---|
| C | 78 | 带连接池的 HTTP 服务 | 纯 ISO C17 与 libc，复用 C++ 工具链 | `devbox-cpp` |
| C++ | 77 | 高性能文本索引器 | C++ 工程、并发、索引与性能测量 | `devbox-cpp` |
| 数据库 | 77 | 带缓存的订单服务 | MySQL、PostgreSQL、MongoDB、Redis、SQLite | 独立 Compose runner：五个数据库服务 + toolbox |
| Go | 77 | 并发任务网关 | 标准库 HTTP 服务、worker pool 与指标 | `devbox-go` |
| Java | 74 | JDK `HttpServer` REST 服务 | 手写 JSON 与内存存储，不依赖 Spring | `devbox-java` |
| Python | 74 | CSV 数据处理与报表 | 标准库 CSV、集合与命令行处理 | `devbox-python` |
| Rust | 74 | 跨平台 CLI 工具 | 标准库参数解析、线程与基准测量 | `devbox-rust` |
| Shell | 54 | 部署与巡检工具集 | 严格模式、幂等、并行与 BATS | `devbox-shell` |
| Vue | 74 | SSR 待办应用 | Vue SFC 与 SSR，不使用 Vite | `devbox-vue` |

用例数按各轨道 `examples/` 的直接子目录计数，包含 `L0-hello`（存在时）；C/C++ 共用镜像
不代表共用用例目录。镜像映射以 [`images/lang-images.tsv`](images/lang-images.tsv) 为准。

## 目录结构

```text
devbox/
├── c/ cpp/ go/ java/ python/ rust/ shell/ vue/
│   ├── examples/<ID>/       # 可运行用例；每例包含 run.sh、expected.txt、README.md
│   ├── docs/                # 该轨道的知识点与学习资料
│   └── project/             # 毕业项目及 COVERAGE.md
├── db/
│   ├── examples/<ID>/       # 数据库用例
│   ├── project/             # 数据库毕业项目与覆盖声明
│   ├── docker/              # 五个数据库服务与 toolbox 的 Compose 配置
│   └── scripts/             # 数据库轨道独立 runner 与服务管理
├── images/                  # 分层镜像定义及依赖版本真本
│   ├── base/ tool/          # 公共底座与调试工具层
│   ├── cpp/ go/ java/ python/ rust/ shell/ vue/    # 语言镜像层；C 复用 cpp 层
│   └── scripts/             # 镜像安装脚本
├── shared/                  # 跨轨道复用的 shell 工具与发布辅助
├── scripts/                 # 仓库级 runner、覆盖检查、构建与门禁脚本
└── docs/                    # 仓库级说明、路线图、已知问题、开源合规审计
```

`examples/` 放逐例可运行的知识点练习；`project/` 放整合练习的毕业项目及覆盖表；
`docs/` 放轨道知识资料或仓库级说明。九条轨道现在都有 `project/`。

## 快速开始

镜像已发布到 GHCR，直接用就行：

```bash
git clone https://github.com/zeek-zhao/devbox.git
cd devbox

# 跑一门轨道的全部用例（拉取已发布镜像）
make examples LANG=cpp TAG=latest

# 只跑一条用例
bash scripts/run-example.sh cpp L1-001-string-view
```

想自己构建镜像（改了 `images/` 或想固定依赖版本时）：

```bash
make build-lang LANG=cpp TAG=local
make examples   LANG=cpp TAG=local
```

`TAG=latest` 用 CI 发布的镜像，`TAG=local` 用本地构建的镜像。镜像映射与构建细节见
[镜像体系](docs/01-镜像体系.md)。

镜像默认以非 root 用户 `dev` 运行，其 uid/gid 会在启动时对齐 `HOST_UID`/`HOST_GID`；
需要 root 时可使用 `-e DEVBOX_AS_ROOT=1`。

## 用例契约

每个用例目录恰好包含三个文件：

```text
cpp/examples/L1-001-string-view/
├── run.sh          # 可执行；set -euo pipefail；业务结果写 stdout
├── expected.txt    # 期望输出
└── README.md       # 考点、判据与边界
```

runner 将 `run.sh` 的 stdout 与 `expected.txt` 逐行比较；行尾空白和首尾空行在比较时忽略，
其余输出必须一致。用例 ID 中的 `L1`–`L4` 表示难度层级。

**输出必须确定**：集合输出显式排序，浮点数固定精度，不打印时间戳、随机数、容器 IP 或耗时。
同一条用例连跑两次必须完全一致——不确定性用例会以随机间隔假红，是最难排查的一类缺陷。

## 排障演练（labs，已迁入 examples/）

821 个 examples 目录中有 **10 个排障演练**（`<lang>/examples/T-NNN-<slug>/`，2026-11-12 由 `<lang>/labs/` 迁入）：埋一个真实故障，用 ASan / valgrind / race detector / shellcheck 等工具真跑排查，配逐行判读文档。规范见 [docs/72-排障演练规范](docs/72-排障演练规范.md)。

**演练与普通用例的区别**：演练计入 examples 目录计数（821 口径），但不走 `expected.txt` 逐行比对——`scripts/run-example.sh --all` 显式跳过 `T-*` 前缀，由 `ci.yml` 的 labs job 独占真跑；每个目录带 README 的 `coverage: exempt`。跑法：

```bash
bash <lang>/examples/T-001-<slug>/run.sh      # 完整演练流程
bash <lang>/examples/T-001-<slug>/assert.sh   # 断言：关键诊断行 + 退出码
```

## 覆盖表

有毕业项目的轨道在 `project/COVERAGE.md` 声明项目实际覆盖哪些用例，
`bash scripts/coverage-check.sh <轨道>` 会核对声明与项目代码。

- `pending` —— 用例已存在但尚未接入项目，属于**未完成项**，`--strict` 下算失败
- `exempt <理由>` —— 该用例与项目形态天然无关，属于**已决策项**，理由必填

二者不能用来掩盖漏接入：覆盖校验只认非文档文件里的引用，把用例 ID 抄进 README 表格
是不算的。

## 校验与流水线

```bash
bash scripts/coverage-check.sh <轨道>            # 覆盖表自洽
bash scripts/coverage-check.sh <轨道> --strict   # 不留 pending
bash scripts/fmt.sh --check --lang <轨道>        # 格式化
bash scripts/pre-merge.sh --base main            # 全量总闸（约 15 分钟）
```

流水线对所有触发（`push`、`pull_request`、打 tag）都跑全量：811 个用例 + 10 个排障演练（共 821 个 examples 目录）+ 8 门格式 +
覆盖表 + 镜像构建 + 体积预算，单次约 20–25 分钟。仓库是公开的，Actions 分钟数不计量，
所以不再按场景省测。细节见 [流水线说明](docs/02-流水线.md)。

## 门禁文件

门禁文件定义的是「什么算通过」，而不是「通过什么」：CI workflow、runner、覆盖/预算检查
脚本、版本真本、格式化配置、镜像安装逻辑。改动它们可能改变判定标准本身，因此必须单独
一个 PR 并写明理由。完整清单见 [`scripts/gate-files.txt`](scripts/gate-files.txt)。

## 增加一门语言

1. 在 `images/lang-images.tsv` 登记「语言 → 镜像层」映射
2. 在 `images/` 下加该语言的 Dockerfile 与安装脚本
3. 把该语言加入 `.github/workflows/ci.yml` 的 matrix
4. 建 `examples/`、`docs/`、`project/` 三个目录

第 3 步最容易漏——遗漏 matrix 会让该轨道**静默不进入 CI**，本地全绿而远端从不校验。

## 版本真本

`VERSION` 是项目版本真本；`images/versions.env` 是镜像依赖版本真本。两者物理隔离、
用途不同：不要把依赖版本写进项目版本文件，也不要把项目版本混入镜像依赖清单。
发版时 `full` 档会校验 `VERSION` 与 tag 逐字一致。

## 格式化

格式化器运行在各自语言镜像中：

```bash
bash scripts/fmt.sh --check --lang <轨道>
bash scripts/fmt.sh --list
```

`scripts/run-example.sh` 默认用 `TAG=local`（宿主已构建的本地镜像）；CI 与远端通过 `IMAGE_TAG=latest` 指定 tag，也可用 `TAG=latest` 显式覆盖。

## 项目现状

- [路线图与里程碑](docs/ROADMAP.md)
- [已知问题与路线图](docs/ROADMAP.md)
- [开源合规审计](docs/开源合规审计.md)
- [贡献指南](CONTRIBUTING.md) · [安全策略](SECURITY.md) · [行为准则](CODE_OF_CONDUCT.md)

## 许可

本仓库的代码与文档以 [Apache License 2.0](LICENSE) 授权，第三方组件说明见 [NOTICE](NOTICE)。

## 声明

- 本项目名称 `devbox` 仅为项目代号，与 JetBrains Devbox、HashiCorp 等相关产品或商标
  **无任何关联**。
- 所有容器配置中的口令（如 `password: devbox`）都是本地教学用固定值，服务只监听 Docker
  内部网络。**不要把这些配置用于任何联网环境**，详见 [SECURITY.md](SECURITY.md)。

<!-- verify: bash scripts/fmt.sh --list -->
<!-- verify: make help -->
