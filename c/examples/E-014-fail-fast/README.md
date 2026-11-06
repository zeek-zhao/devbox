# E-014-fail-fast —— 不可恢复与快速失败

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-014 不可恢复与快速失败），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

内部不变量被破坏（指针越界踩坏了字段、状态机到了不可能的状态）后程序继续跑：
带病数据流经五层，最后以一个毫不相干的表象报错，甚至悄悄写坏持久化数据。
崩溃点与破坏点相距十万八千里，排障无从下手。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-014-fail-fast
docker run --rm -v "$PWD":/work -w /work/c/examples/E-014-fail-fast \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：ok 子命令打印不变量成立；fatal 子命令打印
`FATAL invariant violated: main.c:<行号> (root->left > 0)` 后立即退出，
run.sh 捕获并打印 `fatal_exit=70`。

## 为什么这样处理

- 快速失败只用于 INTERNAL 类错误（程序前提被破坏），与可重试的 ENVIRONMENT、
  可修正的 USAGE 严格区分（分类口径见 E-001）：前者的下一站是人，不是重试逻辑。
- 诊断行带 `文件:行号 + 不变量原文`（CHECK_INVARIANT 宏用 `#expr` 字符串化），
  现场直接定位到检查点，不需要复现。
- 退出码固定为 70（EX_SOFTWARE 惯例）：监控按码告警，不会把「退出 70」
  误读成某次可重试的业务失败。
- 教学实现把 fatal 做成子命令、由 run.sh 捕获退出码：用例整体退出码仍为 0，
  非零码成为被断言的业务输出——「快速失败」被观察而不是被触发到 CI。

## 反例

- 对不变量破坏「尽力恢复」继续跑：恢复逻辑建立在已损坏的状态上，是二次故障发生器。
- assert 触发即 abort 且无诊断留痕：现场只有一个信号码，破坏点无处可查
  （生产构建下 NDEBUG 还会把整条检查悄悄删掉，见 L2-005）。
