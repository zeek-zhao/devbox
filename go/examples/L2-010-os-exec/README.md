# L2-010-os-exec


## 考点
对应 KP-GO-L2-10：通过 os/exec 以可执行文件和参数启动子进程。
看到精确的子进程 stdout、stderr 及被识别的退出码 7，说明输出和退出错误均已处理。
参数作为独立参数传递，不需要 shell 拼接命令。

## 易错点
把整条命令交给 shell 会引入转义和注入问题，也让参数边界不清晰。
直接传可执行文件及参数，并显式检查非零退出对应的错误类型和退出码。

## 延伸
用 `exec.CommandContext` 增加取消与超时控制，并检查进程被取消时的错误。
用 `Stdin`、`Stdout` 和 `Stderr` 管道支持流式处理较大的子进程输出。

## 复现
TAG=latest scripts/run-example.sh go L2-010-os-exec
