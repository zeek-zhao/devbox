# E-012-error-aggregate —— 并发错误聚合

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-012 并发错误聚合），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

并发放一批请求，第一个失败就把整批标红并返回：剩下的失败被丢弃，
「3 个超时 + 1 个 IO 错」被压成「1 个失败」——运维看到的是冰山一角，
修复后下一轮又爆出另一个错误，来回试错。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-012-error-aggregate
docker run --rm -v "$PWD":/work -w /work/c/examples/E-012-error-aggregate \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：4 行 worker 结果（按槽位固定顺序），
一行汇总 `total=4 ok=1 failed=3 by_code TIMEOUT=2 IO=1`。

## 为什么这样处理

- 每个 worker 只写自己的槽位：数据无共享写冲突，不需要锁，也不会因竞态丢结果。
- 聚合在全部 join 之后进行，按槽位下标打印：输出与线程调度次序完全解耦，
  同一批结果在任何机器上呈现一致。
- 聚合既报个数也报分布（by_code）：「TIMEOUT=2 IO=1」直接指向两类不同根因，
  比裸的 failed=3 可行动得多。

## 反例

- 第一个错误立即 return：短视失败（fail-fast 用错了地方），批处理语义下丢信息。
- 各 worker 往同一个全局错误变量里写：竞态覆盖，聚合出来的数量随缘。
- join 前就开始读槽位：读到半成品，比不聚合更误导。
