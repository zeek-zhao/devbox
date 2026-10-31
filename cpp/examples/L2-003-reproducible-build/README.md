# L2-003-reproducible-build

<!-- coverage: pending -->

## 考点
对应 KP-L2-03：显式指定 C++20、警告选项和路径映射，并在两个干净输出目录分别构建。
看到两次构建的 SHA-256 完全相同且输出 `identical: yes`，即说明构建可复现。

## 易错点
依赖编译器默认标准或把绝对源码路径写入产物，会让不同环境的构建结果不一致。
显式固定标准与选项，并用 `-ffile-prefix-map` 将源码目录映射为稳定相对路径。

## 延伸
可继续加入调试信息、归档时间戳和依赖版本，分析各自如何影响可复现性。
再使用独立构建环境验证相同源码和工具链配置能否产生相同产物哈希。

## 复现
TAG=latest scripts/run-example.sh cpp L2-003-reproducible-build
