# L1-006-numeric-boxing

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-06：整数除法、显式窄化、溢出检查及包装类型拆箱空值风险。
看到整除为 2、窄化为 -126、`addExact` 检出溢出、空包装值先检查，以及直接拆箱时抛 `NullPointerException`，即掌握此 KP。

## 易错点
计数可能回绕或拆箱失败，因为普通整数运算不自动报溢出且包装值可为空。
用 `Math.addExact` 检查溢出，并在拆箱前显式检查空值；漏检时拆箱这一步就会抛 NPE，而不是静默得到 0。

## 延伸
为文档计数与偏移边界选择合适数值类型，并明确转换与溢出的业务策略。
在可空输入边界检查包装值，再进行基本类型运算。

## 复现
TAG=latest scripts/run-example.sh java L1-006-numeric-boxing
