# L2-013-build-script

## 考点
对应 KP-RS-L2-13：build.rs 环境变量与重跑指令。build.rs 发布的环境变量在编译时可读，且 rerun-if-changed 明确声明触发文件

## 易错点
在 `build.rs` 打印环境变量后用 `std::env::var` 运行时读取，会把编译期配置和程序运行环境混为一谈。用 `cargo:rustc-env` 导出的值通过 `env!` 编译进 crate；输入文件变化时还要用 `rerun-if-changed` 声明触发条件，避免构建缓存漏掉更新。

## 延伸
`rust/project/build.rs` 导出 `DEVBOX_BUILD_MARKER` 并声明自身变化时重跑，`src/lib.rs` 的 `build_script_exports_compile_time_configuration` 用 `env!` 验证该值。该标记让构建脚本提供的设置在编译时可用，而不是依赖运行命令时再配置环境。

## 复现
TAG=latest scripts/run-example.sh rust L2-013-build-script
