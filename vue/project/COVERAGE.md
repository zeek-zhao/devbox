# Vue project coverage

Only examples implemented by the project are listed here. Exemptions and their project-specific
reasons live in the corresponding example README.

| 用例ID | 落点 | 说明 |
|---|---|---|
| L0-hello | src/ssr/render.js:13 | 服务端将 Vue 应用渲染为 HTML，并供 smoke 检查。 |
| L1-001-setup-basics | src/components/app-factory.js:31 | 页面 setup 暴露响应式状态和操作。 |
| L1-002-ref-vs-reactive | src/store/todos.js:5 | 待办列表使用 reactive，草稿使用 ref。 |
| L1-003-computed-caching | src/store/todos.js:8 | 未完成数量由 computed 从列表派生。 |
| L1-004-watch-vs-watcheffect | src/store/todos.js:13 | watchEffect 追踪未完成数量并同步标题。 |
| L1-005-props-one-way | src/components/app-factory.js:15 | 待办行通过只读 todo prop 接收父组件数据。 |
| L1-006-emits-declare | src/components/app-factory.js:17 | 行组件声明 toggle 和 remove 事件。 |
| L1-007-v-model-expand | src/components/TodoApp.vue:36 | 输入框通过 v-model 双向绑定草稿。 |
| L1-008-slots | src/components/app-factory.js:80 | 根 render 函数向页面传入 footer 插槽。 |
| L1-009-provide-inject | src/components/app-factory.js:20 | 行组件从祖先注入请求级 store。 |
| L1-010-lifecycle-order | src/components/app-factory.js:49 | 客户端 mount/unmount 生命周期更新 hydration 状态。 |
| L1-011-template-refs | src/components/TodoApp.vue:37 | 输入元素 ref 在更新后用于聚焦。 |
| L1-012-vif-vs-vshow | src/components/TodoApp.vue:38 | 路由区块用 v-if，空状态用 v-show。 |
| L1-013-vfor-key | src/components/TodoApp.vue:39 | todo 列表使用稳定的 todo.id 作为 key。 |
| L1-014-class-style-binding | src/components/TodoItem.vue:15 | 完成状态绑定行项目 class。 |
| L1-015-form-modifiers | src/components/TodoApp.vue:40 | v-model.trim 清理输入草稿。 |
| L1-016-ssr-basic | src/ssr/render.js:6 | 每个请求创建 SSR 应用。 |
| L1-017-render-function | src/components/app-factory.js:78 | 使用 Vue.h 创建根 vnode。 |
| L1-018-nexttick | src/components/app-factory.js:41 | Vue 更新 DOM 后再聚焦输入框。 |
| L2-002-sfc-template-compile | src/components/app-factory.js:70 | Vue runtime compiler 编译页面 SFC 模板。 |
| L2-003-multifile-modules | src/app.js:6 | store、router 和组件由独立模块组合。 |
| L2-004-unit-test-harness | test/smoke.sh:27 | smoke 对真实 SSR 响应断言，失败时非零退出。 |
| L2-006-package-exports | src/server.js:9 | package.json 将服务端设为包的唯一公开入口。 |
| L2-007-env-config | src/server.js:10 | PORT 环境变量配置监听端口。 |
| L3-001-proxy-reactivity | src/store/todos.js:5 | Vue reactive 通过代理追踪待办列表状态。 |
| L3-002-effect-scheduler | src/store/todos.js:13 | watchEffect 由 Vue 的响应式调度器触发。 |
| L3-003-hydration-mismatch | src/ssr/hydrate.js:6 | 水合客户端使用与 SSR 相同种子和路由创建的应用。 |
| L3-005-composable-reuse | src/store/todos.js:4 | SSR 与浏览器复用 store factory，各自创建隔离状态。 |
| L3-011-theme-tokens | src/styles.css:2 | 页面消费共享颜色和间距 CSS 令牌。 |
| L3-012-render-perf-baseline | src/perf/baseline.js:11 | 对固定 1000 条列表做真实 SSR 渲染观测。 |
