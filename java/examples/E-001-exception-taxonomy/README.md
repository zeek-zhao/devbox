# E-001-exception-taxonomy —— 异常分类与处理策略映射

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-001 异常分类与处理策略映射），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

同一个异常到不同调用点被解读成不同意思：有的当输入问题直接拒绝，有的当
临时故障重试三次，有的当致命 bug 静默吞掉。根因是只有 `RuntimeException`
一个载体，没有「类别 → 处理策略」的映射，每个调用点各自猜。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-001-exception-taxonomy
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-001-exception-taxonomy \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三种领域异常各归入唯一类别（VALIDATION /
TRANSIENT / INTERNAL），类别决定唯一动作（reject-input / retry / fail-fast），
末行是分类汇总。

## 为什么这样处理

- 用「每类一个异常子类」而不是「错误码字段」表达分类：`instanceof` 判定
  不依赖消息文本，子类再派生一层也不会丢类别。
- 全部继承统一基类 `DomainError`：一次 `catch (DomainError)` 即可接住
  全部业务错误，且不会误捕 `Error` / OOM 这类不该处理的致命错误。
- 未知子类保守归 INTERNAL（快速失败）：分类器宁可停下也不冒充「可重试」。
- 处理策略挂在类别上，上层只问一次类别；受检/非受检的选型在层次内部解决
  （领域错误是非受检的，调用方不被迫到处 `throws`）。

## 反例

- 用 `getMessage()` 前缀猜类别：文本改一个词分类就静默漂移。
- 对 VALIDATION（调用方 bug）重试三次：重试修不好参数错误，只是推迟并放大。
- `catch (Exception e)` 当分类器：会把 `OutOfMemoryError` 之外的意外错误
  一起接走，按错误策略处理。
