# E-001-error-taxonomy —— 错误分类与类型体系

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-001 错误分类与类型体系），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

同一个 error 到了不同调用点被解读成不同意思：有的地方当输入问题直接拒绝，
有的地方当临时故障重试三次，有的地方当致命 bug 静默吞掉。根因是错误只有一个
`error` 接口值，没有「类别 → 处理策略」的映射，每个调用点各自猜。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-001-error-taxonomy
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-001-error-taxonomy \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三种自定义错误类型各归入唯一类别（VALIDATION /
TRANSIENT / INTERNAL），类别决定唯一动作（reject-input / retry / fail-fast），
末行是分类汇总。

## 为什么这样处理

- 用「每类一个自定义错误类型」而不是「一个错误码字段」表达分类：类型是编译期
  概念，`errors.As` 沿包装链取类型，包装多少层都不丢类别。
- `classify` 对每个错误给出唯一归类，保证同一错误在任何调用点解读一致；
  未知类型保守归 INTERNAL（快速失败），不会静默落入「可重试」。
- 处理策略挂在类别上：VALIDATION 修调用、TRANSIENT 重试、INTERNAL 快速失败，
  上层只问一次类别，不用维护散落各处的 if 表。

## 反例

- 用字符串前缀猜类别：`strings.HasPrefix(err.Error(), "transient")` ——文本改一个
  词分类就静默漂移，且无法沿包装链穿透。
- 类别与动作不匹配：对 VALIDATION（调用方 bug）重试三次——重试修不好参数错误，
  只是把失败推迟并放大。
