# E-006-suppressed-cleanup —— 清理失败不遮盖主异常

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-006 清理失败不遮盖主异常），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

手写 finally 清理时，`close()` 自己抛的异常把业务异常整个顶掉：排障日志
只见「close failed」，真正的故障（business failed）连一行痕迹都没有。
这正是 try-with-resources 要解决的经典事故——两者行为差异是排障的
必考题。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-006-suppressed-cleanup
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-006-suppressed-cleanup \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：手动 finally 场景浮出的是 close 的
IllegalStateException、suppressed-count=0（业务异常被遮盖丢失）；
try-with-resources 场景浮出的是 BusinessError、关闭异常进
getSuppressed()；末行固定输出规则。

## 为什么这样处理

- 手动 finally 里抛新异常会**替换**待传播的异常：主体异常丢失且
  suppressed 为空——这不是理论边界，是遗留代码里真实的事故形态。
- try-with-resources 把 close 异常挂到主异常的 `getSuppressed()`：
  主异常（业务原因）优先传播，清理失败作为附属证据保留，两个故障都不丢。
- 反过来「主体正常、close 失败」时，close 异常正常传播：清理失败
  不可能被静默吞掉。

## 反例

- 在 finally 里写 `close()` 且不处理其异常：close 一炸，业务异常蒸发。
- 修复方式写成 finally 里 `try { close(); } catch (Exception e) {}` 空吞：
  业务异常保住了，但清理失败变成黑洞，资源泄漏无从发现。
- 依赖 `getSuppressed()` 做业务分流：suppressed 是诊断信息，不是
  主异常——分流必须看主异常。
