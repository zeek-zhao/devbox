coverage: exempt 项目样式存放于共享 `styles.css`，SFC 模板是运行时编译字符串，没有 scoped style 块可编译。

# L2-017-sfc-scoped-css

## 考点

`compileStyle` 为局部选择器追加 scope 属性，并让 `:deep()` 内部选择器穿透组件边界。

## 易错点

scoped CSS 是编译期选择器改写，不是浏览器隔离；`:deep()` 也不会给子节点添加父组件 scope。

## 延伸

组件库可用 scoped 样式约束默认规则，再通过受控的 deep 选择器定制内部第三方组件。

## 复现

```bash
TAG=local scripts/run-example.sh vue L2-017-sfc-scoped-css
```
