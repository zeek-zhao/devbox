# E-003-error-match —— 捕获与精确匹配

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-003 捕获与精确匹配），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

调用方收到错误后统一当一种错处理：本该「建默认记录」的 NOT_FOUND 被拿去重试，
本该上报的 NO_MEMORY 被当成超时睡 3 秒再来一次。错误的「处理策略」和
「错误身份」对不上号。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-003-error-match
docker run --rm -v "$PWD":/work -w /work/c/examples/E-003-error-match \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：4 行，分别是无错、两个精确匹配分支、一个兜底分支。

## 为什么这样处理

- 先判成功（code==0），再用 `switch(code)` 精确匹配有既定策略的码，
  `default` 兜底显式 escalate——每个错误必然落入唯一分支，不存在「漏网后被忽略」。
- 精确匹配放在兜底之前，保证特化策略优先；兜底分支的存在让「新增了码但没写策略」
  变成可观察的 escalate，而不是静默按成功处理。

## 反例

- 按 `strstr(what, "not found")` 匹配：文案一改匹配全断；两类错误文案相近时互相误配
  （E-005 有同型陷阱的定量演示）。
- 只写精确分支不写 default：新增码直接跳过整段处理逻辑，静默丢错。
