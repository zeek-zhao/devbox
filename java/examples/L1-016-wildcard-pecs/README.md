# L1-016-wildcard-pecs


## 考点
对应 KP-JV-L1-16：PECS 用 extends 表示生产者、用 super 表示消费者。
用例读取 extends 源、向 super 目标写入，并以编译探针显示 extends 写入被拒绝。

## 易错点
写入 extends 列表被拒绝，因为真实元素可能是另一 Number 子类；读源用 extends，写目标用 super，别用强转绕过限制。
读取 super 列表时只按 Object 处理；需要写入时保持目标类型边界。

## 延伸
把 `copy` 方法泛型化为 extends 源和 super 目标，复制多个 Number 子类的值。
阅读标准集合 API 中通配符的使用方式，比较读源与写目标的签名。

## 复现
TAG=latest scripts/run-example.sh java L1-016-wildcard-pecs
