<!-- coverage: exempt 静态分析器是额外诊断工具，不是服务本身行为。 -->

# L2-011-gcc-analyzer —— 用 GCC 静态分析发现泄漏路径

## 考点

- `-fanalyzer` 在编译阶段追踪分配到函数返回的资源路径。
- 只有出现 leak 类诊断才把静态分析判为命中。

## 为什么这么写

被分析的程序只有一次小分配和一条返回路径，输出仅反映诊断类别，不依赖 GCC 版本相关的完整告警文本。

## 易错点

- 静态分析诊断在编译器 stderr，不是程序运行时输出。
- 只检查编译退出码会漏掉默认不提升为错误的 analyzer 告警。

## 运行

```bash
TAG=latest scripts/run-example.sh c L2-011-gcc-analyzer
```
