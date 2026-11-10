# E-010-structured-logging —— 结构化错误日志

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-010 结构化错误日志），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

错误日志长成 `[ERROR] db down!!!` 这样的自由文本：想统计「过去一小时
TRANSIENT 错误几次」只能对文本做正则；消息措辞一改，告警规则和统计
全部静默失效——日志给人读没问题，给机器查就先得解析玄学。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-010-structured-logging
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-010-structured-logging \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三行 JSON 日志，每行固定含 code（错误类别）、
level、message 三个键，键按字典序输出；错误类别是字段而非消息前缀，
机器可按 `code=TRANSIENT` 直接检索统计。

## 为什么这样处理

- `logging` + 自定义 Formatter 是零依赖方案：记录的字段进
  `record.code`（`extra=` 传入），Formatter 统一序列化成一行 JSON——
  一行一条保证逐行解析不串行。
- 错误类别（code）沿用 E-001 的分类词汇表（VALIDATION/TRANSIENT/…）：
  日志字段与异常层次同源，分类规则只维护一份。
- `sort_keys` + 固定键集：输出跨运行逐字节稳定，可直接做 expected 断言；
  生产环境换成时间戳/trace_id 等字段时，同样保持键序确定。

## 反例

- `logger.error(f"TRANSIENT: {err}")`：类别写进消息文本，统计靠正则，
  措辞改动即静默失效。
- 多行打印异常栈到 stdout 混进业务输出：日志采集按行切分后栈被拆散。
- 把密码、token 等敏感值带进消息：日志成了凭证泄露源——错误信息要含
  上下文（哪个操作、哪个键），不含敏感值。
