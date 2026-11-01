# L1-038-deref-coercion

## 考点
对应 KP-RS-L1-38：Deref 与解引用强制转换。&MyBox<String> 可作为 &str 传给函数，展示自定义解引用强转链

## 易错点
把 `Deref` 当作任意类型转换来用，会误以为它能改变值或获得所有权；解引用强制转换只在需要引用时沿 `Target` 链调整借用类型。自定义包装器若没有合理、直观的目标类型就不该实现 `Deref`，否则方法和隐式转换会让 API 难以预测。

## 延伸
项目的 `src/lib.rs` 通过 `Arguments::command` 显式调用 `String::as_str`，并没有定义自定义 `Deref` 包装器。CLI 目前没有真正需要自定义解引用强转的地方，本例只作引用类型转换能力练习。

## 复现
TAG=latest scripts/run-example.sh rust L1-038-deref-coercion
