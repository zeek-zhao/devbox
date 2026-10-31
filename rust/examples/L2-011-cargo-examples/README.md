# L2-011-cargo-examples


## 考点
对应 KP-RS-L2-11：将独立可执行示例放在 crate 根目录的 `examples/`。
看到 `cargo run --example public-api --offline` 通过公开函数输出固定查询，说明示例可独立构建。

## 易错点
会让示例依赖未公开实现或隐式构建状态而失败；仅从公开接口调用并用独立命令验收。
Cargo 的 `examples/` 属于 crate 根目录，不是外层课程用例目录的子目录。

## 延伸
为查询和索引 API 各编写自包含示例，并验证它们只依赖公开接口。
把示例命令加入离线 CI，确保文档化用法不会随 API 变化而失效。

## 复现
TAG=latest scripts/run-example.sh rust L2-011-cargo-examples
