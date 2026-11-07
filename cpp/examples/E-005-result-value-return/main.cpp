#include <iostream>
#include <optional>
#include <string>
#include <utility>
#include <variant>

// optional/expected 式返回：错误作为**值**在返回类型里显式流转，
// 调用方不处理就编译不过（variant 不查看就 get 会抛/不匹配）。
// 这里用 std::expected 的最小可替代：Result<T, E>（variant + 标签）。

enum class LookupError { NotFound, Permissions };

struct Result {
    std::variant<std::string, LookupError> value;

    bool ok() const { return value.index() == 0; }
    const std::string& text() const { return std::get<0>(value); }
    LookupError error() const { return std::get<1>(value); }
};

static const char* describe(LookupError e) {
    switch (e) {
    case LookupError::NotFound:
        return "not found";
    case LookupError::Permissions:
        return "permissions denied";
    }
    return "unknown";
}

static Result lookup(bool hit, LookupError fail) {
    if (!hit) {
        return Result{fail};
    }
    return Result{std::string("entry-42")};
}

int main() {
    // 成功路径：值在 variant 的 0 号槽位。
    Result good = lookup(true, LookupError::NotFound);
    if (good.ok()) {
        std::cout << "good: value=" << good.text() << '\n';
    } else {
        std::cout << "good: error=" << describe(good.error()) << '\n';
    }

    // 失败路径 1：NotFound。
    Result miss = lookup(false, LookupError::NotFound);
    if (miss.ok()) {
        std::cout << "miss: value=" << miss.text() << '\n';
    } else {
        std::cout << "miss: error=" << describe(miss.error()) << '\n';
    }

    // 失败路径 2：Permissions，同一返回类型承载多种错误。
    Result denied = lookup(false, LookupError::Permissions);
    std::cout << "denied: ok=" << (denied.ok() ? "true" : "false") << '\n';
    std::cout << "denied: error=" << describe(denied.error()) << '\n';

    // optional 变体：只关心「有没有」，不区分错误种类。
    std::optional<int> maybe = std::nullopt;
    std::cout << "optional: has=" << (maybe.has_value() ? "true" : "false") << '\n';
    maybe = 7;
    std::cout << "optional: value_or=" << maybe.value_or(-1) << '\n';
    return 0;
}
