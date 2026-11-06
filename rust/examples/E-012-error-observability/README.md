# E-012-error-observability

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无错误观测落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

5 行输入 2 行非法。程序继续跑完：stdout 只有业务输出（3 行成功 + 1 行
降级结果）；stderr 出现 `[WARN] row 2: ... degrading to id 0` 与
`[ERROR] row 4: ...` 两条带锚点的分级诊断；收尾一行计数
`metrics: processed=3 warned=1 failed=1`。失败既没有吞掉，也没有打断业务流。

## 复现

```
TAG=latest scripts/run-example.sh rust E-012-error-observability
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-012-error-observability \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
row 0: id 1
row 1: id 2
row 2: id 0
row 3: id 4
metrics: processed=3 warned=1 failed=1
-- stderr --
[WARN] row 2: parse failed (invalid digit found in string), degrading to id 0
[ERROR] row 4: parse failed (invalid digit found in string)
```

## 为什么

可观测性三要素在 std 里就有落点：stdout/stderr 分流（业务数据与诊断数据
不互相污染，下游可以分别消费）、固定前缀锚点（`[WARN]`/`[ERROR]` 让
grep/日志采集有稳定模式）、计数汇总（失败率从日志可算，不必逐行数）。
分级的意义：WARN 是「已兜底、可继续」，ERROR 是「策略失效、需要人看」——
两条线不能混用，否则告警噪音淹没真故障。

## 反例

所有诊断都 `println!` 进 stdout：业务输出被污染，管道下游
（`| jq`、文件导入）直接坏。反向反例是只打 ERROR 不打计数——
「今天挂了多少」没有数字，只能人肉数日志，告警阈值无从谈起。

## 落点

stdout/stderr 分流与分级口径见 `rust/docs/排查手册.md` 错误处理章
（M11-DOC-rust 卡落盘）。
