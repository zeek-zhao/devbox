# L1-019-iterator-adaptors

<!-- coverage: pending -->

## 考点
对应 KP-RS-L1-19：串接 `map`、`filter`、`fold` 与 `collect` 完成转换、筛选、归并和收集。
看到固定输入得到精确的筛选序列与归并值，说明适配器的输入输出类型衔接正确。

## 易错点
会在 `filter` 中返回转换后的值而非布尔条件，或误用 `fold` 初始值类型；按每个适配器的输入输出类型检查链条。
先明确 `map` 的元素类型，再保证 `filter` 谓词返回布尔值，最后选择与归并结果相容的初始值。

## 延伸
用倒排表筛选匹配文档编号，再通过 `fold` 汇总命中计数。
练习将适配器链拆开检查每一步的元素类型与结果类型。

## 复现
TAG=latest scripts/run-example.sh rust L1-019-iterator-adaptors
