# E-001-exception-hierarchy —— 异常层次与分类处理

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-001 异常层次与分类处理），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

同一个错误到了不同调用点被解读成不同意思：有的地方当输入问题直接拒绝，
有的地方当临时故障重试三次，有的地方当致命 bug 静默吞掉。根因是错误只有一个
裸 `Exception`，没有「类别 → 处理策略」的映射，每个调用点各自猜。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-001-exception-hierarchy
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-001-exception-hierarchy \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三种领域异常各归入唯一类别（VALIDATION /
TRANSIENT / INTERNAL），类别决定唯一动作（reject-input / retry / fail-fast），
末行是分类汇总。

## 为什么这样处理

- 用「每类一个自定义异常子类」而不是「错误码字符串字段」表达分类：类型是
  语言一等概念，`isinstance` 沿继承链判定，子类再派生一层也不会丢类别。
- `classify` 对每个错误给出唯一归类，保证同一错误在任何调用点解读一致；
  未知子类保守归 INTERNAL（快速失败），不会静默落入「可重试」。
- 处理策略挂在类别上：VALIDATION 修调用、TRANSIENT 重试、INTERNAL 快速失败，
  上层只问一次类别，不用维护散落各处的 if 表。
- 所有领域异常从统一基类 `DomainError` 派生：想「一次接住所有业务错误」时
  有稳定锚点，又不会误捕 `KeyboardInterrupt` / `SystemExit`。

## 反例

- 用 `str(err)` 前缀猜类别：消息改一个词分类就静默漂移，且子类派生不会跟着变。
- 类别与动作不匹配：对 VALIDATION（调用方 bug）重试三次——重试修不好参数
  错误，只是把失败推迟并放大。
- 捕获 `Exception` 兜底当分类器：宽捕会把 `MemoryError` 这类不该处理的
  错误也接走。
