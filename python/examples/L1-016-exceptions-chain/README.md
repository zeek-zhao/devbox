# L1-016-exceptions-chain

<!-- coverage: pending -->

## 考点
对应 KP-PY-L1-16：将底层异常转换为领域异常时保留显式原因，并确认 `finally` 执行。
外层捕获到领域异常、`__cause__` 是 `ValueError`，且 finally 记录先出现，即说明掌握。

## 易错点
直接抛出新异常会丢失明确因果关系，过宽捕获还可能吞掉不可处理错误。
只捕获可处理的 `ValueError`，并用 `raise ... from err` 保留原始失败原因。

## 延伸
为输入格式解析定义领域异常，并在错误报告中展示稳定的原因类型。
为清理操作添加 `finally`，验证异常传播时仍按预期执行收尾。

## 复现
TAG=latest scripts/run-example.sh python L1-016-exceptions-chain
