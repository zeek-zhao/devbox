# E-002-error-create —— 错误创建：结构化诊断与退出码

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-002 错误创建），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

失败发生时诊断信息随手 `echo`：有时打到 stdout 混进业务输出，有时不带「发生在哪」，
有时退回 0。排障时既拼不出完整现场，也无法用退出码区分失败类别。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-002-error-create
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-002-error-create \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：失败路径一条标准化诊断
（`main.sh: validate-name: name is empty`）+ `rc=2`，成功路径只有 `rc=0` 且无诊断行。

## 为什么这样处理

- 统一出口 `err()`：诊断信息固定走 stderr（stdout 只留给业务输出，管道里才不会被污染），
  格式固定为 `<脚本名>: <发生地>: <发生了什么>`，出问题能直接定位到函数。
- 退出码与失败类别一致（这里是 usage=2）：上层不用解析文本就能按码分派处理。
- 成功路径零诊断：`report` 只在有诊断时打印诊断行，stdout 不被空行和噪声污染。

## 反例

- `echo "错误!"` 打到 stdout：下游消费 stdout 的管道把诊断当成数据吞下去。
- 失败后 `exit 0` 或不带码的 `return`：调用方拿不到失败信号，静默假绿。
- 诊断里不带位置：只有一句 "failed"，定位全靠猜。
