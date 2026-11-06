# E-012-error-join —— 并发错误聚合

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-012 并发错误聚合），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

批量同步 N 个分片时：遇到第一个错误就整体 return，其余分片的失败全部失明，
运维每次只能发现一个坏分片；或者自己拼 `multierror` 字符串，拼完的错误
丢了身份，上游没法判断「失败集合里有没有限流」。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-012-error-join
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-012-error-join \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：聚合错误文本按分片号稳定排列（两行成员）、
errors.Is 对成员 ErrDisk/ErrAuth 成立、对非成员排他、单失败也能聚合、
空聚合成 nil。

## 为什么这样处理

- 先等全部 worker 收工（WaitGroup），把所有失败收集齐再一次 `errors.Join`：
  一次暴露全部坏分片，修复一轮顶过去 N 轮。
- `errors.Join` 的聚合错误实现 `Unwrap() []error`：每个成员的身份都在，
  `errors.Is` 对任一成员成立——聚合只加结构，不毁判定。
- 并发完成顺序不定，聚合前按分片号排序：输出稳定，expected 才可能逐行断言，
  日志 diff 才有意义。

## 反例

- 第一个错误就 return：批处理变成「每次修一个」，故障暴露以轮数为单位放大。
- 手工 `strings.Join(msgs, ";")` 拼错误：文本聚合、身份尽失，errors.Is 全断。
- 聚合顺序跟随 goroutine 完成顺序：同一故障两次运行的输出不同，无法对账。
