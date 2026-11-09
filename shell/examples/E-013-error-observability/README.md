# E-013-error-observability —— 失败的结构化可观测记录

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-013 失败可观测性），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

失败只有一句人话日志（"something wrong at download"）：日志管道没法按
step/status/rc 聚合，"本周下载失败多少次、都是什么类别"答不出来；
或者反过来，诊断打满了 stdout，消费 stdout 的下游把日志当数据处理。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-013-error-observability
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-013-error-observability \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：一行业务汇总 + 4 条 `step=... status=... rc=... reason=...`
结构化记录（成功与失败都记，失败行带码与原因类别）。

## 为什么这样处理

- 记录走统一出口 `record()`：字段固定（step/status/rc/reason），
  grep/awk/jq 都能直接消费，失败率与失败类别变成可聚合的数字。
- 成功也记录：观测要的是完整时间线，只有失败才有记录时，
  「没记录」与「没执行」无法区分（对应素材池 S-06 的教训）。
- 汇总行（ok=3 failed=1）给人看，结构化行给机器看，
  两者都在 stdout 上按固定顺序输出，互不干扰。

## 反例

- 失败只 echo 一句人话：无法聚合，"失败变多了吗"永远答不出。
- 结构化字段手拼 JSON 不转义：值里带引号/空格就碎，宁可 key=value。
- 失败记录里不带 rc 与 reason 类别：有记录但没法按错误体系分派。
