<!-- coverage: pending -->

# L2-002-sfc-template-compile —— 验证模板编译产物的确定性

## 考点

- 通过 `parse` 取得 SFC 模板，再交给 `compileTemplate`。
- 在同一输入和选项下比较两份完整编译产物。

## 为什么这么写

不固定断言编译器生成代码的具体内容；内部变量名和辅助代码可能随 Vue 版本变化，而同版本重复编译应当完全一致。

## 易错点

- 两次编译必须共享相同的文件名、id 和模板内容。
- 不能只比较产物长度；本例比较完整字符串。

## 运行

```bash
TAG=latest scripts/run-example.sh vue L2-002-sfc-template-compile
```
