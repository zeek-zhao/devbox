# L1-021-optional-fallback

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-21：用 map/flatMap 组合 Optional，并为缺失值提供默认分支。
看到空值安全地得到固定默认值、orElse 提前计算而 orElseGet 不计算，即说明掌握。

## 易错点
默认值可能被无谓计算，因为 orElse 的参数会先求值；昂贵默认值应改用 orElseGet。
不要先盲目 get；先用组合操作表达存在与缺失两条路径。

## 延伸
把 Optional 用在未命中查询结果上，练习把查询结果转换为明确的领域默认值。
比较 map 与 flatMap 在转换函数本身也返回 Optional 时的差异。

## 复现
TAG=latest scripts/run-example.sh java L1-021-optional-fallback
