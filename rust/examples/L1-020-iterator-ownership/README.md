# L1-020-iterator-ownership


## 考点
对应 KP-RS-L1-20：区分 `iter`、`iter_mut` 和 `into_iter` 的借用与所有权语义。
看到只读借用后集合仍可访问、可变借用修改元素、消费迭代器取得元素后结束原绑定使用，说明掌握了所有权流转。

## 易错点
会在 `into_iter` 后继续使用集合，因为元素所有权已转出；只读遍历用 `iter`，需要逐项取得所有权时才消费集合。
在消费集合前完成对原集合的读取，之后只使用迭代器取得的元素。

## 延伸
在倒排表读取阶段使用 `iter`，需要转移结果时使用 `into_iter`。
比较 `iter_mut` 对元素的可变借用与消费迭代器取得所有权的区别。

## 复现
TAG=latest scripts/run-example.sh rust L1-020-iterator-ownership
