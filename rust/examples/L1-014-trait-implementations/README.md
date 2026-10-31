# L1-014-trait-implementations

<!-- coverage: pending -->

## 考点
对应 KP-RS-L1-14：定义 trait、实现必需方法，并复用 trait 的默认方法。
看到两种类型通过同一 trait 接口产生各自内容，并使用共享默认摘要，说明实现满足契约。

## 易错点
会漏实现必需方法而无法编译，或在默认方法中假定不存在的字段；将共享行为放入 trait 方法并显式提供必要实现。
默认方法只通过必需方法访问类型能力，不依赖具体实现的字段布局。

## 延伸
为文档格式化器和索引器定义共同接口，让不同类型实现必要的名称或内容方法。
把通用摘要逻辑留在 trait 中，减少重复实现。

## 复现
TAG=latest scripts/run-example.sh rust L1-014-trait-implementations
