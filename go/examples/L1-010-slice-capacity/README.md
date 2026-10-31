# L1-010-slice-capacity


## 考点
对应 KP-GO-L1-10：观察子 slice 的容量如何影响 append。
看到 `s[:n:n]` 追加后原 slice 尾部保持不变，说明掌握了容量边界。

## 易错点
`s[:n]` 仍保留原容量，append 可能覆盖底层数组尾部。
用 `s[:n:n]` 限制可写容量，或复制数据以隔离底层数组。

## 延伸
练习把查询结果切成批次，并确认追加一批不会改写相邻数据。
比较限制容量与复制隔离在所有权和分配上的差别。

## 复现
TAG=latest scripts/run-example.sh go L1-010-slice-capacity
