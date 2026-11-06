#include <cstdio>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>

// 资源泄漏防护：裸 FILE* 交给 unique_ptr 挂自定义删除器，所有退出路径
// （包括异常路径）都恰好关闭一次。void(*)(FILE*) 删除器配 fclose 正好。

struct FileCloser {
    void operator()(std::FILE* f) const noexcept {
        if (f != nullptr) {
            std::fclose(f);
            std::cout << "closed\n";
        }
    }
};

using FileGuard = std::unique_ptr<std::FILE, FileCloser>;

static FileGuard open_or_throw(const std::string& path) {
    std::FILE* f = std::fopen(path.c_str(), "r");
    if (f == nullptr) {
        throw std::runtime_error("cannot open " + path);
    }
    std::cout << "opened " << path << '\n';
    return FileGuard(f); // 所有权立即交给守卫，后面任何路径都不会漏
}

static void read_header(const std::string& path) {
    FileGuard g = open_or_throw(path);
    std::cout << "read_header: processing " << path << '\n';
    if (path == "/tmp/devbox-e009-bad.txt") {
        throw std::runtime_error("bad header"); // 异常路径：g 析构仍会关闭
    }
    std::cout << "read_header: done\n";
}

int main() {
    // 造两个确定性夹具，避免依赖仓库里预置的文件。
    {
        std::FILE* a = std::fopen("/tmp/devbox-e009-good.txt", "w");
        if (a != nullptr) {
            std::fputs("ok", a);
            std::fclose(a);
        }
        std::FILE* b = std::fopen("/tmp/devbox-e009-bad.txt", "w");
        if (b != nullptr) {
            std::fputs("corrupt", b);
            std::fclose(b);
        }
    }

    try {
        read_header("/tmp/devbox-e009-good.txt");
    } catch (const std::runtime_error& e) {
        std::cout << "good path: caught " << e.what() << '\n';
    }

    try {
        read_header("/tmp/devbox-e009-bad.txt");
    } catch (const std::runtime_error& e) {
        std::cout << "bad path: caught " << e.what() << '\n';
    }

    try {
        open_or_throw("/tmp/devbox-e009-missing.txt");
    } catch (const std::runtime_error& e) {
        std::cout << "missing path: caught " << e.what() << '\n';
    }
    return 0;
}
