# L1-015-generic-bounds


## 考点
对应 KP-RS-L1-15：以 trait bound 和 `where` 子句约束泛型类型能力。
看到同一个泛型函数处理两种实现该 trait 的类型，说明约束描述了所需接口。

## 易错点
会让泛型函数调用未声明约束的方法而编译失败；把实际使用的 trait 能力写入参数约束或 `where` 子句。
从函数体实际调用的方法反推必需的 trait bound，避免隐藏前提。

## 延伸
为通用排序和查询辅助函数分别声明比较、格式化等实际需求的 trait 约束。
组合多个类型参数时用 `where` 子句清晰列出每项能力。

## 复现
TAG=latest scripts/run-example.sh rust L1-015-generic-bounds
