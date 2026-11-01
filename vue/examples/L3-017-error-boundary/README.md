# L3-017-error-boundary

## 考点

父级 `onErrorCaptured` 接收子组件错误；测试随后以捕获状态 SSR 渲染降级内容。

## 易错点

SSR 是单次渲染，错误钩子里的状态变更不会让当前 HTML 自动重渲染；需要使用捕获结果显式输出回退内容。

## 延伸

边界可按组件子树隔离非关键区域，避免单个展示组件错误导致整页不可用。

## 复现

```bash
TAG=local scripts/run-example.sh vue L3-017-error-boundary
```
