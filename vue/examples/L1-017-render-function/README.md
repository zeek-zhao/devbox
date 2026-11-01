# L1-017-render-function

## 考点

使用 `h('div', { class: 'a' }, [...])` 创建 vnode，并由 SSR 转成 HTML。

## 易错点

`h` 的第二个参数是 props；有 props 时 children 放第三个参数。字符串 children 不能误当 props。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-017-render-function
```
