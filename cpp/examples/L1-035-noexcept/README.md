# L1-035-noexcept

<!-- coverage: pending -->

## 考点
对应 KP-L1-35：用类型特征和 `noexcept(expr)` 验证移动构造及调用表达式的不抛承诺。
看到安全移动构造与 `noexcept` 函数表达式为真、可能抛出的函数表达式为假，即可说明会判断异常契约。

## 易错点
`noexcept` 表达式检查的是异常契约，不会执行其中的函数；不能据此推断运行时一定成功。
异常逃出 `noexcept` 函数会调用 `std::terminate`；确保异常路径被处理，不要实际越过该边界。

## 延伸
可比较容器面对不抛移动构造与可能抛移动构造时的元素搬迁策略。
还可为资源释放操作设计不抛异常的接口，并检查其类型特征。

## 复现
TAG=latest scripts/run-example.sh cpp L1-035-noexcept
