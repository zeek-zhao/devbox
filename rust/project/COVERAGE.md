# Rust 毕业项目：用例覆盖表

项目目标：跨平台 CLI 工具（clap 解析 → 并发扫描 → FFI 调 C 库 → criterion 基准）。
阶段 0 只有 hello 用例。

| 用例ID | 落点 | 说明 |
|---|---|---|
| hello | src/main.rs:3 | 工具链版本与所有权基础验证 |
