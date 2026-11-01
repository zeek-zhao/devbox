<!-- coverage: exempt Prettier 只由仓库统一格式化门禁检查，不属于 todo 应用的运行功能或测试逻辑，项目内没有独立格式检查器。 -->

# L2-005-prettier-check —— 将 Prettier 检查接入用例

## 考点

- 对故意不符合格式的 JavaScript 文件运行 `prettier --check`。
- 区分发现格式差异的退出码 1 与参数或配置错误的退出码 2。

## 为什么这么写

把 Prettier 的原始诊断捕获到临时文件，stdout 仅打印稳定的业务判定；检查复用仓库 `.prettierrc.json` 的 `printWidth: 100` 和 `singleQuote: true`。

## 易错点

- 不能把任意非零状态都判为格式差异，错误参数时 Prettier 返回 2。
- 检查输入必须确实未格式化，否则成功退出属于测试失效。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-005-prettier-check
```
