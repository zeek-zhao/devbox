#include <iostream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

// 强异常安全保证（commit/rollback）：失败时对象回到操作前的样子。
// 手法是「先在副本上做完所有可能失败的事，全部成功后用不抛操作提交」。

class Roster {
public:
    void add_weak(const std::string& name) {
        // 基本保证对照：只承诺不泄漏、状态有效，但状态可能已经变化。
        names.push_back(name);
    }

    void add_strong(const std::string& name) {
        std::vector<std::string> staged = names; // 副本：失败不影响原件
        staged.push_back(name);                  // 可能抛的操作都在副本上
        if (name == "boom") {
            throw std::runtime_error("storage full"); // 模拟中途失败
        }
        names = std::move(staged); // 提交：move 赋值不抛
    }

    std::size_t size() const { return names.size(); }
    std::string at(std::size_t i) const { return names.at(i); }

private:
    std::vector<std::string> names;
};

int main() {
    Roster roster;
    roster.add_strong("ada");
    roster.add_strong("bob");
    std::cout << "before: size=" << roster.size() << " first=" << roster.at(0) << '\n';

    try {
        roster.add_strong("boom");
    } catch (const std::runtime_error& e) {
        std::cout << "failed: " << e.what() << '\n';
    }
    // 强保证：失败后状态与操作前完全一致，size 没涨、内容没变。
    std::cout << "after: size=" << roster.size() << " last=" << roster.at(roster.size() - 1)
              << '\n';

    // 基本保证对照：weak 实现先改状态、后遇故障，改过的状态回不去。
    Roster weak;
    weak.add_weak("ada");
    try {
        std::cout << "weak: add done, failure incoming\n";
        throw std::runtime_error("disk error");
    } catch (const std::runtime_error&) {
        std::cout << "weak: size=" << weak.size() << " (state already changed)\n";
    }
    return 0;
}
