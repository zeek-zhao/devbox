# E-006-error-context —— 上下文附加

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-006 上下文附加），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

顶层日志只有一句 `operation timed out`——不知道在拨哪台主机、为哪个用户、
在哪一步超时；排查要在代码里逐层翻调用链。另一头，把用户输入直接拼进错误
文本，恶意输入（换行、引号）把日志搅乱甚至注入。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-006-error-context
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-006-error-context \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：逐层上下文拼出的完整链文本、errors.Is 确认身份
保留、Unwrap 逐层剥离（outer→inner）、%q 引住恶意输入且身份不受影响。

## 为什么这样处理

- 中间层最懂「本层在做什么」：`fmt.Errorf("load profile %q: %w", user, err)`
  一行同时完成附加上下文与保住身份，顶层拿到可读链 + 可判定错误。
- 对外可见的数据一律 `%q` 引住：换行、引号被转义，日志保持一行一条，
  不可被输入注入。

## 反例

- 只 `%w` 不加上下文：错误一路裸奔到顶层，只有 `operation timed out`
  没有任何位置信息。
- 用 `%v` 附加上下文：文本有了、身份丢了，上游所有 `errors.Is` 判定失效。
- 把用户输入裸拼进错误文本：日志注入与日志多行污染。
