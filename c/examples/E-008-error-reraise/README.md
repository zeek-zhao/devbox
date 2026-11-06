# E-008-error-reraise —— 不吞错与重抛

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-008 不吞错与重抛），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

中间层捕获错误后打了一行日志就 `return 0`：日志里有错、程序语义是成功，
顶层照常往下走。故障被推迟到「数据不完整」这类离根因很远的表象上，
日志与结果互相矛盾，排查无从下手。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-008-error-reraise
docker run --rm -v "$PWD":/work -w /work/c/examples/E-008-error-reraise \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：重抛路径顶层看到码 9 并切换备库；吞错路径顶层
误判成功（code=0）——这正是反例的可观察后果。

## 为什么这样处理

- 中间层的合法动作只有三种：处理掉（返回 0 且真的恢复了）、补充上下文后原样重抛
  （码不变）、或直接透传。没有第四种「记了日志就算处理了」。
- 重抛保持码不变，顶层才能按 E-003 的精确匹配路由到正确策略（fail over）。
- 用函数指针把两条路径喂给同一个顶层，让「吞错前后顶层看到的差异」成为输出的一部分。

## 反例

- `if (rc != 0) { log(rc); rc = 0; }`：日志与控制流分叉，是「假绿」的个人版。
- 打印后 `exit(0)` 结束函数：错误消失了，调用方毫无感知。
