# L3-003-cprofile

<!-- coverage: pending -->

## 考点
对应 KP-PY-L3-03：从 `cProfile` 统计中提取目标函数调用信息。
输出只含稳定的函数名和调用次数且按名称排序，说明掌握了该 KP。

## 易错点
完整统计会包含耗时和文件路径，直接打印会产生不稳定输出。
从 stats 中取函数名和调用次数后排序，不输出计时字段。

## 延伸
对报表转换函数集合逐个剖析并聚合调用次数。
结合热点采样结果决定是否值得优化，再用固定输入回归验证。

## 复现
TAG=latest scripts/run-example.sh python L3-003-cprofile
