# L1-004-string-pool

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-04：字符串不可变，字面量驻留不代表所有同内容字符串身份相同。
相同字面量身份相同、新建字符串身份不同而 `intern` 后相同，且 `concat` 返回新值，即掌握此 KP。

## 易错点
修改结果会丢失，因为 `concat` 不会原地修改字符串。
接收它的返回值；内容比较用 `equals`，不要依赖字符串池的身份关系。

## 延伸
观察规范化词项如何通过返回新字符串表达转换，并比较显式驻留的适用边界。
用不可变字符串安全地共享原始文本与转换结果。

## 复现
TAG=latest scripts/run-example.sh java L1-004-string-pool
