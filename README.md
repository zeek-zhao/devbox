# devbox

六门语言的学习仓库：**C/C++、Go、Rust、Shell、Python、Java**。
每门语言都有三级用例 + 一个把全部用例串起来的毕业项目，全部跑在 Ubuntu 24.04 的分层 Docker 镜像里。

---

## 为什么长这样

- **镜像分层共享**：`base`（公共底座）→ `tool`（调试工具）→ 6 个语言镜像横向并列。
  6 门语言共用前两层，共享层只存一份；改 Java 不会让 C++ 层失效。
- **只在 CI 构建**：本地不 `docker build`，镜像由 GitHub Actions 构建并推到 GHCR，
  本地只 `docker pull`。所以每个语言 job 都强制跑一次 `hello` 用例——**证明镜像真能跑，而不是只能构建**。
- **版本单一真本**：所有版本号只在 [`images/versions.env`](images/versions.env) 写一次，
  Dockerfile 里写死版本号会被 CI 拦下。
- **语言安装逻辑单一真本**：每门语言的安装只写一份 `images/scripts/install/<lang>.sh`，
  语言镜像和总镜像 `all` 都调同一个脚本，杜绝两套逻辑漂移。

---

## 目录结构

```
devbox/
├── images/                  # 全部镜像定义（唯一的镜像真本）
│   ├── versions.env         #   版本单一真本
│   ├── base/  tool/         #   L0 公共底座 / L1 调试工具
│   ├── cpp/ go/ rust/ shell/ python/ java/   # L2 六门语言
│   ├── all/  runtime/       #   L3 总环境 / 部署运行时
│   └── scripts/             #   安装逻辑（install/*.sh）+ 自检
├── cpp/ go/ rust/ shell/ python/ java/       # 六门语言的学习内容
│   ├── examples/<ID>/       #   用例：run.sh + expected.txt（+ README.md）
│   ├── docs/                #   知识点文档
│   └── project/             #   毕业项目 + COVERAGE.md
├── scripts/                 # 仓库级工具
│   ├── build-images.sh      #   逐层构建（215 上迭代用）
│   ├── dev.sh               #   进容器
│   ├── run-example.sh       #   跑用例（309 个编号用例 + 6 个 hello 的唯一入口）
│   └── coverage-check.sh    #   「项目把用例用上了」的机器校验
├── .github/workflows/       # images.yml（建镜像）/ ci.yml（跑用例）
└── docs/                    # 仓库级文档
```

---

## 快速开始

```bash
# 1. 拉镜像（CI 构建好后）
docker pull ghcr.io/zeek-zhao/devbox-cpp:latest

# 2. 进容器写代码
TAG=latest scripts/dev.sh cpp

# 3. 跑一个用例
TAG=latest scripts/run-example.sh cpp hello

# 4. 跑一门语言的全部用例
TAG=latest scripts/run-example.sh cpp --all

# 5. 校验毕业项目的用例覆盖
bash scripts/coverage-check.sh
```

六门语言：`cpp` `go` `rust` `shell` `python` `java`。
`scripts/dev.sh all` 进的是六语言总环境镜像（体积预算 5.5 GB，只在需要切语言时用）。

---

## 镜像体系

| 层 | 镜像 | 含什么 | 体积预算（字节） |
|---|---|---|---|
| L0 | `devbox-base` | 国内 apt 源、locale、git/curl/make/build-essential | 700000000 |
| L1 | `devbox-tool` | gdb/lldb/strace/valgrind/tcpdump + zsh/tmux/fzf/ripgrep/shellcheck | 1300000000 |
| L2 | `devbox-cpp` | gcc-14 / clang-18 / cmake / ninja / gtest / cppcheck | 2200000000 |
| L2 | `devbox-go` | Go 1.27.3 官方工具链 | 1700000000 |
| L2 | `devbox-rust` | rustup + stable + clippy/rustfmt | 2200000000 |
| L2 | `devbox-shell` | bash 5.2 + bats + shellcheck + shfmt | 1400000000 |
| L2 | `devbox-python` | python3.12 + uv + ruff + mypy + pytest | 1700000000 |
| L2 | `devbox-java` | JDK 21 + Maven | 2000000000 |
| L3 | `devbox-all` | 六门语言合集（切语言用） | 5500000000 |
| L3 | `devbox-runtime` | 只要运行时，不含编译器（部署毕业项目） | 600000000 |

