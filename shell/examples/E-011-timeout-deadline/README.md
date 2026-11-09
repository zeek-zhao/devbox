# E-011-timeout-deadline —— 超时与截止时间

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-011 超时与截止时间），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

脚本调用一个会挂起的外部命令（网络卡住、对端不响应、等一个永远不来的锁），
没有截止时间——整个部署流水线挂在一步上不退不出；或者挂起最终被外层杀掉，
但退出码是杀进程工具自己的 124，上层完全不知道发生了什么类别的事。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-011-timeout-deadline
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-011-timeout-deadline \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：按时完成的任务 rc=0；挂起任务在 1s 截止处被杀
（timeout 的 124 被翻译成脚本自己的超时类别 rc=3）。

## 为什么这样处理

- `timeout 1s "$@"` 给每次外部调用兜底：挂起变成有限时间的失败，
  流水线不会被单步拖死。
- 124 是工具的语义，不是脚本的：边界函数 `classify_timeout` 把它翻译成
  自己的 CODE_TIMEOUT=3，上层按类别处理（可重试/上报），不解析工具细节
  （与 E-009 的边界翻译同一纪律）。
- 截止时间写死在调用点可见处：多久算「太久」是调用方的决定，不藏在深处。

## 反例

- 裸调 `sleep 5`、裸调网络命令：一个挂起调用拖垮整个流水线。
- 只判非零不分类：124 和真正的业务失败混为一谈，重试逻辑无从下手。
- 截止时间过长（如 600s）：兜底形同虚设，故障恢复仍然以小时计。
