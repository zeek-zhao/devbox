# L3-008-repr-c-layout

## 考点
对应 KP-RS-L3-08：repr(C)、repr(transparent) 与字段布局。size_of 和 offset_of 显示 C 布局填充以及 transparent 包装的底层尺寸

## 易错点
假设 Rust 默认字段布局固定，或把 `repr(C)` 当成“字段之间没有填充”，都会算错偏移和结构体大小。只有需要与 C ABI 对接时才用 `repr(C)` 并核对目标平台布局；`repr(transparent)` 只适用于单个非零大小字段及其零大小附属字段的包装类型。

## 延伸
项目的 `rust/project/src/lib.rs` 没有 C ABI 接口或外部二进制布局承诺，`repr(C)` 和 `repr(transparent)` 只出现在布局示例测试中。跨平台 CLI 的内部数据不需要固定 C 布局，本例只作 FFI 布局能力练习。

## 复现
TAG=latest scripts/run-example.sh rust L3-008-repr-c-layout
