<!-- coverage: pending -->

# L3-009-form-validation —— 声明式有序规则引擎

## 考点

- required/min/max 规则数组与校验器映射分离，打印实际规则顺序。
- 四组输入分别触发必填、最短、最长、通过，并由组件 SSR 展示。
- required 优先，长度边界包含等号，空白文本也视为未填。

## 为什么这么写

按数组顺序遇到首个错误即返回，保证空字符串不被报告成 min 错误。
引擎不硬编码四组输入分支；新增规则需要注册明确校验器，
未知规则直接抛错，不能默认通过。示例以字符串长度为单位，不宣称处理字素簇。

## 易错点

- 把 min 放在 required 前，空字符串的错误信息会变成 min:3。
- 用大于而非大于等于，会拒绝长度恰好等于边界的值。
- 只判断字符串是否 truthy，会让三个空格通过 required。
- Vue SSR 将空值属性输出为 `data-input` 而非 `data-input=""`，两者都表示空字符串。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L3-009-form-validation
```
