# L2-003-unit-tests

<!-- coverage: pending -->

## 考点
对应 KP-RS-L2-03：由 `cargo test` 启动单元测试，并用 `#[should_panic]` 标记预期 panic。
看到普通断言和限定消息的预期 panic 测试都通过，说明测试框架按预期执行。

## 易错点
过宽的 `should_panic` 会把意外 panic 也当通过，普通二进制运行也不会自动执行测试。
用 `cargo test` 启动测试，并用 `expected` 收窄预期 panic 消息。

## 延伸
为索引边界增加正常输入与非法输入测试。
将同一行为的测试放入集成测试，比较测试模块的可见性边界。

## 复现
TAG=latest scripts/run-example.sh rust L2-003-unit-tests
