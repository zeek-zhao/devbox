# L1-003-equality-contract

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-03：相等对象必须有相同的 `hashCode`，集合键参与比较的字段应稳定。
固定散列值不同的相等键查找失败，而成对实现契约的键可去重并查到，即掌握此 KP。

## 易错点
相等键会查不到，因为不一致的 `hashCode` 会把它们分到不同桶。
成对重写 `equals` 与 `hashCode`，且不修改入集合后的键字段；坏例使用明确不同的固定散列值。

## 延伸
检查哈希键所依赖字段的生命周期，并比较不可变键与可变键的集合行为。
将此契约应用到文档键去重和基于键的索引查找。

## 复现
TAG=latest scripts/run-example.sh java L1-003-equality-contract
