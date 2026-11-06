#include <cassert>
#include <iostream>
#include <optional>
#include <stdexcept>
#include <string>

// 断言与契约分层：
//   assert        —— 内部不变式/程序员错误，NDEBUG 下消失，不上线顶班；
//   前置条件校验  —— 调用方输入问题，永远检查，返回错误值而不是崩溃。
// 两层混用是常见事故：拿 assert 挡用户输入，release 构建直接放行坏数据。

static std::optional<int> parse_port(const std::string& input) {
    if (input.empty()) {
        return std::nullopt; // 前置条件不满足：调用方错误，永远检查
    }
    for (char c : input) {
        if (c < '0' || c > '9') {
            return std::nullopt;
        }
    }
    return std::optional<int>(std::stoi(input));
}

static int to_mask(int port) {
    assert(port >= 0 && port <= 65535); // 内部不变式：上游 parse 已保证
    return port & 0xFF;
}

int main() {
    // 输入路径：永远真校验，坏输入返回错误值，不靠 assert。
    auto bad = parse_port("");
    std::cout << "empty: ok=" << (bad.has_value() ? "true" : "false") << '\n';

    auto junk = parse_port("80o");
    std::cout << "junk: ok=" << (junk.has_value() ? "true" : "false") << '\n';

    auto good = parse_port("8080");
    if (good.has_value()) {
        std::cout << "good: value=" << *good << " mask=" << to_mask(*good) << '\n';
    }

    // 内部不变式：正常数据下 assert 通过，程序继续。
    auto ok = parse_port("1");
    std::cout << "boundary: value=" << *ok << " mask=" << to_mask(*ok) << '\n';

    // 展示 assert 生效性：本例在 debug 构建跑，NDEBUG 未定义。
    bool ndebug = false;
#ifdef NDEBUG
    ndebug = true;
#endif
    std::cout << "assert: active=" << (ndebug ? "false" : "true") << '\n';
    return 0;
}
