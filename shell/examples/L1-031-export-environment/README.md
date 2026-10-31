# L1-031-export-environment


## 考点
对应 KP-SH-L1-31：区分当前 Shell 变量与导出给子进程的环境变量。
子进程看不到未导出的值、执行 `export` 后读到完整值，说明掌握环境传递。

## 易错点
Shell 变量默认不会传给外部命令；需让子进程读取时显式 `export`。
在调用外部程序前导出所需配置，避免子进程拿不到当前 Shell 中已有的值。

## 延伸
练习在单条命令前设置环境变量，与持久导出变量的作用范围差异。
为子命令整理明确的环境配置，避免依赖调用者 Shell 中偶然存在的变量。

## 复现
TAG=latest scripts/run-example.sh shell L1-031-export-environment
