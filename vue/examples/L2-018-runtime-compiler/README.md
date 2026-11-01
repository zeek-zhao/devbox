# L2-018-runtime-compiler

## 考点

Vue 完整 CJS 构建能把模板编译为 render 函数；镜像自带的 runtime-only global 构建不生成模板 render 函数。

## 易错点

运行时编译器不是所有 Vue 构建都包含；runtime-only 构建中的 compile 占位不支持模板即时编译。

## 延伸

镜像没有单独安装 `@vue/runtime-core` 包，本例用 Vue 分发包内的 runtime-only 构建验证相同边界；生产项目通常在构建阶段预编译模板。

## 复现

```bash
TAG=local scripts/run-example.sh vue L2-018-runtime-compiler
```
