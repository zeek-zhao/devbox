# E-006-error-context —— 错误上下文附加

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-006 上下文附加），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

线上告警只给一句 "load failed"，排查时不知道是哪个用户、哪次请求、哪个字段出的问题；
日志里搜不到、告警聚不了类——错误在产生时就没有携带结构化上下文。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-006-error-context
docker run --rm -v "$PWD":/work -w /work/c/examples/E-006-error-context \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：两行结构化事件，各带 `code / op / target` 与逐层附加的
KV 字段（user_id、request、trace 或 field、value）。

## 为什么这样处理

- 上下文以 KV 字段挂载，逐层 `with_field` 附加：底层知道 user_id，处理层知道
  request 与 trace，最终一条事件同时携带两层视角，检索与聚合都按字段命中。
- 字段表满后丢弃新增字段但保持码不变：附加动作绝不改变错误身份。
- 与消息链（E-004）分工：消息给人读，字段给机器查。

## 反例

- 把上下文拼进一句话再靠 `strstr` 反解：字段边界一变解析就断，也无法按字段聚合。
- 上下文只在最顶层补：底层才知道的关键键值（user_id）在顶层根本拿不到，补出来是空的。
