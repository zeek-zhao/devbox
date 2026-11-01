<!-- coverage: exempt 路由和诊断不生成预处理器标识符或字符串。 -->

# L1-033-macro-stringify —— 观察字符串化与 token 粘贴的展开时机

## 考点

- `#` 将宏参数转成其字面文本，`##` 将两个预处理 token 粘合。
- 外层宏先展开参数、内层宏再字符串化或粘贴，能得到参数宏展开后的结果。

## 为什么这么写

对比 `STR(VALUE)` 与 `XSTR(VALUE)` 的文本，再通过 `XCAT(PRE, FIX)` 生成并访问 `prefix` 标识符，观察两级展开的差异。

## 易错点

- 直接用 `#` 或 `##` 的参数不会在该次替换前先展开。
- `CAT` 的结果必须是有效 token；粘贴出来的标识符需要有实际声明。

## 运行

```bash
TAG=latest scripts/run-example.sh c L1-033-macro-stringify
```
