---
track: cpp
guide: G5
dimensions: [D2, D5, D8]
level: P2
status: draft
links: [知识点清单.md, 用例编写规范.md, 实践指南.md, 开发指南.md, 问题指南.md, 工具指南.md]
examples: [L0-hello, L1-010-stl-containers, L1-012-iterators-algorithms, L2-002-cmake-targets, L2-005-test-harness, L2-007-gdb-debugging]
---

# C++ FAQ（G5）

> 高频短问答，按主题分组。每条：结论 → 一步命令 → 详见 G3/G4。
> 组织口径：G3 按问题域（一个域 500–1500 字排查路径），本篇按提问频率（一条 50–200 字），
> 卡在具体故障时去 [问题指南.md](问题指南.md)，查参数去 [工具指南.md](工具指南.md)。
> 版本号只引用 `images/versions.env` 变量；用例命令遵守规范 §4.3 契约。

## 上手与环境

### Q: 环境装好了吗？一条命令怎么自检？

A: 跑通路用例 `L0-hello`（L0 是环境自检层，不考知识点）：
`TAG=latest scripts/run-example.sh cpp L0-hello`，实测输出 `PASS (1s)`。
红先查镜像与 tag：详见 [问题指南.md](问题指南.md)「镜像与标签」。

### Q: 镜像从哪拉？tag 用 latest 还是别的？

A: `docker pull "ghcr.io/zeek-zhao/devbox-cpp:${TAG:-latest}"`（前缀真本
`images/versions.env` 的 `REGISTRY`）。日常用 `latest`，要可复现用 `sha-<commit>`
（`latest` 随 main 变动，ROADMAP `KI-08`）。详见 [问题指南.md](问题指南.md)「镜像与标签」。

### Q: 容器里是 root 吗？

A: devbox 语言镜像默认以非 root 的 `dev` 运行（历史改动见 ROADMAP `KI-07` 的
对比描述）；需要 root 显式开启。db 轨道的 toolbox 例外，与本轨道无关。

### Q: 本地已经 docker build 过镜像，怎么让 runner 用它？

A: runner 的 `TAG` 默认就是 `local`（取值顺序 `TAG` → `IMAGE_TAG` → `local`，
真本 `scripts/run-example.sh`），直接 `TAG=local scripts/run-example.sh cpp <ID>`。
注意 `local` 只是本地约定，别写死进文档或 CI。详见 [实践指南.md](实践指南.md) §4。

## 跑用例

### Q: 用例目录里必须有哪些文件？

A: 三件套：`run.sh`（自编译自运行，只往 stdout 打业务输出）、`expected.txt`
（逐行精确比对）、`README.md`（考点说明）。缺 `run.sh` 实测报 `NO-RUNNER`。
详见 [问题指南.md](问题指南.md)「用例三文件契约」与 [用例编写规范.md](用例编写规范.md)。

### Q: 输出跟 expected.txt 不一致（DIFF）怎么办？

A: 先 `--keep` 进容器手工跑 `run.sh`，diff 实际输出与期望输出；
行为改对了才按 [用例编写规范.md](用例编写规范.md) 更新期望文件，
`--update` 仅限新写用例。详见 [问题指南.md](问题指南.md)「用例三文件契约」。

### Q: 77 个用例怎么一把全跑？

A: `TAG=latest scripts/run-example.sh cpp --all`（与 CI 的 `examples` job 同入口）；
只看列表用 `--list`。单例跑法见 [开发指南.md](开发指南.md) §3。

### Q: L1/L2/L3/L4 是什么意思？先练哪个？

A: L1 语言特性、L2 工程能力（构建/测试/CI）、L3 专题（并发/序列化/FFI）、
L4 设计模式，共 77 例；一张表见 [知识点清单.md](知识点清单.md)，
顺序按清单从上往下，每个 KP 一个用例。先 `L0-hello` 验通路再往下。

## 构建与格式化

### Q: 格式化命令是什么？为什么我本机 clang-format 报不存在？

