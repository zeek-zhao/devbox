# L1-033-error-identity

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-33，两次 errors.New 文本相同但错误值不同；包装后的哨兵仍可由 errors.Is 识别。
看到文本相等、身份不相等且哨兵分类成功，即可说明错误比较边界已掌握。

## 易错点
错误文本相同不代表错误值相同，直接比较文本不能可靠表达错误分类。
需要稳定分类时复用哨兵并用 errors.Is，或定义可匹配的自定义错误类型。

## 延伸
为解析、存储等边界定义错误哨兵，让调用方按语义选择恢复或返回。
进一步练习 errors.As 匹配携带结构化信息的自定义错误。

## 复现
TAG=latest scripts/run-example.sh go L1-033-error-identity
