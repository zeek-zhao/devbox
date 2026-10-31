# L1-008-option-values


## 考点
对应 KP-RS-L1-08：`Option<u32>` 明确区分存在的编号与缺失值。
看到 `Some(7)` 输出命中编号、`None` 输出 `missing`，且缺失配置采用显式默认值 `10`，说明能安全处理两种情况。
`match` 列出两个分支；漏掉其中一个分支将无法通过穷尽检查。

## 易错点
会直接取出可能不存在的值而在运行期 panic，因为 `None` 没有可取出的载荷。
用匹配、`if let` 或显式缺省策略处理 `None`；本例的 `unwrap_or` 指定默认值，不是直接 `unwrap`。

## 延伸
在查询未命中时返回 `None`，不要用文档编号 `0` 暗示缺失。
为可选字段逐项决定缺失语义：查询结果保留未命中，展示配置可以使用明确默认值。

## 复现
TAG=latest scripts/run-example.sh rust L1-008-option-values
