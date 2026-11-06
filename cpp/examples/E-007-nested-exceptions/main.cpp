#include <exception>
#include <iostream>
#include <stdexcept>
#include <string>

// 嵌套异常：底层异常在向上转译时用 std::throw_with_nested 包一层，
// 顶层 catch 用 std::rethrow_if_nested 逐层剥开，根因不丢。

static void read_index() {
    throw std::runtime_error("checksum mismatch at offset 16");
}

static void build() {
    try {
        read_index();
    } catch (const std::exception&) {
        // 转译：把底层异常挂到新异常的「nest」里再抛。
        std::throw_with_nested(std::runtime_error("build failed"));
    }
}

// 逐层剥：当前异常的 nest 不是空且是异常类型就继续打。
static void print_chain(const std::exception& e, int depth) {
    std::cout << "depth " << depth << ": " << e.what() << '\n';
    try {
        std::rethrow_if_nested(e);
    } catch (const std::exception& inner) {
        print_chain(inner, depth + 1);
    } catch (...) {
        std::cout << "depth " << depth + 1 << ": non-standard nested throwable\n";
    }
}

int main() {
    try {
        build();
    } catch (const std::exception& e) {
        print_chain(e, 0);
    }

    // 对照：普通 throw 新异常不会挂 nest，rethrow_if_nested 什么都不做。
    try {
        try {
            throw std::runtime_error("root cause");
        } catch (const std::exception&) {
            throw std::runtime_error("plain rethrow, no nest");
        }
    } catch (const std::exception& e) {
        std::cout << "plain: " << e.what() << '\n';
        try {
            std::rethrow_if_nested(e);
            std::cout << "plain: no nested exception\n";
        } catch (const std::exception&) {
            std::cout << "plain: unexpectedly nested\n";
        }
    }
    return 0;
}
