# E-013-error-observability —— 可观测性

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-013 可观测性），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

一次底层故障在日志里出现五条——每一层都「顺便」记了一遍，彼此还不一致，
值班要在五条里猜哪条是根因；另一头，有的错误只在日志里出现过、函数却返回
nil，日志与程序状态对不上。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-013-error-observability
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-013-error-observability \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：边界一条结构化记录（msg + err 字段 + op 属性）、
反例的中间层重复记录（无 err 字段）、记录之后 errors.Is 判定不受影响。

## 为什么这样处理

- 结构化日志（log/slog）把错误放进 `err` 字段而不是拼进 msg：可按 err 检索、
  可被日志系统解析；属性（op=list-users）给出检索维度。
- 「边界记一次」原则：请求入口（或错误最终汇聚处）记一条带全上下文的；
  中间层只负责 `%w` 传播。记录次数与错误传播层级解耦，日志才可信。
- 记录与返回是两个独立义务：记了日志仍必须返回错误（反之，可恢复的内部
  重试成功后也不必把每次失败都 ERROR 出来）。

## 反例

- 中间层 `log.Error` 后继续 return err：一次失败 N 条日志，告警风暴。
- `log.Error(err.Error())` 后 return nil：日志里全是红、程序自以为成功。
- 把 err 用 %s 拼进 msg 不放字段：日志系统无法按错误类型聚合统计。
