# E-005-error-identity —— 错误身份判定

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-005 错误身份判定），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 现象

两处代码各写了一个 `errors.New("unauthorized")`，文本一模一样，一个错误却
判定不出另一个的身份；反过来，想问「这个错误是不是解析错误、错在哪个字段」，
只能靠解析错误字符串，字段和行号在包装后全都拿不到了。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh go E-005-error-identity
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-005-error-identity \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：同文本的两个 errors.New 身份不同（false）、复用
sentinel 包装后身份不变（true）、errors.As 从包装链取出 *ParseError 的
结构化字段（field="age" line=3）、同类不同值各自保留（line=9）。

## 为什么这样处理

- 身份的判定工具是 `errors.Is`（同一个错误吗）与 `errors.As`（这一类错误吗，
  顺便把类型取出来）。Is 对身份，As 对类别+数据，二者不可互相替代。
- `errors.New` 每次返回新实例，接口比较按 (类型, 值) 判等——文本相同身份也不同。
  所以 sentinel 必须定义成包级 var 全仓复用，谁都不许就地新建。

## 反例

- 每个包各自 `errors.New("unauthorized")` 再用 `==` 互判——身份永不相等。
- 用 `err.Error()` 正则提取字段——错误文本重构（换标点、换语序）即静默失配；
  结构化数据应放进错误类型，用 `errors.As` 提取。
