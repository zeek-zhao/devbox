<!-- coverage: pending -->

# L1-002-ref-vs-reactive

## 考点

在 JavaScript 中通过 `.value` 读写 `ref`，直接读写 `reactive` 对象属性，并用 `isRef` 区分两者。

## 易错点

`ref` 仅在模板中自动解包；普通 JavaScript 代码必须访问 `.value`。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-002-ref-vs-reactive
```
