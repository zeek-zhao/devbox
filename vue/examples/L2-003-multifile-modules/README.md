# L2-003-multifile-modules —— 用相对路径组织多文件模块

## 考点

- 由入口模块加载组件模块，再由组件模块加载工具模块。
- 使用 Vue SSR 渲染模块组合的真实结果。

## 为什么这么写

三个 JavaScript 文件都在独立临时目录中，通过相对路径 `require` 建立依赖关系。`NODE_PATH` 只帮助解析全局安装的包，不负责相对路径。

## 易错点

- 相对路径必须以 `./` 开始。
- `renderToString` 返回 Promise，入口必须等待渲染完成再输出。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-003-multifile-modules
```
