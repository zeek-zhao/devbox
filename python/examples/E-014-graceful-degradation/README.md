# E-014-graceful-degradation —— 优雅降级

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-014 优雅降级），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

主数据源抖一下，整个读路径直接报错：明明有缓存快照可用，调用方却拿不到
任何结果；或者反过来，降级「成功」却没人知道结果来自回退路径、主路径
已经坏了多久——降级不透明和降级失败一样危险。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-014-graceful-degradation
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-014-graceful-degradation \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：主源失败的原因逐字留痕；回退结果明确标注
数据来源（served by cache）与失败源数量（failed-sources=1）；两个源
全部失败时抛 RuntimeError 并携带每个源的失败原因，末行固定输出降级规则。

## 为什么这样处理

- 回退是「明账」：返回值带 served_by 与 failed-sources，结果从哪来、
  主路径是否还坏着，调用方与日志都能回答——降级透明才可运维。
- 每次尝试失败都追加原因（源名 + 类别 + 消息）：全败时 RuntimeError
  的消息就是完整的失败时间线，不需要复跑。
- 「全败才整体失败」是降级的边界：只要还有一个可用源就继续服务，
  一个都没有时按快速失败协议上报（对接 E-008 的退出码）。

## 反例

- 静默降级：结果来自缓存但调用方以为是实时数据，业务在旧数据上做决策。
- 降级路径自己抛错不处理：回退把原始故障换成另一个故障，日志里只见后者。
- 无限级回退链不设上限：每次故障都走完整条链，最坏延迟失控——
  链表要短且每级有截止时间（对接 E-011）。
