coverage: exempt 项目依赖 Vue SSR renderer 输出 HTML，业务目标不是原生小程序、Canvas 或其他自定义宿主节点树。

# L2-022-custom-renderer

## 考点

`createRenderer` 通过宿主操作接口把 vnode 转换为纯 JavaScript 树，无需浏览器 DOM。

## 易错点

自定义 renderer 必须实现节点创建、插入、移除和属性更新等宿主操作；`h()` 本身不负责挂载。

## 延伸

同一套 Vue 组件模型可复用于终端、Canvas 或原生平台，但每个宿主都需要自己的 renderer。

## 复现

```bash
TAG=local scripts/run-example.sh vue L2-022-custom-renderer
```
