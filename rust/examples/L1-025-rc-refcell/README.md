# L1-025-rc-refcell

<!-- coverage: pending -->

## 考点
对应 KP-RS-L1-25：`Rc::clone` 只增加共享所有者，`RefCell` 在运行时检查内部借用。
看到引用计数 1→2→1、冲突借用被安全拒绝、两个持有者都读到 15，说明共享的是同一份数据。

## 易错点
同一时刻取得冲突的 `RefCell` 借用会触发 panic，因为只读与独占写入不能重叠。
用 `try_borrow_mut` 观察冲突而不 panic，缩短守卫作用域，结束只读借用后再写入。

## 延伸
在毕业项目中让单线程的多个查询节点共享可变缓存，克隆句柄而不是复制缓存内容。
把缓存读取和更新拆为短作用域，明确处理运行时借用冲突，避免嵌套回调保留守卫。

## 复现
TAG=latest scripts/run-example.sh rust L1-025-rc-refcell
