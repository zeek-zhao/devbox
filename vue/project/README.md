# Vue Todo 毕业项目

这是一个不经过打包器的 Vue 3 待办应用。Node 直接运行 CommonJS 服务端；两个 `.vue`
文件保留为组件模板，Vue 自带的完整运行时编译器在 SSR 和浏览器启动时将模板编译为
render 函数。`package.json` 只依赖 `vue`，不使用 Vite、webpack 或测试框架。

## 模块划分

- `src/store/todos.js`：每次请求创建独立的 `reactive` 列表、`ref` 草稿、
  `computed` 未完成数和 `watchEffect` 页面标题。
- `src/router/router.js`：路由表、`:id` 参数解析、未知路由回退守卫和浏览器导航。
- `src/components/*.vue`：待办页面与行项目的模板；`app-factory.js` 绑定 props、
  emits、provide/inject、具名 slot 和生命周期。
- `src/ssr/`：`render.js` 封装 `createSSRApp` / `renderToString`，
  `hydrate.js` 在客户端把同一应用挂载到 SSR DOM；浏览器入口为 `src/client.js`。
- `src/perf/baseline.js`：SSR 渲染 1000 条待办，只向 stderr 记录耗时并核对渲染条数，
  不断言任何绝对耗时。
- `src/styles.css`：基础样式与可复用 CSS 主题令牌。

## SSR 数据流

每个 HTTP 请求先依据 URL 创建新的 store 和 router，再读取两个 SFC 的 template，
用 Vue runtime compiler 编译组件，最后经 `src/ssr/render.js` 输出 HTML。
页面同步输出初始路由，浏览器加载同一份 Vue runtime、状态/路由模块和模板，使用相同
种子数据创建同构应用；`src/ssr/hydrate.js` 的 `hydrate()` 在现有服务端 DOM 上执行 hydration。

## 运行与观察 hydration

```bash
npm install
node src/server.js
# 另一个终端
curl -s http://localhost:18081/
```

可用 `PORT=18082 node src/server.js` 指定端口；`npm run smoke` 会启动服务、请求页面、
检查 SSR 待办并发送 SIGTERM 等待服务退出。浏览器中打开页面后，在开发者控制台检查
`window.__TODO_HYDRATED__`（hydration 完成后为 `true`），并通过添加/勾选待办观察现有
SSR 节点变为响应式交互界面。服务端 HTML 与 hydration 后内容使用同一份初始数据。

性能基线运行方式：

```bash
npm run perf
```

输出格式为 `SSR baseline: rendered 1000 todos in <elapsed> ms (observation only)`。
毫秒数随机器和负载变化，**这是基线观测，不是断言**。

## 覆盖落点自证

「真接入」指代码路径实际执行此知识点，且在真实落点的非 Markdown 源文件中有对应注释。
豁免理由保存在各自的 `vue/examples/<id>/README.md`；`COVERAGE.md` 只登记真接入用例。

| 用例ID | 类别 | 落点或豁免理由 |
|---|---|---|
| hello | 真接入 | `src/ssr/render.js:13` |
| L1-001-setup-basics | 真接入 | `src/components/app-factory.js:31` |
| L1-002-ref-vs-reactive | 真接入 | `src/store/todos.js:5` |
| L1-003-computed-caching | 真接入 | `src/store/todos.js:8` |
| L1-004-watch-vs-watcheffect | 真接入 | `src/store/todos.js:13` |
| L1-005-props-one-way | 真接入 | `src/components/app-factory.js:15` |
| L1-006-emits-declare | 真接入 | `src/components/app-factory.js:17` |
| L1-007-v-model-expand | 真接入 | `src/components/TodoApp.vue:36` |
| L1-008-slots | 真接入 | `src/components/app-factory.js:80` |
| L1-009-provide-inject | 真接入 | `src/components/app-factory.js:20` |
| L1-010-lifecycle-order | 真接入 | `src/components/app-factory.js:49` |
| L1-011-template-refs | 真接入 | `src/components/TodoApp.vue:37` |
| L1-012-vif-vs-vshow | 真接入 | `src/components/TodoApp.vue:38` |
| L1-013-vfor-key | 真接入 | `src/components/TodoApp.vue:39` |
| L1-014-class-style-binding | 真接入 | `src/components/TodoItem.vue:15` |
| L1-015-form-modifiers | 真接入 | `src/components/TodoApp.vue:40` |
| L1-016-ssr-basic | 真接入 | `src/ssr/render.js:6` |
| L1-017-render-function | 真接入 | `src/components/app-factory.js:78` |
| L1-018-nexttick | 真接入 | `src/components/app-factory.js:41` |
| L2-002-sfc-template-compile | 真接入 | `src/components/app-factory.js:70` |
| L2-003-multifile-modules | 真接入 | `src/app.js:6` |
| L2-004-unit-test-harness | 真接入 | `test/smoke.sh:27` |
| L2-006-package-exports | 真接入 | `src/server.js:9` |
| L2-007-env-config | 真接入 | `src/server.js:10` |
| L3-001-proxy-reactivity | 真接入 | `src/store/todos.js:5` |
| L3-002-effect-scheduler | 真接入 | `src/store/todos.js:13` |
| L3-003-hydration-mismatch | 真接入 | `src/ssr/hydrate.js:6` |
| L3-005-composable-reuse | 真接入 | `src/store/todos.js:4` |
| L3-011-theme-tokens | 真接入 | `src/styles.css:2` |
| L3-012-render-perf-baseline | 真接入 | `src/perf/baseline.js:11` |

真接入 30 条 / 豁免 16 条，合计 46 条。

真接入 30 条 / 豁免 16 条，合计 46 条。
