# L2-013-log-level-filtering

## 考点
对应 KP-SH-L2-13：日志按级别分级，运行时可按阈值过滤，低于阈值的行不产生输出。

## 易错点
在每条输出处散落 if 判断会让阈值散布各处；用统一的分级函数集中决定可见性，阈值取自环境变量一处配置。

## 延伸
把分级日志接入部署工具：巡检跑 info，排障临时切 debug，无需改代码。

## 复现
TAG=latest scripts/run-example.sh shell L2-013-log-level-filtering
