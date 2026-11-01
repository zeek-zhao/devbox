<!-- coverage: exempt 目标运行平台固定为 Linux，无平台分支实现需要。 -->

# L2-004-conditional-compilation —— 通过编译期开关选择实现

## 考点

- `-DDEBUG` 定义宏后选择调试分支。
- 不带开关时走默认分支，两次编译运行都产生可区分的输出。

## 为什么这么写

两个构建使用同一份源码与相同编译选项，唯一差别是预处理宏，便于把输出差异归因于条件编译。

## 易错点

- `#ifdef` 检查的是宏是否定义，不是宏值是否为真。
- 只在某一分支定义变量会使另一种配置编译失败；本例让分支各自完整输出。

## 运行

```bash
TAG=latest scripts/run-example.sh c L2-004-conditional-compilation
```
