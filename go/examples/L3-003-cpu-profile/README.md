# L3-003-cpu-profile


## 考点
对应 KP-GO-L3-03：用 `runtime/pprof` 采集受控 CPU 工作负载并验证 profile 可解析。
输出 `profile-samples: present` 表示停止采样后，pprof 能解析到目标 workload 的样本。
工作负载运行超过 300ms，避免短采样窗口产生空 profile。

## 易错点
未调用 StopCPUProfile 就读取会留下不完整数据；用 defer 确保停止采样并将文件写入临时目录。
profile 必须等进程停止采样并关闭文件后再解析；仅检查文件非空不能证明有样本。

## 延伸
用 `go tool pprof` 比较切词与倒排构建的 CPU 热点，再据热点优化并复测。
学习 heap profile 与 goroutine profile，区分 CPU 消耗和内存占用问题。

## 复现
TAG=latest scripts/run-example.sh go L3-003-cpu-profile
