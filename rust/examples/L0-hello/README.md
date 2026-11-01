## 考点
用 `rustc` 独立编译 `hello.rs`，验证 Rust 编译器、标准库区间迭代与 `String` 字符计数。
生成的可执行文件写入 `/tmp/devbox-hello-rust` 并运行，无 Cargo 工程或第三方 crate。

## 运行
在仓库根目录执行：`TAG=latest scripts/run-example.sh rust hello`。

## 易错点
这是直接调用 `rustc` 的单文件用例，不需要 `cargo`；不要误改成依赖 crates.io 的构建流程。
编译需要 Rust 工具链在镜像中可用，且可写入临时目录。
