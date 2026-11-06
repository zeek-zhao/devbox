#include <iostream>
#include <stdexcept>
#include <string>
#include <utility>

// 自定义异常类型：继承 std::runtime_error（或其派生），把定位所需的上下文
// （哪个文件、第几条记录、什么码）作为字段随身携带，而不是只塞进一段字符串。

class IndexCorruptError : public std::runtime_error {
public:
    IndexCorruptError(std::string path, int line, int code)
        : std::runtime_error("index file corrupt"), path_(std::move(path)), line_(line),
          code_(code) {}

    const std::string& path() const { return path_; }
    int line() const { return line_; }
    int code() const { return code_; }

private:
    std::string path_;
    int line_;
    int code_;
};

static void load(const std::string& path) {
    // 真实场景：读到 magic/校验和不符时抛出。这里固定第 7 行、错误码 3。
    throw IndexCorruptError(path, 7, 3);
}

int main() {
    try {
        load("data/index.bin");
        std::cout << "load: ok\n";
    } catch (const IndexCorruptError& e) {
        // 诊断信息里带着上下文字段，定位时不用重新打开文件。
        std::cout << "load: failed what=" << e.what() << '\n';
        std::cout << "load: path=" << e.path() << " line=" << e.line() << " code=" << e.code()
                  << '\n';
    }

    // 上层只认基类时，仍能靠 what() 给出概要；细节字段留在派生类型里按需取。
    try {
        load("data/index.bin");
    } catch (const std::runtime_error& e) {
        std::cout << "outer: summary=" << e.what() << '\n';
    }
    return 0;
}
