<!-- coverage: exempt 运行不依赖调试宏，避免关闭追踪改变参数求值。 -->

# L3-023-debug-build-macros —— 验证关闭追踪时没有参数副作用

## 考点

- 用 `-DDEVBOX_TRACE=1` 和 `=0` 编译同一份程序。
- 追踪关闭时宏不求值参数表达式，开启时产生可见追踪输出。

## 为什么这么写

将 `++counter` 作为宏参数，直接观察关闭配置是否仍执行了表达式。

## 易错点

- 关闭宏展开成 `(void)0`，不能展开成仍会求值参数的空函数调用。
- 两种构建必须使用独立输出文件，避免互相覆盖。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-023-debug-build-macros
```
