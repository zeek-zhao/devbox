# L1-026-record-model

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-26：record 提供组件访问与值相等，但引用组件只具备浅层不可变。
看到相同组件值相等、负页数被拒绝，且修改输入列表不改变记录，即说明掌握。

## 易错点
record 组件是 final 不代表列表内容冻结，因为组件仍引用可变对象。
在紧凑构造器验证约束并用 List.copyOf 做防御性复制。

## 延伸
将 record 用作文档元数据和查询命中模型，明确构造时的验证与复制边界。
比较浅层不可变与深层不可变，并确认每个可变组件如何处理。

## 复现
TAG=latest scripts/run-example.sh java L1-026-record-model
