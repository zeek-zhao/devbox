#include <iostream>
#include <string>

// 错误码枚举：enum class 把错误集合收进一个类型，非法值进不来；
// to_exit_code 集中管理「错误码 -> 进程退出码」的映射，散落各处的
// return 3 之类的魔法数字收敛到一处。

enum class Errc {
    Ok = 0,
    BadInput = 1,
    NotFound = 4,
    Conflict = 5,
};

static const char* name(Errc e) {
    switch (e) {
    case Errc::Ok:
        return "ok";
    case Errc::BadInput:
        return "bad input";
    case Errc::NotFound:
        return "not found";
    case Errc::Conflict:
        return "conflict";
    }
    return "unknown";
}

// 进程退出码约定：0 成功，1 输入错误，2 内部错误； NotFound/Conflict
// 这类「业务失败但程序没错」统一归 0（命令行工具常用口径）。
static int to_exit_code(Errc e) {
    switch (e) {
    case Errc::Ok:
    case Errc::NotFound:
    case Errc::Conflict:
        return 0;
    case Errc::BadInput:
        return 1;
    }
    return 2;
}

static Errc remove_entry(const std::string& key, bool exists) {
    if (key.empty()) {
        return Errc::BadInput;
    }
    if (!exists) {
        return Errc::NotFound;
    }
    return Errc::Ok;
}

int main() {
    Errc a = remove_entry("alpha", true);
    std::cout << "alpha: " << name(a) << " exit=" << to_exit_code(a) << '\n';

    Errc b = remove_entry("", true);
    std::cout << "empty: " << name(b) << " exit=" << to_exit_code(b) << '\n';

    Errc c = remove_entry("ghost", false);
    std::cout << "ghost: " << name(c) << " exit=" << to_exit_code(c) << '\n';

    // enum class 不隐式转 int：写 std::cout << c 编译不过，必须显式取值。
    std::cout << "ghost: raw=" << static_cast<int>(c) << '\n';
    return to_exit_code(c);
}
