<!-- coverage: exempt 服务端每个请求都创建独立 store，并通过 provide 注入组件树；全局插件状态会削弱请求隔离且没有额外全局属性需求。 -->

# L2-015-plugin-install —— 在 SSR 前安装全局属性插件

## 考点

- 通过插件 `install` 写入 `app.config.globalProperties`。
- 在组件渲染过程中读取该属性，并验证 SSR 输出。

## 为什么这么写

先创建应用并调用一次 `app.use(plugin)`，再交给 `renderToString`；这样组件代理能在渲染时访问插件提供的 `$badge`。

## 易错点

- 必须在开始 SSR 前安装插件。
- `app.use` 按插件对象去重；重复调用不会再次安装，也不能依赖重复安装产生副作用。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-015-plugin-install
```
