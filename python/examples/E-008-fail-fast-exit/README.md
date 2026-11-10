# E-008-fail-fast-exit —— 快速失败与退出码协议

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-008 快速失败与退出码协议），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

CLI 脚本对非法输入既不报错也不区分原因：用法错误、数据错误、内部错误
统统以退出码 0 收场（或全部 1），调用方（脚本、CI、调度器）无法按退出码
分流，只能去解析 stdout 猜——错误协议缺位让失败变得不可编程消费。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-008-fail-fast-exit
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-008-fail-fast-exit \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：协议行固定声明 usage=2 / data=1 / success=0；
非法参数在入口即刻以 exit=2 拒绝，超限数据以 exit=1 拒绝，合法输入
走成功路径 exit=0（本例用 try 捕获 `SystemExit` 展示映射，进程实际退出 0）。
错误详情进 stderr，stdout 只留可断言的协议行。

## 为什么这样处理

- 退出码是进程对外的错误协议：惯例 0 成功、1 数据/业务失败、2 用法错误，
  让上层不解析文本就能分流（重试/告警/人工介入）。
- 快速失败发生在边界（参数解析、入口校验），错误消息进 stderr——
  与正常输出分离，管道消费者不会被污染。
- `SystemExit(code)` 是标准库的进程级退出语义：从任意深处抛出都能
  依约退出，避免「校验失败后继续跑半页日志再炸」的拖泥带水。

## 反例

- 校验失败后 `print("invalid")` 然后继续执行：错误被当提示，后续逻辑在
  坏输入上跑出更大的错。
- 所有错误一律 `sys.exit(1)`：调用方无法区分「该修命令」还是「该修数据」。
- 把错误详情打进 stdout：管道消费方拿到的是混合流，`2>err.log` 失效。
