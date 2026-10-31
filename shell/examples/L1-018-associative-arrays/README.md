# L1-018-associative-arrays

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-18：用 Bash 关联数组将字符串键映射到值。
看到 `api` 和 `worker` 分别查到对应状态，且键经排序后稳定输出，说明掌握了键值访问。

## 易错点
关联数组必须先用 `declare -A` 声明，并由 Bash 执行。
键的遍历顺序不稳定；需要稳定输出时先收集并排序键。

## 延伸
用关联数组维护服务名到状态的映射，并显式处理不存在的键。
将键排序后输出映射内容，构造可重复的巡检摘要。

## 复现
TAG=latest scripts/run-example.sh shell L1-018-associative-arrays
