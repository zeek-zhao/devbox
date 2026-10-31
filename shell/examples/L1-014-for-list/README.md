# L1-014-for-list


## 考点
对应 KP-SH-L1-14：`for` 循环逐个遍历显式列表中的元素。
看到 `"one two"` 保持为一个完整元素而 `three` 是另一个元素，说明掌握了列表边界。

## 易错点
`for item in $value` 会发生拆词和路径名展开，元素边界可能丢失。
使用明确列表；遍历数组时用 `"${array[@]}"` 保留每个元素。

## 延伸
将显式列表用于逐一处理固定目标或子命令参数。
需要动态目标集合时改用数组并保持每个元素的引用。

## 复现
TAG=latest scripts/run-example.sh shell L1-014-for-list
