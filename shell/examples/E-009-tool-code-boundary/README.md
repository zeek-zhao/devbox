# E-009-tool-code-boundary —— 外部命令退出码的边界翻译

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-009 外部命令退出码边界翻译），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

脚本把外部工具的原始退出码直接往上传：`grep` 的 1（未命中，预期分支）被
上层当成失败重试；`diff` 的 1（有差异，正是要写文件的理由）被当成错误
退出；工具真坏了（2）反而和未命中混成一谈。工具语义泄漏成了脚本语义。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-009-tool-code-boundary
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-009-tool-code-boundary \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：5 次调用各自给出 `raw=工具原始码`、
`kind=翻译后的语义类别`、`action=对应动作`。

## 为什么这样处理

- 边界函数（grep_kind/diff_kind）是唯一的翻译点：先接住工具原始码，
  再查该工具手册的码表翻译成 kind（match/no-match/tool-broken 等），
  上层只认 kind 与 action，不认工具。
- 「预期中的非零」（grep 1、diff 1）翻译成正常分支，不再伪装成失败；
  「工具坏了」（2 或任何未知码）统一落 tool-broken，走 stop，
  不与预期分支混淆。
- 翻译点集中：工具换版本、换参数改语义时，只需要改一个函数。

## 反例

- `grep -q pat file || die "grep failed"`：未命中也被 die，预期分支变成故障。
- 上层直接 `if [ $? -eq 1 ]` 判工具码：码表散落全仓，换工具全改一遍。
- 不区分 1 和 2：工具真坏（权限、缺失）被吞进「没有匹配」的默认值，假绿。
