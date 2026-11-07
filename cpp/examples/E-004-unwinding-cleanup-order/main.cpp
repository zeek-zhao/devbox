#include <iostream>
#include <stdexcept>
#include <string>
#include <utility>

// 栈展开（stack unwinding）：异常离场时，沿途已构造完成的局部对象按
// 「构造逆序」析构。多个资源一起持有时，清理顺序是确定的、可依赖的：
// 后获取的先释放。析构函数不得抛异常，否则展开中再抛会 std::terminate。

class Session {
public:
    explicit Session(std::string name) : name_(std::move(name)) {
        std::cout << "acquire " << name_ << '\n';
    }
    ~Session() { std::cout << "release " << name_ << '\n'; }

    Session(const Session&) = delete;
    Session& operator=(const Session&) = delete;

private:
    std::string name_;
};

static void send_batch() {
    Session conn{"conn"}; // 先构造
    Session tx{"tx"};     // 后构造
    std::cout << "send: start\n";
    throw std::runtime_error("peer reset");
    // 下方代码不可达；展开时先析构 tx，再析构 conn。
}

int main() {
    try {
        send_batch();
    } catch (const std::runtime_error& e) {
        std::cout << "caught: " << e.what() << '\n';
    }

    // 正常返回同样逆序：验证不是异常路径专属行为。
    {
        Session a{"a"};
        Session b{"b"};
        std::cout << "scope: body done\n";
    }
    std::cout << "exit: clean\n";
    return 0;
}
