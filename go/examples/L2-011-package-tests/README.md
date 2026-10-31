# L2-011-package-tests

<!-- coverage: pending -->

## 考点
对应 KP-GO-L2-11：按目录组织模块包，并从模块根运行 `go test ./...`。
看到 lib 和 store 的测试整体通过、模块外部对 internal 包的导入被拒绝，说明两条边界均生效。

## 易错点
只测试当前包会漏掉其他包回归；从模块根运行 `go test ./...` 才覆盖全部包。
internal 的可见性按模块树根限制；用第二个模块验证外部导入确实会被拒绝。

## 延伸
把存储接口与实现拆成独立包，并让调用方通过接口而非内部实现依赖存储。
为跨包操作增加集成测试，验证包组合后的行为和错误传播。

## 复现
TAG=latest scripts/run-example.sh go L2-011-package-tests
