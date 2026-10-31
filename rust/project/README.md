# Rust 跨平台 CLI 工具

仅用 Rust 标准库实现 `count`（词频）、`dupe`（重复行）和固定工作量 `bench`，支持目录递归、并行分片、稳定错误处理及确定性 `--self-check`。

目录结构：`src/` 为库与 CLI 实现，`tests/` 为集成测试，`examples/` 为 Cargo 示例，`build/` 保存可交付二进制，`COVERAGE.md` 追踪全部 Rust 示例用例。

从仓库根目录执行以下三条命令：

```bash
bash rust/project/build.sh
rust/project/build/devbox-rust-project count --threads=4 /path/to/text
bash rust/project/check-runtime.sh
```

`count` 和 `dupe` 支持文件或目录路径；省略路径时扫描当前目录。`--threads=N` 与 `--threads N` 均可用；`bench` 只输出固定操作次数。构建脚本使用离线 Cargo，并执行格式、Clippy 与测试检查。
