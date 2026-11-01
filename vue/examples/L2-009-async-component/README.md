<!-- coverage: pending -->

# L2-009-async-component —— 等待异步组件加载后进行 SSR

## 考点

- 用 `defineAsyncComponent` 声明异步组件加载器。
- 观察渲染前未加载、SSR 完成后已加载且出现组件 HTML。

## 为什么这么写

加载器在 Promise 微任务中更新真实状态；以 `renderToString` 的结果作为完成边界，验证 SSR 会等待异步组件而不是输出占位内容。

## 易错点

- 只创建异步组件并不等于已加载；加载发生在渲染过程中。
- 不等待 `renderToString` 就检查输出，会在组件就绪前结束用例。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-009-async-component
```
