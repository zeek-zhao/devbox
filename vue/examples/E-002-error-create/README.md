# E-002-error-create —— 结构化错误创建

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-002 结构化错误创建），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

校验失败时 `throw new Error('invalid')`：调用方拿到的只有一句话——
不知道错在哪个字段、该重试还是该改输入、日志里也无法按错误类型聚合。
表单校验、数据加载、提交三类失败混成同一种 "invalid"。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-002-error-create
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-002-error-create \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：两条结构化错误各带
`code`（处理策略）与 `field`（出错数据），汇总元数据 3 个字段。

## 为什么这样处理

- 领域错误类型（ValidationError）+ name/code/field 三元组：
  `code` 让上层按策略分派（E-003），`field` 让表单直接定位到控件，
  `name`/`instanceof` 让匹配不用解析文本（E-005 的身份基础）。
- 构造函数统一走 `super(message)` + 显式赋值：错误对象在跨层传递
  与序列化时元数据不丢。
- message 保留给人看的完整句子：机器读字段，人读 message，两不误。

## 反例

- `throw new Error('invalid')`：所有失败一个长相，上层只能猜。
- 把元数据塞进 message 字符串：`'E_REQUIRED on field name'`——
  机器要解析字符串才能分派，文案一改就碎。
- 校验函数返回错误码数字而不抛：调用方忘记检查就静默继续。
