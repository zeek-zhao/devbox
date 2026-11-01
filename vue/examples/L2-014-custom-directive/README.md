<!-- coverage: exempt 表单只用原生 input、checkbox 和按钮行为，应用没有需要封装的 DOM 聚焦/测量等指令逻辑。 -->

# L2-014-custom-directive —— 观察自定义指令的 SSR 降级

## 考点

- 用 `withDirectives` 将真实的 `v-focus` 指令绑定到输入元素。
- 检查浏览器生命周期钩子和 SSR HTML 中的指令痕迹。

## 为什么这么写

浏览器挂载后 `mounted` 可以访问 DOM 并聚焦输入框；SSR 没有 DOM，因此不会调用该钩子，HTML 也不会留下 `v-focus` 属性。若要在 SSR 输出属性，应实现 `getSSRProps`。

## 易错点

- `mounted` 是客户端生命周期，不是 SSR 指令钩子。
- SSR 属性应由 `getSSRProps` 返回，不能期待指令名自动写入 HTML。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-014-custom-directive
```
