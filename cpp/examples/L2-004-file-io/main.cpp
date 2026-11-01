#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "expected one data directory\n";
        return 1;
    }

    const std::filesystem::path data_dir{argv[1]};
    std::filesystem::remove_all(data_dir);
    std::filesystem::create_directories(data_dir);

    {
        std::ofstream output{data_dir / "notes.txt"};
        if (!output) {
            std::cerr << "cannot create notes.txt\n";
            return 1;
        }
        output << "alpha\nbeta\n";
        output.close();
        if (!output) {
            std::cerr << "cannot finish notes.txt\n";
            return 1;
        }
    }
    {
        std::ofstream output{data_dir / "summary.txt"};
        if (!output) {
            std::cerr << "cannot create summary.txt\n";
            return 1;
        }
        output << "two lines\n";
        output.close();
        if (!output) {
            std::cerr << "cannot finish summary.txt\n";
            return 1;
        }
    }

    std::ifstream input{data_dir / "notes.txt"};
    if (!input) {
        std::cerr << "cannot open notes.txt\n";
        return 1;
    }
    std::string line;
    std::vector<std::string> lines;
    while (std::getline(input, line)) {
        lines.push_back(line);
    }
    if (input.bad()) {
        std::cerr << "cannot read notes.txt\n";
        return 1;
    }

    std::cout << "read: ";
    for (std::size_t index = 0; index < lines.size(); ++index) {
        if (index != 0) {
            std::cout << '|';
        }
        std::cout << lines[index];
    }
    std::cout << '\n';

    std::ifstream missing{data_dir / "missing.txt"};
    std::cout << "missing: " << (missing ? "opened" : "not found") << '\n';

    std::ofstream blocked{data_dir / "notes.txt" / "blocked.txt"};
    std::cout << "write: " << (blocked ? "succeeded" : "failed") << '\n';

    std::vector<std::string> filenames;
    for (const auto& entry : std::filesystem::directory_iterator{data_dir}) {
        filenames.push_back(entry.path().filename().string());
    }
    std::sort(filenames.begin(), filenames.end());
    std::cout << "files:\n";
    for (const auto& filename : filenames) {
        std::cout << "- " << filename << '\n';
    }
}
