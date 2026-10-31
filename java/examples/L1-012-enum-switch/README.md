# L1-012-enum-switch

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-12：enum 可封装显式状态码，switch 表达式可用 `yield` 返回分支值。
看到固定状态码和 switch 生成的状态描述，即可确认状态数据与分支结果均可观察。

## 易错点
持久化状态码会随排序变化，因为 ordinal 取声明顺序；定义显式字段，不用 ordinal 作磁盘协议。
状态码需稳定时读取显式字段，不能把枚举声明位置当作外部数据格式。

## 延伸
把显式状态码映射到请求/索引状态，并为未知外部状态定义明确处理策略。
扩展 switch 表达式的块分支，比较直接分支与 `yield` 的适用场景。

## 复现
TAG=latest scripts/run-example.sh java L1-012-enum-switch
