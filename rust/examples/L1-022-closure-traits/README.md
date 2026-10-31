# L1-022-closure-traits

<!-- coverage: pending -->

## 考点
对应 KP-RS-L1-22：通过 `Fn`、`FnMut`、`FnOnce` 参数约束区分读取、修改、消费捕获值。
看到只读两次为 `[4, 4]`、修改累计为 `[1, 2]`、消费后返回拥有型字符串，说明调用方式匹配捕获动作。

## 易错点
把消费捕获值的闭包重复调用会编译失败，因为移出 `String` 的闭包只实现 `FnOnce`。
本例只将消费闭包传值调用一次，之后只使用返回值；依据捕获动作选择调用次数与参数约束。

## 延伸
在毕业项目中将只读查询谓词约束为 `Fn`，有累计统计的回调约束为 `FnMut`。
将一次性交出查询参数的回调约束为 `FnOnce`，明确结果的新所有者。

## 复现
TAG=latest scripts/run-example.sh rust L1-022-closure-traits
