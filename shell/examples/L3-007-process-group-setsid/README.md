# L3-007-process-group-setsid

## 考点
对应 KP-SH-L3-07：setsid 把子进程放进独立会话/进程组，kill -- -PGID 能一次终止整组（含孙进程）。

## 易错点
只 kill 直接子进程会漏掉它派生的孙进程，端口和临时文件被残留占用；对组取负 PID 发信号才能整组回收。

## 延伸
把进程组管理接入部署守护：重启时按组终止旧实例，避免新旧实例并存。

## 复现
TAG=latest scripts/run-example.sh shell L3-007-process-group-setsid
