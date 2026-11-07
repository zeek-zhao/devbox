# E-011-context-timeout —— 超时与取消

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-011 超时与取消），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

慢查询没有预算控制：下游一卡，调用方 goroutine 永远挂着，超时只在某个
HTTP client 的配置里孤零零生效；或者超时终于报错，日志里却只有一句
`i/o timeout`——分不清是「预算到了」（正常背压）还是「调用方不要了」（主动取消），
重试策略因此选错。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-011-context-timeout
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-011-context-timeout \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：超时路径报 `handle: query: context deadline exceeded`
且 errors.Is 判定 DeadlineExceeded、取消路径报 context canceled 且判定
Canceled、预算充足时正常完成 err=nil。

## 为什么这样处理

- context 把「超时」与「取消」统一成一种机制：ctx.Err() 只有
  DeadlineExceeded 与 Canceled 两个值，业务用 select 同时等结果与
  ctx.Done()，两种失败原因都能沿 %w 链保留，上游 errors.Is 一判便知该重试
  （DeadlineExceeded）还是该放弃（Canceled，调用方已离开）。
- WithTimeout 必须 defer cancel：即使业务先完成也要释放计时器，
  否则泄漏到请求结束。

## 反例

- 忽略 ctx 只跑业务：超时预算形同虚设，取消信号传不进慢调用。
- 把 ctx.Err() 用 %v 包掉：上游再也分不清超时与取消，重试决策瞎猜。
- 对 Canceled 重试：调用方早已放弃，重试只会烧资源。
