# E-005-error-identity —— 错误身份判定

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-005 错误身份判定），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 考点

`errors.Is` 判断错误身份，`errors.As` 判断错误类别并取出结构化字段。每次调用 `errors.New` 都创建新实例，即使文本相同也不是同一个错误；sentinel 应由包级变量复用。

## 易错点

- 每个包各自 `errors.New("unauthorized")` 再用 `==` 互判，身份永不相等。
- 用 `err.Error()` 解析字段或行号，文本重构就会静默失配；应把结构化数据放进错误类型并用 `errors.As` 提取。
- 真跑对照：重新创建同文本错误得到 `false`；复用 sentinel 并经 `%w` 包装后用 `errors.Is` 仍得到 `true`。错误结果作为 stdout 期望数据，进程保持成功退出。

## 复现

```bash
TAG=latest bash scripts/run-example.sh go E-005-error-identity
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-005-error-identity \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

逐行输出应与 `expected.txt` 一致：同文本的两个 `errors.New` 身份不同、复用 sentinel 包装后身份不变、`errors.As` 取到 `*ParseError` 的 `field="age" line=3`，同类第二个实例保留 `line=9`。

## 延伸

可以把 `Is` 理解为“是不是这个哨兵”，把 `As` 理解为“是不是这种类型、并取出数据”；身份与类别是不同维度，不能互相替代。
