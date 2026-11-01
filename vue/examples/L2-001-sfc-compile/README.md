<!-- coverage: pending -->

# L2-001-sfc-compile —— 编译 SFC 中的 setup 脚本

## 考点

- 将 `.vue` 源码字符串交给 `parse` 和 `compileScript`。
- 从实际编译产物中提取 setup 声明，验证编译器确实处理了脚本。

## 为什么这么写

源码放在临时 JavaScript 文件的模板字符串里，而不是创建 `.vue` 文件；镜像没有 SFC 加载器，直接调用编译器 API 才能验证编译本身。只打印被测声明片段，避免输出依赖编译器版本的辅助代码。

## 易错点

- `compileScript` 接收 `parse` 返回的 `descriptor`，不是源字符串。
- 不能只打印固定文本；片段必须从编译结果中提取，不匹配时应失败。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-001-sfc-compile
```
