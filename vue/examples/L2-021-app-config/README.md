# L2-021-app-config

## 考点

`globalProperties` 提供模板全局属性，`compilerOptions.delimiters` 改变运行时模板插值定界符，`errorHandler` 是应用级错误处理入口。

## 易错点

编译选项需在模板首次编译前设置；`errorHandler` 应记录或处理错误，不能把错误当作成功结果吞掉。

## 延伸

应用级配置适合跨组件共享的全局能力；局部规则优先放在组件或 composable 中。

## 复现

```bash
TAG=local scripts/run-example.sh vue L2-021-app-config
```
