# L1-003-constants-iota


## 考点
对应 KP-GO-L1-03：观察同一 const 组中的状态值递增，以及新组从零开始。
连续且可预测的枚举值说明理解 `iota` 的组内作用域。

## 易错点
`iota` 在声明组内按行递增，另起 const 组会重置。
把状态集中声明并显式设置首项，避免编号起点含糊。

## 延伸
为文档状态或查询模式定义具名常量，并集中维护其数值含义。
使用 switch 按具名状态分支处理业务状态。

## 复现
TAG=latest scripts/run-example.sh go L1-003-constants-iota
