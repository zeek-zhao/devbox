# L1-031-function-callbacks

<!-- coverage: pending -->

## 考点
对应 KP-L1-31：把函数指针、函数对象和捕获 lambda 作为回调传入接口。
看到三种回调都按约定处理输入并产生各自结果，即可验证掌握了回调调用方式。

## 易错点
回调签名不匹配时不能传给函数指针接口；传入前要核对参数和返回类型。
捕获 lambda 保存了状态，不能直接转换为普通函数指针；用可调用对象接口接收它。

## 延伸
可以将回调扩展为接收多个参数，比较其函数类型与模板接口的约束。
也可以用 `std::function` 类型擦除回调，再权衡灵活性与运行时开销。

## 复现
TAG=latest scripts/run-example.sh cpp L1-031-function-callbacks
