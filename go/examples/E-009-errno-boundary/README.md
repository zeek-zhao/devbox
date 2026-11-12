# E-009-errno-boundary —— 边界转换与错误码

<!-- coverage: exempt Go 轨 E 段错误处理专题示例（E-009 边界转换与错误码），面向错误处理教学，不接入毕业项目；排查指引将收录于 go/docs/排查手册.md 错误处理章（该章由 M11-DOC-go 卡统一落盘，先以本指向登记） -->

## 考点

标准库错误通常同时携带包级 sentinel（如 `fs.ErrNotExist`）和包装类型（如 `*fs.PathError`）。在系统边界用 `errors.Is/As` 解码，再映射为稳定的应用错误码；不要让上层依赖错误文本。

## 易错点

- `strings.Contains(err.Error(), "not exist")` 把给人看的诊断文本当成程序契约，换系统或 locale 就可能失效。
- 所有失败统一映射成 exit 1，会让调用方无法区分可自动恢复与需人工介入的错误。
- 真跑对照用一个稳定构造的权限错误：文本中不含固定英文短语时，字符串匹配得到 `false`，而 `errors.Is` 仍能识别 `fs.ErrPermission`。

## 复现

```bash
TAG=latest bash scripts/run-example.sh go E-009-errno-boundary
# 或直接在 devbox-go 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/go/examples/E-009-errno-boundary \
  ghcr.io/zeek-zhao/devbox-go:latest bash assert.sh
```

逐行输出应与 `expected.txt` 一致：缺失文件被识别为 `*fs.PathError` 并映射为码 3；非法数字映射为 2；成功为 0；未知错误兜底为 70。

## 延伸

错误文本适合诊断人类，错误类型与 sentinel 才适合作为稳定机器接口。在系统边界集中解码一次，之后的业务逻辑只依赖自己的错误码表。
