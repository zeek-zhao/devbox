#include <iostream>
#include <string>
#include <vector>

// 错误聚合：逐项校验，把**全部**错误收进一个列表一次上报，
// 而不是遇错即抛——用户/调用方修一个错被踢回来一次，体验最差。
// 异常适合「错误是例外」的路径；校验类失败率高，聚合值返回更合适。

struct Problem {
    std::string field;
    std::string message;
};

static std::vector<Problem> validate(const std::string& name, const std::string& port,
                                     const std::string& tags) {
    std::vector<Problem> problems;

    if (name.empty()) {
        problems.push_back({"name", "must not be empty"});
    }
    if (port.empty()) {
        problems.push_back({"port", "must not be empty"});
    } else if (port.find_first_not_of("0123456789") != std::string::npos) {
        problems.push_back({"port", "must be numeric"});
    }
    if (tags.empty()) {
        problems.push_back({"tags", "need at least one"});
    }
    return problems;
}

int main() {
    // 场景 1：三项全错——一次拿到全部三条。
    auto all = validate("", "8o0", "");
    std::cout << "bad input: " << all.size() << " problems\n";
    for (const auto& p : all) {
        std::cout << "  - " << p.field << ": " << p.message << '\n';
    }

    // 场景 2：只有一项错。
    auto one = validate("web", "9x99", "ingest");
    std::cout << "one problem: " << one.size() << "\n";
    for (const auto& p : one) {
        std::cout << "  - " << p.field << ": " << p.message << '\n';
    }

    // 场景 3：全对，空列表即成功信号。
    auto none = validate("web", "8080", "ingest");
    std::cout << "valid input: " << none.size() << " problems\n";
    return 0;
}
