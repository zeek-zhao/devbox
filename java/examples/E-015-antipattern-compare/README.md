# E-015-antipattern-compare —— 错误处理反模式对照

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-015 错误处理反模式对照），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

两类高频反模式让故障「看起来在跑、实际已坏」：`catch (Exception e) {}`
把失败吞进无日志的黑洞（任务失败与任务成功从外部无法区分）；按
`getMessage().contains("timeout")` 分流分类，措辞一改行为就漂移。
对照项配正确做法：类型分流 + 单行结构化日志。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-015-antipattern-compare
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-015-antipattern-compare \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：吞错反例与结构化日志修复对照（单行 JSON：
code/type/message），文本分流反例与类型分流修复对照（storage busy
不含 timeout，文本分流给出 other；类型分流给出稳定的 TRANSIENT），
末行固定输出三条规则。

## 为什么这样处理

- 吞错的替代不是「不吞」，而是「记录后再决策」：结构化单行 JSON
  与 E-010 的日志契约同构，机器可检索、告警可分类。
- 分流靠类型（instanceof / 多 catch）不靠消息文本：`TransientException`
  的分支在措辞改动下行为不变——文本匹配的脆弱性用真实消息演示。
- 反例只演示、不扩散：反模式代码与修复代码放在同一文件相邻方法，
  名称前缀 anti-/fixed-，评审时一眼可辨。

## 反例

- 反模式自身即本例演示对象：空 catch、文本分流——真实事故里分别对应
  「无日志可查」「分类静默漂移」。
- `catch (Exception e)` 顶格兜底：连 `OutOfMemoryError` 之外的意外错误
  一起接走并按错误策略处理。
- `e.printStackTrace()` 兜底：多行栈进 stderr，采集端按行切分后
  无法关联上下文，等于换格式继续静默。
