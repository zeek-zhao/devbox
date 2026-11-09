# E-013-exit-code-protocol —— 失败退出码协议

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-013 失败退出码协议），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

批处理程序所有失败一律 `System.exit(1)`（甚至异常栈直接崩出退出码 1）：
调用方（脚本、CI、调度器）无法区分「该修命令」还是「该修数据」，
只能解析 stdout 文本猜——错误协议缺位让失败变得不可编程消费。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-013-exit-code-protocol
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-013-exit-code-protocol \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：Main 声明协议（usage=2 / data=1 / success=0）；
三个 Probe 子进程分别演示 usage 失败退出 2、data 失败退出 1、成功退出 0，
错误详情进 stderr（stdout 只留协议行），宿主回显每个子进程的真实退出码。

## 为什么这样处理

- 退出码是进程对外的错误协议：惯例 0 成功、1 数据/业务失败、2 用法错误，
  上层不解析文本即可分流（重试/告警/人工介入）。
- 用独立 Probe 进程演示：`System.exit` 的真实退出码只有跨进程边界才能
  体现，run.sh 捕获子进程退出码并回显，证据真实可断言。
- 错误详情进 stderr、stdout 只留可断言的协议行：管道消费者不被污染
  （与 python 轨 E-008 同一契约，跨语言一致）。

## 反例

- 所有失败一律 exit 1：调用方无法分流，重试逻辑对 usage 错误也生效。
- 未捕获异常直接崩出（退出码 1 且无结构化 stderr）：失败原因只有整段
  栈文本，机器不可消费。
- 把错误详情打进 stdout：`2>err.log` 失效，管道下游拿到混合流。
