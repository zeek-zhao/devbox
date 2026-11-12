# L2-020-log-rotation-size

## 考点
对应 KP-SH-L2-20：日志按大小阈值轮转，历史按 .1/.2 顺移并封顶保留份数，当前日志清零重开。

## 易错点
只重命名不封顶会让 .1/.2/.3… 无限累积占满磁盘；顺移链条上要淘汰超出保留份数的最旧文件。

## 延伸
接入部署巡检：轮转阈值可配，历史日志压缩归档并按保留天数清理。

## 复现
TAG=latest scripts/run-example.sh shell L2-020-log-rotation-size