> 体积预算来自唯一真本 [`images/budgets.tsv`](images/budgets.tsv)，不是镜像实测体积；1 GB = 1000000000 字节。分层设计详见 [docs/01-镜像体系.md](docs/01-镜像体系.md)。

---

## 用例契约

每个用例是 `examples/` 下的一个目录，三个文件：

```
cpp/examples/L1-001-string-view/
├── run.sh          # 必须：自己负责编译与运行，只往 stdout 打业务输出
├── expected.txt    # 期望输出：逐行精确匹配（忽略行尾空白与首尾空行）
└── README.md       # 考点说明、易错点、延伸阅读
```

用例 ID 规则：`L1-<三位序号>-<短横线小写>`。
- **L1** 语言特性（每门 30-40 例）：语法、类型、标准库惯用法
- **L2** 工程能力（每门 10-15 例）：构建、依赖、测试、调试、性能剖析
- **L3** 专题（每门 5-8 例）：并发、FFI、网络、序列化

用例入口统一走 `scripts/run-example.sh`，不要各自写脚本。

当前有 **309 个 L1~L3 编号用例**：cpp 53 / go 53 / rust 50 / shell 53 / python 50 / java 50。
另有每门语言 1 个 `hello` 冒烟用例；`ls -d */examples/*/ | wc -l` 合计 **315**，`ls -d */examples/L*/ | wc -l` 为 **309**。

---

## 毕业项目与验收

每门语言一个项目，题目贴该语言的长处：

| 语言 | 项目（标准库实现） | 当前状态 |
|---|---|---|
| C++ | 高性能文本索引器（mmap + 倒排索引 + 基准测试） | 已实现 |
| Go | 并发任务网关（`net/http` + worker pool + 手写 Prometheus 文本 + `signal.NotifyContext`） | M4 进行中 |
| Rust | 跨平台 CLI 工具（手写参数解析 + `std::thread` + `std::time` 基准，无 clap/rayon） | M4 进行中 |
| Shell | 部署与巡检工具集（严格模式 + `flock` 幂等 + 并行 + BATS） | M4 进行中 |
| Python | CSV 数据处理与报表（`csv`/`collections`/`argparse`，无 polars） | M4 进行中 |
| Java | JDK 内置 `HttpServer` 的 REST 服务（手写 JSON + 内存存储 + 手写健康检查，无 Spring/Maven） | M4 进行中 |

镜像按 Q12 不预装第三方库，毕业项目采用上述标准库方案，保证完全离线可复现。

**「学完了」的判定是三条硬门禁**，机器可判：

1. 该语言全部用例 `run-example.sh <lang> --all` 全绿
2. 该项目 CI 全绿
3. `coverage-check.sh` 通过——`project/COVERAGE.md` 里声明的每个用例 ID，
   必须在 `project/` 的代码或测试里真实出现（表格本身不算，防止自证）

---

## 阶段计划

| 阶段 | 内容 | 状态 |
|---|---|---|
| M1 | 镜像 + CI + 目录骨架 + runner + 每语言 1 个 hello 用例 | 已完成 |
| M2 | C++ 纵向打通：L1~L3 全量用例 + 毕业项目（作为样板） | 已完成 |
| M3 | 其余 5 门按同一模式铺开 L1~L3 用例与知识点文档 | 已完成 |
| M4 | 其余 5 门毕业项目 + 基础设施收尾 + 进度看板 | 进行中 |

M1/M2/M3 的镜像、CI、用例与文档已落库，C++ 项目已有实现、测试和基准；其余五门项目仍是骨架，按方案 A 在 M4 实现。

进度看板：M4 完成后提供（计划路径：`docs/进度看板.html`）。
