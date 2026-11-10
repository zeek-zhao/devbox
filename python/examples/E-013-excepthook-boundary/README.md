# E-013-excepthook-boundary —— 未捕获异常的兜底边界

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-013 未捕获异常的兜底边界），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

后台线程里的异常没人接：默认行为只往 stderr 打一行 `Exception in thread`，
主流程毫无感知，任务静默失败；反过来在兜底钩子里再抛异常、或把钩子写成
吞错，又会把「最后一次看到真相的机会」弄丢。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-013-excepthook-boundary
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-013-excepthook-boundary \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：工作线程漏抛的 ZeroDivisionError 被
`threading.excepthook` 捕获并记录一行（异常类型 + 消息），进程按约定
继续运行，末行固定输出边界结论。

## 为什么这样处理

- `threading.excepthook`（Python 3.8+）是线程级未捕获异常的统一兜底点：
  在这里记录类型、消息与线程名，保证「漏网异常」至少有一行结构化痕迹；
  主线程的对应机制是 `sys.excepthook`（主线程异常到达顶层后进程退出）。
- 兜底钩子只记录不抛：钩子内再抛异常会二次进入钩子甚至死循环；
  记录之后交给上层决定退出策略（对照 E-008 的退出码协议）。
- 与业务处理（按类型分流、重试）严格分层：excepthook 只管「没人接的
  异常」，不越权吞掉业务该处理的错误。

## 反例

- `try: worker.join() except: pass`：以为 join 能接住线程异常——
  接不住，异常早已在子线程终点被默认钩子消费。
- 兜底钩子里 `raise` 或再打日志失败不设防：兜底路径自己崩溃，
  现场比没有兜底更难查。
- 只给个别线程手工传 try/except 包装：新增线程漏包，兜底覆盖不完整；
  统一钩子才是「一处配置、全量覆盖」。
