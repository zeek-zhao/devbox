# L1-021-dynamic-component

## 考点

`<component :is>` 在运行时解析标签，随后由 SSR 渲染成选定的元素。

## 易错点

动态解析发生在组件渲染阶段；字符串标签会作为元素渲染，而不是从调用者局部变量中查找。

## 延伸

路由视图可通过 `<component :is="...">` 选择已注册组件或标签。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-021-dynamic-component
```
