coverage: exempt 项目组件由 JavaScript 工厂和 `Vue.compile` 模板组成，没有 `<script setup>` 源文件可供 `compileScript` 提升 props。

# L2-016-script-setup-compile

## 考点

使用 `compileScript` 的 `inlineTemplate` 选项，检查 `defineProps` 声明和模板 render 函数都进入产物。

## 易错点

`defineProps` 是编译宏，不是运行时函数；在普通 JavaScript `setup()` 中不能照搬它。

## 延伸

SFC 构建链可在编译期提升静态 props 声明，减少 setup 阶段的重复工作。

## 复现

```bash
TAG=local scripts/run-example.sh vue L2-016-script-setup-compile
```
