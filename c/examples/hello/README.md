<!-- coverage: pending -->

# hello —— C 语言冒烟用例

## 考点

用 `gcc -std=c17 -Wall -Wextra -Werror` 编译并运行，验证三件事：

1. **C17 标准可用**：`-std=c17` 而不是默认的 gnu17，杜绝 GNU 扩展悄悄混进来。
2. **严格警告可用**：`-Wall -Wextra -Werror` 三件套一起生效。C 的很多坑（隐式函数声明、
   有符号/无符号比较、未使用参数）只有开警告才暴露，只有 `-Werror` 才保证它们被当回事。
3. **手动内存管理能跑通**：`malloc` 拿 100 个 `int`，累加后 `free` 掉。

## 为什么 C 没有自己的镜像

C 和 C++ 共用同一套工具链 —— `gcc` / `g++` / `clang` 全都来自
[`images/scripts/install/cpp.sh`](../../../images/scripts/install/cpp.sh)。
单独给 C 建一层只会让 `docker inspect` 把同一个 2.2 GB 重复报一遍。
语言到镜像的映射写在 [`images/lang-images.tsv`](../../../images/lang-images.tsv)，
`scripts/run-example.sh` 和 `scripts/fmt.sh` 都读它。

## 与 C++ 的边界

C 只考 **ISO C17 + libc**，一个 POSIX 头文件都不用。理由：

- POSIX 那套（`fork`、`socket`、`epoll`、信号）在容器里跑，输出顺序、pid、errno
  都受环境影响，`expected.txt` 没法固定；
- C++ 那边已经有并发/线程专题，C 再考 `pthread` 是重复覆盖；
- 一旦开 `_GNU_SOURCE`，`-Werror` 就压不住 GNU 扩展了。

C 真正独有的考点在**手动内存 + 指针算术 + 位运算 + 结构体布局 + 预处理器**。

## 运行

```bash
TAG=latest scripts/run-example.sh c hello
```

## 易错点

- `-Wall -Wextra` 下 `printf("%zu", strlen(...))` 必须用 `%zu` 而不是 `%d`，
  后者在 64 位上是未定义行为，而且 `-Wformat` 会直接报错。
- `malloc` 的返回值必须判空，虽然 Linux 上 overcommit 让它在小分配时几乎不会返回 NULL，
  但把「几乎不会」当「不会」是 C 里最常见的坏习惯。
