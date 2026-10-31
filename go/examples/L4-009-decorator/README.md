# L4-009-decorator

<!-- coverage: pending -->

## 考点

对应 KP-GO-L4-09：用包装对象在运行时叠加职责，替代为每种组合派生一个子类。

可观察判据：装饰器接收并返回同一接口，两层包装后输出固定拼接文本。

## 为什么这样写

结构位置：`main.go:5-30` 为共同接口、原对象与两个包装实现，`main.go:32-38` 为两层包装及顺序对照。

`main.go` 的 `PlainText`、`Brackets`、`Prefix` 都实现 `Text.Content()`；包装结构体持有 `inner Text`，构造函数也接收并返回 `Text`。
两个装饰器的 `Content()` 都调用被包装对象，而不是直接打印预设结果；`main()` 实际执行两层嵌套及反向嵌套，并保留原对象。
如果 `Prefix` 不调用 `inner.Content()`，第二行 `cached:[go]` 会丢失内层文本；若删除 `Brackets` 包装，两行中的方括号会消失。
第三行验证顺序会影响职责组合，不是一个写死格式的函数；第一行验证包装没有修改原始内容。

## 怎么跑

TAG=latest bash scripts/run-example.sh go L4-009-decorator
