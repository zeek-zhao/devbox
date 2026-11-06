# E-003-errno-checking

## 现象
fopen 打开不存在的文件返回 nullptr，errno=2（No such file or directory）；
随后一次**成功**的 fopen 并不会清零 errno——它仍报告上一次失败的旧值；
`std::system_error` 可以把 errno 与上下文一起打包成异常。

## 复现
```bash
TAG=latest bash scripts/run-example.sh cpp E-003-errno-checking
```

## 期望输出
```text
fopen missing: errno=2 (No such file or directory)
after success call errno still reports: No such file or directory
fopen /dev/null: ok, errno untouched check skipped
system_error: open missing-dir/file.txt: No such file or directory
system_error: code=2
```

## 为什么
C 标准只承诺「失败时设置 errno」，从不承诺「成功时清零」。所以
`errno = 0; f(); if (errno) ...` 这种先看 errno 的写法会把成功调用后残留的
旧错误当成新失败。正确顺序永远是：先检查返回值（返回值说失败了），
再读 errno（它才告诉你为什么）。现代 C++ 用 `std::system_error(errno,
std::generic_category(), ctx)` 把数字码变成带消息、带上下文的异常对象，
`.code().value()` 仍可编程比较。

## 反例
不看返回值、只凭 `errno != 0` 判断失败（成功路径也会报错）；
或失败后中间插了其他库调用才去读 errno（中间调用可能改写它）；
或用 `perror` 后继续用errno 逻辑分支——perror 只打印不返回状态。

<!-- coverage: exempt 排障示例（错误处理演练），不落入任何毕业项目代码；豁免理由与错误处理章统一归档于 cpp/docs/排查手册.md（M11-DOC-cpp 卡落盘） -->
