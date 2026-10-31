# L1-034-sorting-determinism

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-34，map 的键先收集再用 sort.Strings 排序，之后才统一输出键和值。
重复遍历并排序得到相同序列，且键按字典序出现，即可验证确定性输出已掌握。

## 易错点
Go map 的迭代顺序不保证，直接打印迭代结果会让断言随运行波动。
先收集键并排序，再按排序后的键访问和输出 map 内容。

## 延伸
在索引摘要或测试诊断中对 map 键排序，保证日志和快照可重复。
需要其他比较规则时，定义明确的排序键或使用 sort.Slice。

## 复现
TAG=latest scripts/run-example.sh go L1-034-sorting-determinism
