// devbox-cpp 毕业项目：高性能文本索引器
// 已消费用例: hello
#include "index.h"

#include <iostream>

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "usage: devbox-cpp-project <file> <query>\n";
        return 2;
    }

    devbox::InvertedIndex index;
    if (!index.build(argv[1])) {
        std::cerr << "failed to read input file: " << argv[1] << '\n';
        return 1;
    }

    const auto result = index.query(argv[2]);
    const auto* matches = std::get_if<devbox::InvertedIndex::Match>(&result);
    if (matches == nullptr) {
        std::cout << "NO_MATCH\n";
        return 0;
    }

    matches->for_each([](std::size_t line_number, const std::string& text) {
        std::cout << line_number << ": " << text << '\n';
    });
    return 0;
}
