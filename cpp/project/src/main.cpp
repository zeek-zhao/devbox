// devbox-cpp 毕业项目：高性能文本索引器
// 已消费用例: hello
#include "index.h"

#include <iostream>

int main(int argc, char* argv[]) {
    if (argc != 3) {
        return 2;
    }

    devbox::InvertedIndex index;
    if (!index.build(argv[1])) {
        return 1;
    }

    const auto* matches = index.find(argv[2]);
    if (matches == nullptr || matches->empty()) {
        std::cout << "NO_MATCH\n";
        return 0;
    }

    for (const std::size_t line_number : *matches) {
        std::cout << line_number << ": " << index.line(line_number) << '\n';
    }
    return 0;
}
