<!-- coverage: pending -->

# L1-009-provide-inject

## 考点

祖先组件通过 `provide` 提供值，孙子组件通过 `inject` 直接获取；中间组件不需要逐层转发。

## 易错点

普通 provide 值本身不是响应式状态；若需要跨层响应式更新，应提供 ref 等响应式值。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-009-provide-inject
```
