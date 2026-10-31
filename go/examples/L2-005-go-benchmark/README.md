# L2-005-go-benchmark


## 考点
对应 KP-GO-L2-05：编写 Benchmark 开头的函数，并通过 go test -bench 执行。
看到 BenchmarkTokenize 条目出现，且基准循环按 b.N 次执行，说明基准已运行；不比较不稳定的 ns/op。

## 易错点
把初始化成本误计入循环会扭曲结果。
将一次性准备放在计时区外并用 b.ResetTimer，让计时只覆盖被测操作。

## 延伸
用不同输入规模运行同一切词基准，观察输入增长对每次操作耗时的影响。
进一步用 benchstat 比较多次基准结果，而不是从单次 ns/op 下结论。

## 复现
TAG=latest scripts/run-example.sh go L2-005-go-benchmark
