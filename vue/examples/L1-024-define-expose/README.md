coverage: exempt 项目使用 JavaScript 组件工厂而不是 `<script setup>`；其 SSR 组件实例也没有父组件模板 ref 可验证公开代理。

# L1-024-define-expose

## 考点

`compileScript` 将 `defineExpose` 编译为仅暴露指定属性的运行时调用。

## 易错点

`defineExpose` 是 `<script setup>` 编译宏；普通 `setup()` 组件不调用它，也不会自动获得相同的公开面。

## 延伸

客户端父组件通过模板 ref 调用子组件公开方法时，应只暴露稳定且必要的 API。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-024-define-expose
```
