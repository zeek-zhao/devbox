<!-- coverage: pending -->

# L2-002-makefile-incremental —— 用依赖关系避免重复构建

## 考点

- Makefile 目标显式依赖源文件，第一次构建生成目标程序。
- 连续执行两次 `make`，第二次依据文件时间戳判断无需重建。

## 为什么这么写

首次构建的命令输出被隔离，只把第二次确实没有执行构建配方这一事实转换成稳定业务输出。

## 易错点

- 忘写目标的源文件依赖会让源文件变化后不触发重建。
- 把可执行目标声明为 `.PHONY` 会让每次调用都重建，破坏增量判断。

## 运行

```bash
TAG=latest scripts/run-example.sh c L2-002-makefile-incremental
```
