# L2-004-api-javadoc


## 考点
对应 KP-JV-L2-04：公开 API 的参数、返回值和异常契约由 Javadoc 描述。
doclint 成功生成类文档，页面含固定摘要及参数、返回、异常语义，说明源码与文档一致。

## 易错点
文档生成会报错或缺语义，因为标签和签名不一致。
同步维护 @param、@return、@throws 并开启 doclint；生成路径留在临时区且不进入业务输出。

## 延伸
为查询与存储接口补充边界条件、线程安全和异常语义的公开文档。
将 Javadoc 校验纳入干净构建，避免发布与源码不一致的 API 文档。

## 复现
TAG=latest scripts/run-example.sh java L2-004-api-javadoc
