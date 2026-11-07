#include <cerrno>
#include <cstdio>
#include <cstring>
#include <iostream>
#include <system_error>

// errno 约定：库函数失败时才设置 errno，成功时不清零。
// 所以「先看 errno 再判断成败」是错的——必须先检查返回值，失败后 errno 才可信。

int main() {
    // 1) errno 在成功调用后不清零：先制造一个旧错误，再成功调用，errno 仍是旧值。
    errno = 0;
    FILE* missing = std::fopen("no-such-file.txt", "r");
    if (missing == nullptr) {
        std::cout << "fopen missing: errno=" << errno << " (" << std::strerror(errno) << ")\n";
    }
    int stale = errno;
    FILE* good = std::fopen("/dev/null", "r"); // 成功，不会清 errno
    if (good != nullptr) {
        std::fclose(good);
    }
    std::cout << "after success call errno still reports: " << std::strerror(stale) << '\n';

    // 2) 先查返回值、再读 errno：失败才可信。
    errno = 0;
    FILE* ok = std::fopen("/dev/null", "w");
    if (ok != nullptr) {
        std::cout << "fopen /dev/null: ok, errno untouched check skipped\n";
        std::fclose(ok);
    }

    // 3) 现代写法：把 errno 转成 system_error 异常，消息与码一起带走。
    errno = 0;
    FILE* bad = std::fopen("missing-dir/file.txt", "r");
    if (bad == nullptr) {
        try {
            throw std::system_error(errno, std::generic_category(), "open missing-dir/file.txt");
        } catch (const std::system_error& e) {
            std::cout << "system_error: " << e.what() << '\n';
            std::cout << "system_error: code=" << e.code().value() << '\n';
        }
    }
    return 0;
}
