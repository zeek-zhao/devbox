# E-008-oom-taxonomy —— JVM 致命错误分类

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-008 JVM 致命错误分类），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

日志里出现 `java.lang.OutOfMemoryError` 就一律「加内存重启」：但 OOM 家族
里 heap exhaustion（内存不足/泄漏）与 StackOverflowError（递归失控）
的处置完全不同——按消息文本一刀切，递归 bug 被加堆掩盖，堆泄漏被
加堆推迟，直到容器 OOM-killed 才发现方向全错。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-008-oom-taxonomy
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-008-oom-taxonomy \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：-Xmx16m 下申请超大数组触发
`java.lang.OutOfMemoryError`（heap-exhaustion，处置是加堆或查泄漏）；
无限递归触发 `java.lang.StackOverflowError`（call-depth，处置是修
递归）；末行固定输出「按触发源分类，不按消息文本分类」的结论。

## 为什么这样处理

- 用 `getClass().getName()` 做分类锚点而不是 message：错误消息措辞随
  JVM 版本漂移，异常类型 + 触发方式才是稳定接口。
- 两类致命错误都可观测、可捕获演示：捕获后打印分类与处置建议，
  演示「捕获 Error 是为了报告后收尾」，不是继续服务。
- StackOverflowError 不打印实际深度：深度随栈配置/帧大小漂移，
  属不稳定输出；结论行只保留可判定事实。

## 反例

- `catch (Throwable t) { log(); continue; }`：把 OOM/SOE 当普通失败
  吞掉继续服务——堆已坏，继续跑只会产生更多坏结果。
- 见 OOM 就加 `-Xmx`：泄漏场景加堆只是推迟，容器内存上限突破后被
  OOM-kill，故障面更大。
- 把 StackOverflowError 也当「内存不足」：方向错到修不好，
  递归改尾调用/剪枝才是正解。
