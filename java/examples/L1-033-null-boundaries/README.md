# L1-033-null-boundaries

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-33：区分空引用解引用、可空比较与入口非空约束。
看到直接调用抛 NPE、Objects.equals 安全给出 true/false、requireNonNull 给出固定消息，即掌握边界。

## 易错点
缺失值会引发意外 NPE，因为直接解引用；允许空值时用 Objects.equals。
禁止空值时在入口调用 requireNonNull，尽早以明确契约拒绝无效输入。

## 延伸
为查询参数区分必填与可选字段，并在入口统一验证必填值。
研究 Optional 适合表达的返回值边界，以及它不能替代所有 null 检查的场景。

## 复现
TAG=latest scripts/run-example.sh java L1-033-null-boundaries
