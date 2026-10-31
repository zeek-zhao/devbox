#include "index.h"

#include <cassert>
#include <filesystem>
#include <fstream>
#include <string>
#include <vector>

int main() {
    const auto path = std::filesystem::temp_directory_path() / "devbox-cpp-project-test-index.txt";
    {
        std::ofstream output(path);
        output << "Alpha beta alpha\n"
                  "gamma, ALPHA\n"
                  "delta\n";
    }

    devbox::InvertedIndex index;
    assert(index.build(path.string()));

    const auto* alpha = index.find("alpha");
    assert(alpha != nullptr);
    assert((*alpha == std::vector<std::size_t>{1, 2}));
    assert(index.line(1) == "Alpha beta alpha");

    const auto* beta = index.find("BETA");
    assert(beta != nullptr);
    assert((*beta == std::vector<std::size_t>{1}));
    assert(index.find("missing") == nullptr);
    assert(index.find("alpha!") == nullptr);

    std::filesystem::remove(path);
    return 0;
}
