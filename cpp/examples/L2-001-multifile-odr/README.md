# L2-001-multifile-odr

<!-- coverage: pending -->

## 考点
对应 KP-L2-01：声明放在受头文件卫士保护的头文件中，定义分布在两个 `.cpp` 翻译单元。
看到两个翻译单元的函数都成功链接并输出结果，且头文件重复包含不报错，即掌握本点。

## 易错点
把非 `inline` 函数定义写进被多处包含的头文件，会导致重复定义并在链接时报错。
用头文件卫士保护声明，并将每个非 `inline` 定义只放在一个 `.cpp` 文件中。

## 延伸
可继续比较 `inline` 函数、模板定义与普通函数定义放入头文件时的 ODR 规则。
再把模块拆分为库 target，观察公开头文件和实现文件的链接依赖。

## 复现
TAG=latest scripts/run-example.sh cpp L2-001-multifile-odr
