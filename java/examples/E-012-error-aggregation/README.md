# E-012-error-aggregation —— 多任务错误聚合

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-012 多任务错误聚合），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

批量任务里一个失败就 cancel 其余/直接抛出：每轮只能发现一个坏任务，
N 个坏任务要跑 N 轮；且成功任务的结果被一并丢弃。批次处理需要的是
「全部跑完、逐个记账、汇总后再决策」。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-012-error-aggregation
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-012-error-aggregation \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：4 个任务按提交顺序逐个记账——doc-2 与 doc-4
各带异常类型与原因，doc-1/doc-3 正常；汇总行 ok=2 failed=2 声明
「先收齐全部失败再决策」；末行固定输出聚合规则。

## 为什么这样处理

- `invokeAll` 保证全部任务跑完才返回：逐个 `get()` 收账，每个失败以
  `ExecutionException.getCause()` 还原业务异常类型与消息——解包见
  E-005，这里聚焦聚合策略。
- 按提交顺序输出：失败清单与任务一一对应，可直接定位重跑对象；
  并发执行不影响记账顺序。
- 聚合不是带病放行：ok/failed 全部报告后由调用方决策（全部重跑/
  只重跑失败/拒绝批次），决策点集中在汇总之后。

## 反例

- `futures.get(0).get()` 失败即抛：后面的任务结果被丢弃，坏任务
  一次只暴露一个。
- 吞掉 ExecutionException 只统计数字：失败类型/原因丢失，无法分类重试。
- 汇总后默认继续处理坏批次：聚合被误用成带病放行，坏数据流入下游。
