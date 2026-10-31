# L2-005-doctests

<!-- coverage: pending -->

## 考点
对应 KP-RS-L2-05：让公开 API 的文档示例由 `cargo test --doc` 编译运行。
看到自包含示例通过、`compile_fail` 示例按预期拒绝编译，说明 doctest 契约成立。

## 易错点
依赖未声明变量或隐式上下文会使文档示例无法独立编译。
让每段示例自包含，并用 `compile_fail` 标记预期无法编译的代码。

## 延伸
给库的解析与查询 API 补充可复制执行的文档示例。
用多个独立代码块说明成功输入与预期编译失败的类型约束。

## 复现
TAG=latest scripts/run-example.sh rust L2-005-doctests
