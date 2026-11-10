# E-010-structured-logging —— 结构化错误日志

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-010 结构化错误日志），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

错误日志长成 `[ERROR] db down!!!` 这样的自由文本：想统计「过去一小时
TRANSIENT 错误几次」只能对文本做正则；消息措辞一改，告警规则和统计全部
静默失效——日志给人读没问题，给机器查就先得解析玄学。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-010-structured-logging
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-010-structured-logging \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三行 JSON 日志，每行固定含 seq、code、level、
message 四个键；错误类别是可检索字段而非消息前缀，机器按
`code=TRANSIENT` 直接过滤统计；seq 用递增序号替代真实时间戳，输出确定。

## 为什么这样处理

- 单行 JSON 是日志采集的通用底座：一行一条保证按行切分不串行，
  字段化保证统计/告警不依赖消息措辞。
- code 字段沿用 E-001 的分类词汇表（VALIDATION/TRANSIENT/…）：
  日志字段与异常层次同源，分类规则只维护一份。
- 键序固定 + seq 替代时间戳：输出跨运行逐字节稳定，可直接做 expected
  断言；生产里把 seq 换成时间戳/trace_id 时同样保持键序确定。

## 反例

- `log.error("TRANSIENT: " + err.getMessage())`：类别写进消息文本，
  统计靠正则，措辞改动即静默失效。
- `e.printStackTrace()` 多行打栈混进业务 stdout：采集按行切分后栈被拆散，
  且 stdout 与日志流混淆。
- 把密码、token 等敏感值带进消息：日志成了凭证泄露源——错误信息要含
  上下文（哪个操作、哪个键），不含敏感值。
