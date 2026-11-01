// devbox-cpp 毕业项目：高性能文本索引器
// L0-hello: 镜像与 runner 通路锚点。
#include "index.h"

#include <charconv>
#include <iostream>

// L2-008-cli-interface: flags are explicit; numeric conversion consumes the entire input.
int main(int argc, char* argv[]) {
    constexpr std::string_view usage =
        "usage: devbox-cpp-project [--workers N] <file> <query>\n"
        "       devbox-cpp-project --expr <file> '<word> [AND|OR ...]'\n";
    auto errors = devbox::diagnostic_chain();
    if (argc == 2 && std::string_view(argv[1]) == "--help") {
        std::cout << usage;
        return 0;
    }
    try {
        int first = 1;
        bool expression = false;
        if (argc > 1 && std::string_view(argv[1]) == "--workers") {
            if (argc != 5) {
                return errors->report(devbox::ErrorLevel::input, usage, std::cerr);
            }
            std::size_t workers{0};
            const std::string_view value(argv[2]);
            const auto [end, code] =
                std::from_chars(value.data(), value.data() + value.size(), workers);
            if (code != std::errc{} || end != value.data() + value.size()) {
                throw std::invalid_argument("invalid worker count");
            }
            devbox::IndexConfig::instance().workers(workers);
            first = 3;
        } else if (argc > 1 && std::string_view(argv[1]) == "--expr") {
            expression = true;
            first = 2;
        }
        if (argc != first + 2 || std::string_view(argv[first]).starts_with("--")) {
            return errors->report(devbox::ErrorLevel::input, usage, std::cerr);
        }
        if (expression) {
            devbox::IndexApplication{}.run(argv[first], argv[first + 1], std::cout);
            return 0;
        }
        devbox::InvertedIndex index;
        devbox::BuildJob job([&] {
            if (!index.build(argv[first])) {
                throw std::runtime_error(index.last_error());
            }
        });
        job.request();
        job.request();
        const auto result = index.query(argv[first + 1]);
        const auto* matches = std::get_if<devbox::InvertedIndex::Match>(&result);
        if (matches == nullptr) {
            // Preserve the original single-word CLI's invalid-word/no-hit behavior.
            std::cout << "NO_MATCH\n";
            return 0;
        }
        matches->for_each([](std::size_t line_number, const std::string& text) {
            std::cout << line_number << ": " << text << '\n';
        });
        return 0;
    } catch (const std::invalid_argument& error) {
        std::string message = error.what();
        message += '\n';
        message += usage;
        return errors->report(devbox::ErrorLevel::input, message, std::cerr);
    } catch (const std::runtime_error& error) {
        return errors->report(devbox::ErrorLevel::io, error.what(), std::cerr);
    } catch (const std::exception& error) {
        return errors->report(devbox::ErrorLevel::internal, error.what(), std::cerr);
    }
}
