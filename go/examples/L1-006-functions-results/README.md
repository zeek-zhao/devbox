# L1-006-functions-results

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-06：函数返回业务值与 error，调用方分别接收并检查。
成功输入取得解析值、失败输入被明确拒绝，说明掌握多返回值约定。

## 易错点
忽略第二个 error 返回值会漏掉解析失败，业务值此时不可直接信任。
先判断 error，再使用对应的业务值。

## 延伸
将解析函数用于文本输入，并由调用方决定错误如何反馈。
练习包装错误上下文，同时保留可检查的错误结果。

## 复现
TAG=latest scripts/run-example.sh go L1-006-functions-results
