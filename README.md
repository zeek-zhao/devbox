# devbox

devbox 是一个教学型仓库：用可运行用例讲清技术点，再用毕业项目把用例中的能力落到真实程序。当前有 **9 条学习轨道、608 个用例**：8 门编程语言与 1 条数据库轨道。

## 轨道一览

| 轨道 | 用例数 | 毕业项目 | 一句话说明 | 镜像层 / 运行环境 |
|---|---:|---|---|---|
| C | 78 | 带连接池的 HTTP 服务 | 纯 ISO C17 与 libc，复用 C++ 工具链 | `devbox-cpp` |
| C++ | 77 | 高性能文本索引器 | C++ 工程、并发、索引与性能测量 | `devbox-cpp` |
| 数据库 | 77 | 带缓存的订单服务 | MySQL、PostgreSQL、MongoDB、Redis、SQLite | 独立 Compose runner：五个数据库服务 + toolbox |
| Go | 77 | 并发任务网关 | 标准库 HTTP 服务、worker pool 与指标 | `devbox-go` |
| Java | 74 | JDK `HttpServer` REST 服务 | 手写 JSON 与内存存储，不依赖 Spring | `devbox-java` |
| Python | 74 | CSV 数据处理与报表 | 标准库 CSV、集合与命令行处理 | `devbox-python` |
| Rust | 51 | 跨平台 CLI 工具 | 标准库参数解析、线程与基准测量 | `devbox-rust` |
| Shell | 54 | 部署与巡检工具集 | 严格模式、幂等、并行与 BATS | `devbox-shell` |
| Vue | 46 | SSR 待办应用 | Vue SFC 与 SSR，不使用 Vite | `devbox-vue` |

用例数按各轨道 `examples/` 的直接子目录计数，包含 `hello`（存在时）；C/C++ 共用镜像不代表共用用例目录。镜像映射以 [`images/lang-images.tsv`](images/lang-images.tsv) 为准。

## 目录结构

```text
devbox/
├── c/ cpp/ go/ java/ python/ rust/ shell/ vue/
│   ├── examples/<ID>/       # 可运行用例；每例包含 run.sh、expected.txt、README.md
│   ├── docs/                # 该轨道的知识点与学习资料（部分轨道尚无此目录）
│   └── project/             # 毕业项目及 COVERAGE.md（尚无项目的轨道暂不含此目录）
├── db/
│   ├── examples/<ID>/       # 数据库用例
│   ├── project/             # 数据库毕业项目与覆盖声明
│   ├── docker/              # 五个数据库服务与 toolbox 的 Compose 配置
│   └── scripts/             # 数据库轨道独立 runner 与服务管理
├── images/                  # 分层镜像定义及依赖版本真本
│   ├── base/ tool/          # 公共底座与调试工具层
│   ├── cpp/ go/ java/ python/ rust/ shell/ vue/    # 语言镜像层；C 复用 cpp 层
│   └── scripts/             # 镜像安装脚本
├── shared/                  # 跨轨道复用的 shell 工具
├── scripts/                 # 仓库级 runner、覆盖检查、构建与门禁脚本
└── docs/                    # 仓库级说明与进度看板
```

`examples/` 放逐例可运行的知识点练习；`project/` 放整合练习的毕业项目及覆盖表；`docs/` 放轨道知识资料或仓库级说明。目录只展示仓库中已经存在的部分；九条轨道现在都有 `project/`。

## 快速开始

先准备镜像，再运行一门轨道的全部用例：

```bash
make build-lang LANG=cpp TAG=local
make examples LANG=cpp TAG=local
```

215 上已有的镜像使用 `:local`；CI 发布和拉取的镜像使用 `:latest`。如使用已发布镜像，可用 `docker pull ghcr.io/zeek-zhao/devbox-cpp:latest` 代替构建，并以 `TAG=latest` 运行 `make examples`。镜像映射与构建细节见 [镜像体系](docs/01-镜像体系.md)。

## 用例契约

每个用例目录恰好包含三个文件：

```text
cpp/examples/L1-001-string-view/
├── run.sh          # 可执行；set -euo pipefail；业务结果写 stdout
├── expected.txt    # 期望输出
└── README.md       # 考点、判据与边界
```

runner 将 `run.sh` 的 stdout 与 `expected.txt` 逐行比较；行尾空白和首尾空行在比较时忽略，其余输出必须一致。用例 ID 中的 `L1`–`L4` 表示难度层级。集合输出应显式排序，浮点数使用固定精度，避免同一用例重复运行产生不确定输出。

## 覆盖表

有毕业项目的轨道在 `project/COVERAGE.md` 声明项目实际覆盖哪些用例，`bash scripts/coverage-check.sh <轨道>` 会核对声明与项目代码。`pending` 表示用例已存在、但尚未接入项目，是未完成项；`exempt` 表示该用例与项目形态天然无关，必须附上具体理由。二者不能用来掩盖漏接入；严格检查使用 `bash scripts/coverage-check.sh <轨道> --strict`。

## CI 与合并前校验

PR 阶段不跑 CI；`push main` 跑 fast（180 秒预算）；`push tag v*` 跑 full。合并前由本地 `scripts/pre-merge.sh` 执行总闸。档位、触发条件和具体检查见 [CI 分级说明](docs/02-CI分级.md)，这里不重复其细节。

## 门禁文件

门禁文件定义校验标准本身，例如 CI workflow、runner、覆盖/预算检查脚本、版本真本和格式化配置。改动它们可能改变「什么算通过」，因此 AI 不得擅自修改；完整清单及检查方式见 [`scripts/gate-files.txt`](scripts/gate-files.txt)。

## 增加一门语言

按 [CI 分级说明的末节](docs/02-CI分级.md) 接线：在 `images/lang-images.tsv` 登记语言到镜像层的映射，并把该语言加入 `ci.yml` 与 `full.yml` 的 matrix。C 复用 `devbox-cpp` 镜像；遗漏 matrix 会导致该轨道静默不进入 CI。

## 版本真本

`VERSION` 是项目版本真本；`images/versions.env` 是镜像依赖版本真本。两者物理隔离、用途不同，不要把依赖版本写进项目版本文件，也不要把项目版本混入镜像依赖清单。

## 格式化

格式化器运行在各自语言镜像中，使用 `bash scripts/fmt.sh --check --lang <轨道>` 检查。宿主已有 `:local` 镜像时设置 `TAG=local`；CI 使用 `:latest`。

<!-- verify: bash scripts/fmt.sh --list -->
<!-- verify: make help -->
