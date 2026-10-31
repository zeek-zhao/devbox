# L1-032-redirections


## 考点
对应 KP-SH-L1-32：按顺序应用文件描述符重定向，分别观察 stdout 与 stderr 的去向。
`>file 2>&1` 将两路写入文件，而 `2>&1 >file` 让 stderr 保留原 stdout 目标，说明掌握求值顺序。

## 易错点
`>file 2>&1` 与 `2>&1 >file` 顺序不同；按重定向求值顺序安排目标。
先复制当前 stdout 到 stderr 再改变 stdout，会令 stderr 不随后的文件重定向改变。

## 延伸
结合 `2>`, `>>` 和输入重定向构造稳定的命令日志与报告文件。
为需要分别保存诊断和业务输出的脚本设计清晰的文件描述符布局。

## 复现
TAG=latest scripts/run-example.sh shell L1-032-redirections
