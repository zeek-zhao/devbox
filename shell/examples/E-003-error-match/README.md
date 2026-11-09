# E-003-error-match —— 按错误身份匹配处理分支

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-003 错误匹配），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

调用外部命令后只判 `if ! cmd; then` 一刀切：探测未命中（预期分支）与探测本身损坏
（真失败）被混成同一种处理——要么未命中也整脚本报错，要么真失败也被「走默认值」吞掉。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-003-error-match
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-003-error-match \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三种探测结果各自落到唯一分支
（`use-result` / `use-default` / `stop`）。

## 为什么这样处理

- 先接住退出码（`probe "$1" || rc=$?`），再对码做 `case` 匹配：匹配的对象是
  「错误身份」，不是笼统的真假。
- 同一命令的不同非零码语义不同（这里是 1=未命中、2=探针损坏）：匹配表和
  命令手册逐条对应，`*)` 兜底未知码走保守动作（stop）。
- 未命中走默认值继续、损坏立即停：预期失败不升级，真失败不降级。

## 反例

- `probe x || use_default`：探针损坏（rc=2）也被当成未命中吞成默认值，假绿。
- 匹配表只写 0/1 不写其余码：命令升级后新增码落进未定义行为。
