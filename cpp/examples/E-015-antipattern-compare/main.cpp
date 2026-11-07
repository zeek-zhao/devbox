#include <iostream>
#include <stdexcept>
#include <string>

// 反模式对照：三个最常见的错误处理反模式，与正确写法成对展示。
// 每对输出 ANTI/GOOD 各一行，现象差异一目了然。

// 反模式 1：吞异常——catch 后什么都不做，故障凭空消失。
static void swallow() {
    try {
        throw std::runtime_error("disk full");
    } catch (const std::runtime_error&) {
        // ANTI：空的 catch 块，错误被静默丢弃
    }
    std::cout << "ANTI swallow: caller saw nothing";
}

static void rethrow_up() {
    try {
        throw std::runtime_error("disk full");
    } catch (const std::runtime_error& e) {
        std::cout << "GOOD log: " << e.what() << '\n';
        throw; // 保留原异常继续向上传
    }
}

// 反模式 2：按值捕获 → 对象切片，派生上下文字段丢失。
class RichError : public std::runtime_error {
public:
    RichError() : std::runtime_error("rich error"), seq_(77) {}
    int seq() const { return seq_; }

private:
    int seq_;
};

int main() {
    // 对 1：吞异常 vs 记录后重抛。
    swallow();
    std::cout << "\n";
    try {
        rethrow_up();
    } catch (const std::runtime_error& e) {
        std::cout << "GOOD rethrown: " << e.what() << '\n';
    }

    // 对 2：按值捕获切片 vs 引用捕获保真。
    try {
        throw RichError();
    } catch (std::runtime_error e) { // ANTI：按值，RichError 的派生部分被剥掉
        std::cout << "ANTI slicing: what=" << e.what() << '\n';
    }
    try {
        throw RichError();
    } catch (const RichError& e) { // GOOD：引用，字段还在
        std::cout << "GOOD ref: what=" << e.what() << " seq=" << e.seq() << '\n';
    }

    // 对 3：笼统报错 vs 带上下文报错。
    try {
        try {
            throw std::runtime_error("open /data/index.bin: errno=2");
        } catch (const std::runtime_error&) {
            throw std::runtime_error("failed"); // ANTI：上下文全丢
        }
    } catch (const std::runtime_error& e) {
        std::cout << "ANTI vague: " << e.what() << '\n';
    }
    try {
        try {
            throw std::runtime_error("open /data/index.bin: errno=2");
        } catch (const std::runtime_error& e) {
            throw std::runtime_error(std::string("build: ") + e.what()); // GOOD：根因随行
        }
    } catch (const std::runtime_error& e) {
        std::cout << "GOOD context: " << e.what() << '\n';
    }
    return 0;
}
