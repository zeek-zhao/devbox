# E-004-error-wrap —— 传播与包装

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-004 传播与包装），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

错误从底层传到顶层后只剩两难选择：要么原样上抛（顶层看不到发生在哪一步），
要么 `fmt.Errorf("commit log: %v", err)` 加了位置却把错误「重造」了一遍——
顶层拿到一个内容相似但身份不同的新错误，`errors.Is` 判定根因永远失败。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-004-error-wrap
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-004-error-wrap \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三层 `%w` 包装的完整链文本
（`commit log: write segment: disk full`）、`errors.Unwrap` 剥一层、
`%w` 保链判定 true、`%v` 断链对照判定 false 且 `Unwrap` 返回 nil。

## 为什么这样处理

- 中间层传播错误时一律 `fmt.Errorf("步骤: %w", err)`：`%w` 把底层错误存进
  新错误的 `Unwrap` 链，文本有位置信息，身份还能一路追溯到底层 sentinel。
- `errors.Unwrap` 每次剥一层，供逐层检查；日常判定优先 `errors.Is`/`As`，
  不必手写剥层循环。

## 反例

- `%v`/`%s` 当包装用：文本接近但 `Unwrap` 为 nil，等价于在传播途中换掉了
  错误，所有 `errors.Is` 判定被静默破坏。
- 每层都重复拼同样的前缀：`commit log: commit log: ...`，链文本冗余且难读；
  前缀应描述「本层做了什么」。
