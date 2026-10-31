# L1-026-range-semantics

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-26：range 遍历 slice、数组、字符串与 map，区分索引、键和值。
看到修改值副本后 slice 仍为 [10 20]，按索引修改后成为 [11 21]，即掌握元素更新方式。
数组输出索引和值，字符串输出字节索引与 rune，map 收集键后按排序结果展示。

## 易错点
range 的值通常是元素副本，修改该变量不会写回原 slice；需要更新时用索引赋值。
map 顺序不稳定，直接输出遍历结果会使验收波动；本例先收集并排序键再输出。

## 延伸
在文档与倒排表扫描中区分只读值遍历与按索引更新。
为带字段的元素补充副本修改与索引修改对照，断言原集合是否改变。

## 复现
TAG=latest scripts/run-example.sh go L1-026-range-semantics
