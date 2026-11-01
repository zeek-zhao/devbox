<!-- coverage: pending -->

# L1-014-class-style-binding

## 考点

分别以对象、数组和字符串绑定 class，并用 SSR 输出观察规范化后的 class/style 属性。

## 易错点

数组中的 falsy 值会被忽略；对象中值为 false 的 class 不会出现在结果中。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-014-class-style-binding
```
