# devbox

六门语言的学习仓库：**C/C++、Go、Rust、Shell、Python、Java**。
每门语言都有三级用例 + 一个把全部用例串起来的毕业项目，全部跑在 Ubuntu 24.04 的分层 Docker 镜像里。

---

## 为什么长这样

- **镜像分层共享**：`base`（公共底座）→ `tool`（调试工具）→ 6 个语言镜像横向并列。
  6 门语言共用前两层，摊到每个镜像只多摊 100MB 左右；改 Java 不会让 C++ 层失效。
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
│   ├── run-example.sh       #   跑用例（330 个用例的唯一入口）
│   └── coverage-check.sh    #   「项目把用例用上了」的机器校验
├── .github/workflows/       # images.yml（建镜像）/ ci.yml（跑用例）
└── docs/                    # 仓库级文档
```

---

## 快速开始

```bash
# 1. 拉镜像（CI 构建好后）
docker pull ghcr.io/<owner>/devbox-cpp:latest

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
`scripts/dev.sh all` 进的是六语言总环境镜像（约 8-11G，只在需要切语言时用）。

---

## 镜像体系

| 层 | 镜像 | 含什么 | 参考体积 |
|---|---|---|---|
| L0 | `devbox-base` | 国内 apt 源、locale、git/curl/make/build-essential | ~1.1G |
| L1 | `devbox-tool` | gdb/lldb/strace/valgrind/tcpdump + zsh/tmux/fzf/ripgrep/shellcheck | ~2.2G |
| L2 | `devbox-cpp` | gcc-14 / clang-18 / cmake / ninja / gtest / cppcheck | ~3.5G |
| L2 | `devbox-go` | Go 1.27.3 官方工具链 | ~2.9G |
| L2 | `devbox-rust` | rustup + stable + clippy/rustfmt | ~3.3G |
| L2 | `devbox-shell` | bash 5.2 + bats + shellcheck + shfmt | ~2.3G |
| L2 | `devbox-python` | python3.12 + uv + ruff + mypy + pytest | ~2.6G |
| L2 | `devbox-java` | JDK 21 + Maven | ~3.3G |
| L3 | `devbox-all` | 六门语言合集（切语言用） | ~8-11G |
| L3 | `devbox-runtime` | 只要运行时，不含编译器（部署毕业项目） | ~0.4G |

> 体积是估算值，阶段 0 在 215 实测后回填。详见 [docs/01-镜像体系.md](docs/01-镜像体系.md)。

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

---

## 毕业项目与验收

每门语言一个项目，题目贴该语言的长处：

| 语言 | 项目 |
|---|---|
| C++ | 高性能文本索引器（mmap + 倒排索引 + 基准测试） |
| Go | 并发任务网关（worker pool + 限流 + 指标 + 优雅退出） |
| Rust | 跨平台 CLI 工具（clap + rayon + FFI + criterion） |
| Shell | 部署与巡检工具集（严格模式 + 信号 + 幂等 + BATS） |
| Python | 数据处理与报表（polars + CLI + 类型注解 + 打包） |
| Java | Spring Boot REST 服务（JPA + 事务 + 校验 + 集成测试） |

**「学完了」的判定是三条硬门禁**，机器可判：

1. 该语言全部用例 `run-example.sh <lang> --all` 全绿
2. 该项目 CI 全绿
3. `coverage-check.sh` 通过——`project/COVERAGE.md` 里声明的每个用例 ID，
   必须在 `project/` 的代码或测试里真实出现（表格本身不算，防止自证）

---

## 阶段计划

| 阶段 | 内容 | 状态 |
|---|---|---|
| 0 | 9 层镜像 + CI + 目录骨架 + runner + 每语言 1 个 hello 用例 | 进行中 |
| 1 | C++ 纵向打通：L1~L3 全量用例 + 毕业项目（作为样板） | 待开始 |
| 2 | 其余 5 门按同一模式铺开 | 待开始 |
| 3 | 六个毕业项目完成 + 进度看板 | 待开始 |

阶段 1 完成后，其余五门语言的节奏与写法照抄 C++，不再重新设计。
