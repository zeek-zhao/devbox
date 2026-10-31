# C++ 文本索引器骨架

高性能文本索引器：用 mmap 读文件、建立倒排索引、按词查询，并提供基准计时。

从 `cpp/project/` 执行以下命令：

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j
./build/devbox-cpp-project /path/to/file.txt alpha
ctest --test-dir build --output-on-failure
./build/bench_index /path/to/file.txt alpha
```

## 分词规则

连续的 ASCII 英文字母和数字组成一个词；空白、标点及其他字节都是分隔符。索引和查询都会把 ASCII 大写字母转成小写。查询参数应是一个词。同一行中的重复词只会产生一个行号；输出保留原始行内容，行号从 1 开始。

## 用了哪些知识点

- 使用 POSIX `mmap` 映射输入文件，避免用 `ifstream` 全量读取。
- 扫描文本建立“词 → 行号列表”的倒排索引，并按行号顺序查询。
- 用 RAII 管理映射和文件描述符，并在索引构建完成后释放映射。
- 使用 CMake、断言测试和 stderr 基准计时。

完整覆盖表见 [COVERAGE.md](COVERAGE.md)，会随用例铺开增长。

## 在 runtime 镜像里怎么验

```bash
bash check-runtime.sh
```
