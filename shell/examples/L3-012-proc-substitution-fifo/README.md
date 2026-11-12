# L3-012-proc-substitution-fifo

## 考点
对应 KP-SH-L3-12：diff <(cmd) 用进程替换喂动态数据；mkfifo + 后台写者实现跨进程的单次交接。

## 易错点
进程替换要求 Bash 且路径只在当次命令有效；FIFO 不清理会卡住下一个读者，写者必须有人消费。

## 延伸
把两种手法接入部署：配置对比用进程替换，多阶段流水线交接用 FIFO。

## 复现
TAG=latest scripts/run-example.sh shell L3-012-proc-substitution-fifo
