# L3-004-custom-marshal-json


## 考点
对应 KP-GO-L3-04：为类型实现 `MarshalJSON` 并明确稳定的 JSON 字段。
固定输入编码为逐字一致的 JSON，标准 `Unmarshal` 又读回预期值，说明自定义编码生效。

## 易错点
在 `MarshalJSON` 内递归编码自身会无限递归；定义不同的底层别名类型后再委托标准编码器。
本例将别名转换后只委托编码一次，避免再次调用原类型的自定义方法。

## 延伸
为索引元数据定义版本化 JSON schema，并测试字段新增和缺省值兼容性。
为自定义编码增加非法输入的显式错误路径和对应断言。

## 复现
TAG=latest scripts/run-example.sh go L3-004-custom-marshal-json
