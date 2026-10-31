# L3-004-profiling-benchmarks

<!-- coverage: pending -->

## 考点
对应 KP-L3-04：对固定工作负载做实际计时，同时用稳定的迭代和比较计数验收。
看到固定操作数与 `benchmark: measured`，说明执行了基准而没有把墙钟时间当作期望值。

## 易错点
单次计时受预热、缓存和调度影响；不输出耗时，只报告确定的操作计数。
只凭代码推测性能不能证明测量发生；用 steady clock 包住工作负载并消费计算结果。

## 延伸
将固定工作负载重复多轮，报告中位数与离散程度，但不要把计时作为跨机器门槛。
结合 perf 采样与热点分析，验证优化前后是否减少了实际瓶颈。

## 复现
TAG=latest scripts/run-example.sh cpp L3-004-profiling-benchmarks
