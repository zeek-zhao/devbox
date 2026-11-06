# E-015-antipattern-compare —— 反模式对照（吞错 vs 显式上抛）

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-015 反模式对照），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象（本例本身就是一组反例的现场）

读配置的函数打不开文件却照常返回 0：调用方拿 0 当合法配置继续算，
下游产出一份「看起来正常」的错误结果。没有崩溃、没有非零退出、
日志里顶多一行没人看的警告——这类「假数据」故障比崩溃更难发现。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-015-antipattern-compare
docker run --rm -v "$PWD":/work -w /work/c/examples/E-015-antipattern-compare \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：bad 版本 `value=0 error_reported=0` 且假数据流入下游
（computed=0）；good 版本 `value=none error_reported=1 code=3`，下游被保护。

## 为什么这样处理

- 把两种写法放在同一个程序里对照，让差异成为输出本身：吞错的代价
  （下游 computed=0）是可直接断言的事实，不靠口头告诫。
- good 版本遵循 E-002 的错误值纪律（码 + 显式上抛），调用方拿到选择权：
  本例选择「中止下游」，换一个调用方也可以选择默认值——但那是显式决策，
  不是静默默认。
- 与 E-008 的差异：E-008 讲中间层的重抛纪律，本例讲同一流程首尾的
  可观察结果对照，作为整组 E 例的收束。

## 反例（本例的教学核心，再列三条）

- `(void)cfg_open(&ok);` 后不检查：返回值与出参都被无视，失败在源头就被丢弃。
- 失败时「返回一个默认值」且不告知调用方：默认值与真值在类型上不可区分。
- 用 `abort()` 对付可恢复失败：把 E-014 的快速失败用错类别，本可降级的场景直接炸进程。
