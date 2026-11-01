# Vue project coverage

This project covers all 74 example directories under `vue/examples/`. Exemptions and their
project-specific reasons live in the corresponding example README.

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
| L1-019-computed-setter | src/components/app-factory.js | 表单 computed setter 将 v-model 写回 store 源 ref。 |
| L1-020-watch-flush | src/store/todos.js | 标题 watcher 使用 post flush 并等待响应式更新队列。 |
| L1-021-dynamic-component | src/components/TodoApp.vue | 路由状态通过 component is 选择 SSR 标题标签。 |
| L1-023-with-modifiers | src/components/TodoApp.vue | 导航点击阻止默认行为并停止冒泡。 |
| L1-025-inject-default | src/components/app-factory.js | 行组件注入请求 store，缺少 provider 时使用 ref 默认值。 |
| L1-026-to-refs-props | src/components/app-factory.js | `toRefs(props)` 保持 todo 属性的响应式连接。 |
| L1-028-vhtml-escape | src/components/TodoItem.vue | 待办文本使用插值转义，不走 v-html。 |
| L2-002-sfc-template-compile | src/components/app-factory.js:70 | Vue runtime compiler 编译页面 SFC 模板。 |
| L2-018-runtime-compiler | src/components/app-factory.js | 完整版 Vue 导出的 `compile` 在项目中编译模板。 |
| L2-020-emits-validation | src/components/app-factory.js | 组件 emits validator 校验待办事件的字符串 ID。 |
| L2-021-app-config | src/app.js | 应用配置提供全局属性与错误处理器，模板定界符传给 compiler-dom。 |
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
| L3-013-effect-scope | src/store/todos.js | 将请求级 watcher 收入 effectScope 并在 SSR 结束时停止。 |
| L3-014-shallow-markraw | src/router/router.js | 路由快照浅层追踪并标记为 raw，按整体替换。 |
| L3-015-custom-ref | src/store/todos.js | 自定义草稿 ref 明确调用 track 与 trigger。 |
| L3-016-track-trigger-debug | src/store/todos.js | watcher 调试钩子记录依赖追踪和触发操作。 |
| L3-017-error-boundary | src/components/app-factory.js | 子组件错误由父组件边界记录并切换降级区域。 |
| L3-018-ssr-prefetch | src/components/app-factory.js | 服务端渲染前等待请求待办数据完成预取。 |
| L3-019-drag-reorder | src/store/todos.js | 行操作按确定性列表操作将待办向前重排。 |
| L3-023-leak-audit | src/server.js | SSR 请求 finally 停止 store scope，避免 watcher 泄漏。 |
