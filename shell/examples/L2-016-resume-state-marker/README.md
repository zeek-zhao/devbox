# L2-016-resume-state-marker

## 考点
对应 KP-SH-L2-16：批处理用状态文件记录已完成的条目，中断后重跑只处理剩余部分。

## 易错点
不落状态的重跑会重复执行已完成条目，副作用型步骤会翻倍；先读标记再决定从哪续跑。

## 延伸
把断点续跑接入部署：步骤化安装器每步提交后写标记，失败重进不重复安装。

## 复现
TAG=latest scripts/run-example.sh shell L2-016-resume-state-marker
