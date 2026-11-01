# L1-001-setup-basics

## 考点

`setup()` 返回的对象会成为模板可见的数据。SSR 输出 `<p>hello from setup</p>`，验证模板读到了 `msg`。

## 易错点

`setup()` 返回的对象不是组件实例 `this`；模板可以直接使用返回对象中的属性。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-001-setup-basics
```
