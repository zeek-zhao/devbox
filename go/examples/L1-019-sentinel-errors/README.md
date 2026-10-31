# L1-019-sentinel-errors


## 考点
对应 KP-GO-L1-19：函数直接返回包级哨兵错误，调用方识别失败类别。
看到成功查询返回 guide、缺失查询的 errors.Is 为 true 且进入 no results 分支，即掌握哨兵分类。

## 易错点
比较错误字符串会受文案变化影响，让调用方误走分支。
用包级哨兵错误和 errors.Is 判断类别；展示文本不参与业务分类。

## 延伸
在索引查询接口中分别约定未命中与无效文档的哨兵值。
为调用方补充分类分支断言，确认更改提示文案不改变未命中处理策略。

## 复现
TAG=latest scripts/run-example.sh go L1-019-sentinel-errors
