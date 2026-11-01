# L1-011-template-refs

## 考点

模板把 ref 绑定到元素；用例检查 SSR 后 ref 值。此环境没有 DOM，template ref 保持为 `null`。

## 易错点

不要在 SSR 中假定模板 ref 指向真实 DOM 元素。

## SSR 下这条为什么不适用 / 实际观察到什么

服务端没有 DOM，也不执行 `onMounted`，所以无法读取元素节点。实际 HTML 正常生成，但 setup 中的 template ref 仍为 `null`；这正是此用例要观察的差异。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-011-template-refs
```
