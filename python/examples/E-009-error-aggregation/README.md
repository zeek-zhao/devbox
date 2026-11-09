# E-009-error-aggregation —— 校验错误聚合

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-009 校验错误聚合），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

批量校验一遇到第一个错误就抛异常终止：用户修一个字段重跑一次，
下一条错误再修再跑——N 条坏数据要跑 N 轮才能见全貌。首错即停
把「修数据」变成了低效的人机乒乓。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-009-error-aggregation
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-009-error-aggregation \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：每条坏记录列出它的**全部**错误
（record 2 同时有 name-empty 与 age-negative），最后汇总 bad=3、errors=5
并声明「全部报告后再拒绝」。

## 为什么这样处理

- 校验器返回错误列表而不抛异常：把「发现错误」与「处理错误」解耦，
  聚合策略（全量报告/限量报告/直接拒绝）由调用方决定。
- 聚合的价值在交互成本：一次给出完整清单，修一次重跑一次即可收敛。
- 最终仍要拒绝（fail-fast 的语义保留在边界）：聚合是「报告完整」，
  不是「带病放行」——汇总后统一退出码见 E-008。

## 反例

- 循环里遇到坏记录直接 `raise`：每次只暴露一个错误，修复反馈周期被拉长。
- 聚合后只是打印警告却继续处理坏数据：把「报告完整」误用成「带病放行」，
  坏数据流进下游。
- 错误列表只存字符串不存定位（记录号/字段名）：清单有了但无法逐条修复。
