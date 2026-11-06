# E-015-antipattern-compare

## 现象
三对反模式/正例逐项对照：空 catch 吞异常（调用方一无所知）vs 记录后
`throw;` 重抛；按值捕获切片（`seq=77` 取不到）vs 引用捕获保真；
笼统 `failed` vs 前缀拼接保留根因路径。每对 ANTI/GOOD 输出紧邻。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-015-antipattern-compare
```

## 期望输出
```text
ANTI swallow: caller saw nothing
GOOD log: disk full
GOOD rethrown: disk full
ANTI slicing: what=rich error
GOOD ref: what=rich error seq=77
ANTI vague: failed
GOOD context: build: open /data/index.bin: errno=2
```

## 为什么
三个反模式共同点是**信息在错误链上蒸发**：吞异常让故障根本不存在于
任何人的视野（最难查的一类——「程序没报错但结果不对」）；按值捕获
触发切片，`RichError` 的字段静默消失，编译器只有 `-Wcatch-value` 级
提醒；笼统重抛把根因丢在上一个栈帧。对照写法各保留一样东西：重抛
保留异常本体、引用捕获保留派生字段、前缀拼接保留根因消息。
本例是三张 E 卡的收束面：前面 14 个 E 类各自展开的正写法，反着写
基本就是这三条。

## 反例
（本例整例即反例集，每对的 ANTI 行就是反例本体。）

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