A: 走 `make fmt` / `bash scripts/fmt.sh --check --lang cpp`——工具只在镜像里，
宿主没有；版本约束 `${CLANG_FORMAT_MAJOR}` 与 `${CLANG_MAJOR}` 同步。
详见 [工具指南.md](工具指南.md) §2 与 [问题指南.md](问题指南.md)「格式化与门禁漂移」。

### Q: 版本号能不能直接写死在文档里？

A: 不能。一律写 `images/versions.env` 的变量名（如 `${GCC_MAJOR}`、
`${CMAKE_MIN_VERSION}`）并注明真本，否则升级时集体过期且过不了
`scripts/check-version-truth.sh`（规范 §4.4）。

### Q: CMake 从哪练？

A: `TAG=latest scripts/run-example.sh cpp L2-002-cmake-targets`——配置、构建、
安装一条链，构建目录保持干净（呼应 `L2-003-reproducible-build`）。
参数速查见 [工具指南.md](工具指南.md) §2。

## 工具与排查

### Q: 断言怎么突然全不生效了？

A: 八成是构建加了 `-DNDEBUG`——实测断言被整个编译掉，测试假绿。
去掉 NDEBUG 重建。详见 [问题指南.md](问题指南.md)「断言失效与消毒器冲突」。

### Q: ASan 和 TSan 能不能一起开？

A: 不能，实测编译器报 `'-fsanitize=thread' is incompatible with '-fsanitize=address'`。
分开构建分别跑；选型对比见 [工具指南.md](工具指南.md) §3。

### Q: 怎么用 gdb 调试用例？

A: `TAG=latest scripts/run-example.sh cpp L2-007-gdb-debugging --keep` 保留容器，
`docker exec` 进会话；编译带 `-g`，优化构建会内联重排。速查见 [工具指南.md](工具指南.md) §2。

### Q: vector 扩容后原来的指针/迭代器还能用吗？

A: 不能，扩容会使指向元素的指针与迭代器失效（`L1-010-stl-containers` /
`L1-012-iterators-algorithms` 的关键易错点）；需要稳定位置选别的容器，
选型依据见 [知识点清单.md](知识点清单.md) KP-L1-11。

## 流程与门禁

### Q: CI 全红，先看哪个 job？

A: 先 `static`（不依赖镜像、最快）与 `probe`（镜像存在性），再按红掉的 job
（fmt / examples / authors）对症查；通用动线见 docs/02-流水线.md 与
[docs/13-通用开发指南.md](../../docs/13-通用开发指南.md)（T0 真本）。

### Q: 提交身份有什么要求？

A: 作者须在仓库白名单内，且禁止 AI 署名尾巴（CI 的 `authors` job 会卡）；
通用提交约定见 [docs/13-通用开发指南.md](../../docs/13-通用开发指南.md)。

### Q: 指南的 status 为什么都是 draft？什么时候能变 verified？

A: `draft → reviewed → verified` 是单向状态机，判据见《知识点清单增强规范》§7.1：
`reviewed` 需人工抽读，`verified` 需命令在镜像真跑过 + 通过反向测试，
均不许自评。本篇当前 `status: draft`，如实反映现状。

## 查不到时去哪查

1. **已登记的已知问题**：docs/ROADMAP.md 的「已知问题与限制（`KI-*` 编号）」一节，
   每条带 issue 编号；已解决的（`KI-03/04/05`）也在文末保留编号；
2. **Issue 搜索**：<https://github.com/zeek-zhao/devbox/issues>，用报错原文里
   最独特的一小段（如 `manifest unknown`、`NO-RUNNER`）做关键词；
3. **上游文档**：语言与工具的权威口径不在本仓——cppreference（标准库）、
   GCC/Clang 官方手册（编译器开关）、CMake 官方手册（构建系统），
   检索时带上 `images/versions.env` 对应变量的主版本号；
4. **本轨道五篇互查**：学怎么用 → [实践指南.md](实践指南.md)，
   从零上手 → [开发指南.md](开发指南.md)，
   卡在故障 → [问题指南.md](问题指南.md)，查参数 → [工具指南.md](工具指南.md)。
