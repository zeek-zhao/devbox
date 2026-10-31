# Rust 毕业项目：用例覆盖表

本表覆盖 `rust/examples/` 下全部 51 个用例目录；每个 ID 均落在项目实际使用相应语言特性、Cargo 配置或验证行为的位置。

| 用例ID | 落点 | 说明 |
|---|---|---|
| hello | src/main.rs:1 | 标准库 CLI 入口与参数所有权传递 |
| L1-001-string-move | src/lib.rs:265 | 将拥有所有权的分片移动到 worker 闭包 |
| L1-002-copy-types | src/lib.rs:60 | Operation 派生 Copy 以便按值重复分派 |
| L1-003-shared-borrows | src/lib.rs:91 | 参数解析共享借用参数切片 |
| L1-004-mutable-borrows | src/lib.rs:275 | 通过可变 entry 引用累加词频 |
| L1-005-borrow-scope | src/lib.rs:514 | 局部借用结束后继续使用原字符串 |
| L1-006-return-lifetimes | src/lib.rs:85 | 返回与参数同生命周期的命令名切片 |
| L1-007-struct-lifetimes | src/lib.rs:79 | 参数视图结构显式关联输入生命周期 |
| L1-008-option-values | src/lib.rs:92 | 可选命令名使用 Option 表示 |
| L1-009-result-propagation | src/lib.rs:175 | 使用 `?` 传播递归遍历错误 |
| L1-010-custom-errors | src/lib.rs:21 | 定义自有 AppError 类型 |
| L1-011-data-enums | src/lib.rs:62 | Operation 用枚举表示子命令 |
| L1-012-exhaustive-match | src/lib.rs:94 | 对命令字符串进行显式匹配 |
| L1-013-pattern-bindings | src/lib.rs:101 | 匹配未知命令并绑定其名称 |
| L1-014-trait-implementations | src/lib.rs:45 | 为 AppError 实现标准 Error trait |
| L1-015-generic-bounds | src/lib.rs:172 | 通过 Write trait bound 泛化输出目标 |
| L1-016-trait-default-methods | src/lib.rs:334 | SectionWriter 默认方法输出章节标题 |
| L1-017-static-dynamic-dispatch | src/lib.rs:48 | 以动态 Error trait object 暴露底层错误来源 |
| L1-018-lazy-iterators | src/lib.rs:231 | 惰性取得下一词而不分配整组词 |
| L1-019-iterator-adaptors | src/lib.rs:179 | 用 map 将每行转换为拥有字符串 |
| L1-020-iterator-ownership | src/lib.rs:270 | 消费 worker 持有的分片行 |
| L1-021-custom-iterator | src/lib.rs:227 | Words 实现 Iterator::next |
| L1-022-closure-traits | src/lib.rs:206 | 排序闭包按路径逆序处理目录 |
| L1-023-move-closures | src/lib.rs:267 | move 闭包取得分片和发送端 |
| L1-024-box-ownership | src/lib.rs:23 | Box 拥有底层 I/O 错误 |
| L1-025-rc-refcell | src/lib.rs:440 | 测试 writer 以 Rc<RefCell> 共享缓冲区 |
| L1-026-arc-mutex | src/lib.rs:281 | worker 通过 Arc<Mutex> 同步已处理数 |
| L1-027-str-string | src/lib.rs:273 | 将借用词片转换为拥有的 String 键 |
| L1-028-utf8-chars-bytes | src/lib.rs:234 | 用 char_indices 在 UTF-8 边界扫描词语 |
| L1-029-string-slice-boundaries | src/lib.rs:461 | 通过 get 检查合法 UTF-8 切片边界 |
| L1-030-modules-visibility | src/lib.rs:216 | 用私有 words 模块封装迭代器 |
| L1-031-drop-order | src/lib.rs:541 | 验证局部值按声明逆序析构 |
| L1-032-slices-bounds | src/lib.rs:261 | 通过 chunks 安全分片输入 |
| L1-033-integer-overflow | src/lib.rs:297 | 合并统计时用 checked_add 检查溢出 |
| L2-001-cargo-lib-bin | Cargo.toml:15 | Cargo package 同时声明库和二进制目标 |
| L2-002-cargo-modules | src/lib.rs:213 | 将单词扫描实现收进独立模块 |
| L2-003-unit-tests | src/lib.rs:394 | crate 内单元测试覆盖解析与自检 |
| L2-004-integration-tests | tests/cli.rs:1 | 集成测试调用公开 CLI API |
| L2-005-doctests | src/lib.rs:1 | crate 文档代码块作为 doctest 执行 |
| L2-006-cargo-features | Cargo.toml:20 | strict-args feature 控制缺省路径行为 |
| L2-007-fmt-check | build.sh:9 | 构建入口检查 Rust 格式 |
| L2-008-clippy-warnings | build.sh:10 | 构建入口将 Clippy 警告视为错误 |
| L2-009-offline-build | build.sh:11 | Cargo 测试显式启用离线模式 |
| L2-010-cargo-workspace | Cargo.toml:7 | 声明单 package workspace 与 resolver |
| L2-011-cargo-examples | examples/word_count.rs:1 | 独立 Cargo 示例调用库接口 |
| L3-001-binary-format | src/lib.rs:496 | 小端序 u64 记录往返测试 |
| L3-002-zero-copy-parser | src/lib.rs:228 | Words 的迭代项直接借用输入字符串 |
| L3-003-scoped-thread-channel | src/lib.rs:258 | 作用域 worker 通过 mpsc 回传统计分片 |
| L3-004-c-abi-ffi | src/lib.rs:504 | 检查 C ABI 函数指针签名并调用 |
| L3-005-std-benchmark | src/lib.rs:362 | 用 Instant 计时固定基准工作量 |
| L3-006-atomics-ordering | src/lib.rs:363 | 用 AtomicUsize/Relaxed 统计操作次数 |
