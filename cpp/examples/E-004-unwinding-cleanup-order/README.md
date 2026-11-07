# E-004-unwinding-cleanup-order

## 现象
函数内先后构造两个资源对象（conn、tx）后抛异常：栈展开沿构造的**逆序**
调用析构——先 release tx，再 release conn，然后才轮到外层 catch。
正常离开作用域也是同一逆序。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-004-unwinding-cleanup-order
```

## 期望输出
```text
acquire conn
acquire tx
send: start
release tx
release conn
caught: peer reset
acquire a
acquire b
scope: body done
release b
release a
exit: clean
```

## 为什么
栈展开的清理顺序由语言规则保证：已完全构造的局部对象按构造完成的逆序
析构。这意味着「后拿的锁先还、先开的事务后关」这类依赖关系不需要手写
每个分支的清理代码——把获取写成局部对象构造即可，异常路径与正常路径
共用同一套确定顺序。析构期间抛出异常是唯一会破坏这一保证的操作
（展开中再抛 → `std::terminate`），所以析构函数不抛是硬纪律。

## 反例
在 throw 之前手写 `conn.close(); tx.close();` 再 throw：正常路径 return
时析构又会再释放一遍（重复释放）；或者把清理写在 catch 里逐个补——漏一个
中途 return/continue 就泄漏。清理逻辑一旦重复出现，就必然有一份在某个
新分支里被忘掉。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
