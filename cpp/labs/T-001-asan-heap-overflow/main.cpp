// T-001-asan-heap-overflow 练习现场（有缺陷代码，勿模仿）。
// 缺陷 1：heap-buffer-overflow —— for 循环写成 i <= n，i == n 时越过 new[] 边界多写 4 字节；
// 缺陷 2：memory leak —— leaked 分配后从未释放（大小可由 argv[1] 覆盖，默认 8 字节）。
// 本镜像（glibc 2.39）实测：无工具构建并非沉默——4 字节越界踩坏相邻 chunk 元数据，
// 程序死在下游的 glibc malloc 断言（症状位置与病因相距甚远）；ASan 构建则直接报
// heap-buffer-overflow；valgrind（跑无工具构建）报 Invalid write + definitely lost。
#include <cstdlib>
#include <cstring>
#include <iostream>

int main(int argc, char** argv) {
    std::cout << "run: start" << std::endl; // 执行标记：证明二进制真的被跑过（素材 S-06）
    const int leak_size = (argc > 1) ? std::atoi(argv[1]) : 8;
    char* leaked = new char[leak_size]; // 缺陷 2：从不 delete[]
    std::memset(leaked, 'A', static_cast<size_t>(leak_size));

    const int n = 10;
    int* buf = new int[n];         // 40 字节
    for (int i = 0; i <= n; ++i) { // 缺陷 1：i == n 越界写 4 字节
        buf[i] = i;
    }
    int sum = 0;
    for (int i = 0; i < n; ++i) {
        sum += buf[i];
    }
    std::cout << "sum=" << sum << " leak_tag=" << leaked[0] << "\n";
    delete[] buf; // leaked 故意不释放
    return 0;
}
