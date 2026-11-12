# L3-014-custom-signal-ipc

## 考点
对应 KP-SH-L3-14：USR1/USR2 作为自定义 IPC 通道，trap 计数 + 就绪标记 + 轮询确认实现可靠握手。

## 易错点
连发三条标准信号会被内核合并成一次投递，计数必须「发一条、确认一条」；worker 没有就绪标记会丢早期信号。

## 延伸
把信号协议接入部署：reload=USR1、dump=USR2，发布脚本按协议发信号并确认生效。

## 复现
TAG=latest scripts/run-example.sh shell L3-014-custom-signal-ipc
