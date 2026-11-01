<!-- coverage: pending -->

# L1-015-form-modifiers

## 考点

验证 `.trim` 与 `.number` 对输入值的转换，并展示带修饰符的 v-model 模板在 SSR 中生成的初始 HTML。

## 易错点

修饰符依赖输入事件；SSR 不会派发输入事件，因此本用例在 JavaScript 中显式模拟更新转换，不把 SSR 初始值误认为修饰符已生效。

## SSR 下这条为什么不适用 / 实际观察到什么

服务端没有交互事件，`v-model.trim` 和 `v-model.number` 不会在 SSR 期间转换输入。本例先渲染初始模型值，再单独模拟输入更新：字符串先 trim，数字由输入字符串转换；因此 HTML 保留初始值，而 JS 输出展示转换结果。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-015-form-modifiers
```
