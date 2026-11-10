# E-006-error-context —— 多层调用的错误上下文链

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-006 错误上下文链），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

三层脚本（deploy -> download -> fetch）失败后，日志里有三段互不相关的报错：
fetch 说 connection refused、download 说 failed、deploy 说 error。
排障时要把三段报错手工对齐才能拼出「deploy 在下载清单时连不上」这整句话。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-006-error-context
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-006-error-context \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：一条完整上下文链
`deploy: download: fetch: connection refused (rc=7)` + 链层数 3。

## 为什么这样处理

- 每一层失败时把「自己是谁」追加进同一条上下文（`CHAIN` 变量逐层前置），
  最上层天然拿到一条从入口到根因的完整链，不用再拼。
- 底层只报技术原因（connection refused）、上层只报自己的动作
  （download/deploy）：上下文是「逐层追加」出来的，没有一层需要知道全貌。
- 退出码原样上抛（return "$rc"）：链负责「在哪里、干什么」，码负责「什么类别」，
  两个通道各司其职（分类见 E-001，包装细节见 E-004）。

## 反例

- 每层各自 echo 一句互不相关的报错：排障时三段日志对不齐，现场拼不出来。
- 只有最底层知道上下文：上层 `cmd || exit 1` 把链拦腰截断，
  报错里丢掉了「为了干什么」。
- 链里不带码：上层按码分派的逻辑（E-003）失效。
