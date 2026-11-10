# E-004-interrupt-handling —— 中断处理与协作式取消

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-004 中断处理与协作式取消），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

`catch (InterruptedException e) {}`（空吞）让取消请求人间蒸发：任务停不
下来、线程池 shutdown 等到超时、上层永远等不到结果。中断不是杀线程的
开关，是「请求停止」的协作信号——接信号的人不回信，取消机制整体失灵。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-004-interrupt-handling
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-004-interrupt-handling \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：sleep 中的 worker 收到中断被唤醒；捕获后先
恢复中断位（flag restored=true），再按标志协作停止；主线程 join 正常
收尾，进程干净退出，末行固定输出中断规则。

## 为什么这样处理

- 捕获 `InterruptedException` 后立即 `Thread.currentThread().interrupt()`
  恢复标志：当前层不处理（不退出循环/方法）时，必须把取消请求传给
  下一个检查点，否则信号在此处蒸发。
- 用标志位做协作检查（isInterrupted）：worker 是「自己决定何时停」，
  不是被强杀——Java 没有安全杀线程的 API，`Thread.stop` 已废弃。
- `interrupt()` 只对阻塞点（sleep/wait/join/阻塞 IO）与检查点生效：
  「中断后任务立刻消失」是误解，停止是逐检查点推进的。

## 反例

- `catch (InterruptedException e) {}` 空吞：取消请求丢失，线程池关不掉。
- 捕获后直接抛 `RuntimeException` 却不恢复标志：上层若再包一层阻塞调用，
  中断状态已丢，行为退化成普通失败。
- 用 `Thread.stop()` / 标志位轮询 sleep 替代中断：前者破坏对象状态，
  后者响应延迟取决于轮询间隔。
