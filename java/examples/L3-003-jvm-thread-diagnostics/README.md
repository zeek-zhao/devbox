# L3-003-jvm-thread-diagnostics

<!-- coverage: pending -->

## 考点
对应 KP-JV-L3-03：握手后用 jcmd Thread.print 定位自有工作线程的阻塞帧。
worker 确认进入 parkHere 等待后，诊断结果同时找到 WAITING 状态与该关键帧，说明栈采样有效。

## 易错点
抢在阻塞前抓栈会漏帧；原始输出含 PID、地址等动态字段，不能直接写入 expected。
握手后有界采样，只输出布尔结论；失败时把原始诊断保留到 stderr，不依赖堆地址。

## 延伸
把 parkHere 替换为索引任务的等待点，练习从线程栈映射回业务阻塞位置。
将 jstack、jmap 与 jps 留作本地辅助，不让用例依赖其动态输出。

## 复现
TAG=latest scripts/run-example.sh java L3-003-jvm-thread-diagnostics
