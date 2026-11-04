---
track: rust
guide: G5
dimensions: [D2, D5, D8]
level: P1
status: draft
links: [开发指南.md, 工具指南.md, 知识点清单.md]
examples: [L0-hello, L2-003-unit-tests, L3-006-atomics-ordering]
---

# Rust FAQ（G5）

> 一问一答，先结论、再一步命令、最后给「详见」。每条 50–200 字。
> G3 问题指南（按问题域的长排查）本轨道尚未建（M8 补齐），本篇先承接高频短问。

## 环境与镜像

### Q: devbox-rust 的工具链是什么版本？想换 channel 去哪改？

A: 版本只有一份真本：`images/versions.env` 的 `${RUST_TOOLCHAIN}`（rustup 安装，
minimal profile + clippy/rustfmt 组件），文档禁止写字面量。换 stable/固定版本：
改 versions.env → 发版流程重建镜像。详见 [工具指南](工具指南.md) §1 / T0 §6。

### Q: 宿主机没装 Rust，怎么编译 / 格式化 / 测试？

A: 全部走容器：格式化 `bash scripts/fmt.sh --lang rust`；lint+测试+构建一条龙
`bash rust/project/build.sh`（宿主无 cargo 时自动落容器，前提镜像已在本地）。
详见 [开发指南](开发指南.md) §4 / [工具指南](工具指南.md) §2.1。

### Q: rust-analyzer 命令明明能找到，一跑就报 Unknown binary？

A: 那是 rustup 的代理链接，minimal profile 没装组件。先
`rustup component list --installed` 确认，需要 LSP 就在容器内
`rustup component add rust-analyzer`。miri 同理（对 stable 不可用）。
详见 [工具指南](工具指南.md) §2.5。

### Q: 怎么进容器里手动排查？

A: `docker run --rm -it "ghcr.io/zeek-zhao/devbox-rust:${TAG:-latest}" bash`；
跑用例想留现场就给 runner 加 `--keep` 再 `docker exec` 进去。
详见 [开发指南](开发指南.md) §1、§3。

## 构建与测试

### Q: 怎么跑单个教学用例？

A: 仓库根执行 `TAG=latest scripts/run-example.sh rust <ID>`，例如
`TAG=latest scripts/run-example.sh rust L0-hello`（实测 PASS）；
列清单 `scripts/run-example.sh rust --list`。ID 全表见 [知识点清单](知识点清单.md)。
详见 [开发指南](开发指南.md) §3。

### Q: 离线构建报「找不到依赖」？

A: `--offline` 只认 Cargo.lock + 本地 registry 缓存。新增依赖先联网
`cargo fetch` 更新 lock 并随代码提交，再离线构建。练习见 L2-009-offline-build。
详见 [工具指南](工具指南.md) §4。

### Q: 单元测试、集成测试、doctest 分别放哪？

A: 单元测试在 src 内 `#[cfg(test)]` 模块（L2-003-unit-tests），集成测试在
`tests/` 目录（L2-004-integration-tests），文档注释里的代码块由
`cargo test --all-features` 一并执行（L2-005-doctests）。一条命令全跑：
`cargo test --offline --all-targets --all-features`。详见 [开发指南](开发指南.md) §4。

### Q: runner 说「期望输出不匹配」，怎么对现场？

A: 期望值就是用例目录里的 `expected.txt`（逐行精确、忽略行尾空白）。加 `--keep`
保留容器，`docker exec` 进去手动跑 `run.sh` 逐行 diff。
详见 [开发指南](开发指南.md) §3 / T0 §1。

## lint 与调试

### Q: clippy 警告会不会挡合并？

A: 会。`build.sh` 门禁是 `cargo clippy --offline --all-targets -- -D warnings`，
一个警告就是红灯。就地 `#[allow(clippy::lint名)]` + 注释理由是唯一豁免方式。
练习见 L2-008-clippy-warnings。详见 [工具指南](工具指南.md) §2.3。

### Q: Rust 程序在容器里怎么断点调试？

A: 镜像预装 gdb、lldb 及 rust 包装器：`rust-gdb ./target/debug/app`（默认推荐），
包装器自动加载 pretty-printer。详见 [工具指南](工具指南.md) §2.4。

### Q: 原子操作 / unsafe 的行为怎么验证？

A: 原子序语义练 L3-006-atomics-ordering，裸指针练 L3-007-unsafe-raw-pointer；
想解释执行查 UB 可加装 miri 组件（stable 工具链不可用，需按 §2.5 处理）。
详见 [工具指南](工具指南.md) §2.5。

## 文档与流程

### Q: 文档里能写具体版本号吗？

A: 不能。一律写 `images/versions.env` 的变量名（如 `${RUST_TOOLCHAIN}`）：写字面量，
升级当天文档集体过期。镜像 tag 同理，命令统一
`TAG=latest scripts/run-example.sh ...`。详见 T0 §6 / [开发指南](开发指南.md) §1。

### Q: 提交被拒：身份不允许 / AI 署名？

A: author 和 committer 都必须在白名单（当前 `zeek.zhao <zeek.zhao@foxmail.com>`），
且提交信息禁止 `Co-authored-by:` / `Generated with` 尾巴。先
`git config user.name zeek.zhao && git config user.email zeek.zhao@foxmail.com`。
详见 T0 §5。

### Q: 格式化 CI 红了但我本地「已经是格式好的」？

A: 多半是绕过了统一入口导致口径漂移。宿主用
`bash scripts/fmt.sh --check --lang rust`（与 CI 同命令、同镜像）复查，差异会列文件；
规则真本是仓库根 `rustfmt.toml`，改它属门禁变更。fmt 门禁语义见 L2-007-fmt-check。
详见 [工具指南](工具指南.md) §2.2。

## 查不到时去哪查

- **练什么 / 用例 ID**：`rust/docs/知识点清单.md`（L1–L3 各级表格）。
- **工具怎么调 / 是否预装**：[工具指南](工具指南.md)；排查类长问题等 Rust 轨道
  G3 问题指南（M8 建成）承接，先按工具指南 §2 的定位命令走。
- **runner / CI / 门禁 / 提交 / 发版**：`docs/13-通用开发指南.md`（T0 单一真本）。
- **已知坑登记**：`docs/ROADMAP.md` 的 KI 段、`docs/40-问题清单.md`。
- **上游文档**：镜像内 `rustup doc`、`cargo doc --open`（同 `${RUST_TOOLCHAIN}`
  版本，最可靠口径）；再查不到带 `--keep` 现场去 GitHub issue 搜索 / 提 issue。
