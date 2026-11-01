# L1-025-inject-default

## 考点

缺少 provider 时 `inject` 使用默认 ref；提供 ref 时注入者共享同一个响应式引用。

## 易错点

注入普通对象再解构其原始字段不会自动建立响应式依赖；传递 ref 可保留响应式连接。

## 延伸

请求级配置或 store 可通过 provide/inject 传递，默认值可为独立组件测试提供安全回退。

## 复现

```bash
TAG=local scripts/run-example.sh vue L1-025-inject-default
```
