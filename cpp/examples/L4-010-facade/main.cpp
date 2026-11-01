#include <iostream>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

class Parser {
public:
    std::vector<std::string> parse(std::string_view input) const {
        std::istringstream stream{std::string(input)};
        std::vector<std::string> words;
        for (std::string word; stream >> word;) {
            words.push_back(word);
        }
        std::cout << "parse: " << words.size() << " words\n";
        return words;
    }
};

class Indexer {
public:
    std::size_t index(const std::vector<std::string>& words) const {
        const auto count = words.size();
        std::cout << "index: " << count << " entries\n";
        return count;
    }
};

class Renderer {
public:
    void render(std::size_t count) const { std::cout << "render: " << count << " entries\n"; }
};

class PipelineFacade {
public:
    void start(std::string_view input) const {
        const auto words = parser_.parse(input);
        const auto count = indexer_.index(words);
        renderer_.render(count);
    }

private:
    Parser parser_;
    Indexer indexer_;
    Renderer renderer_;
};

int main() {
    const PipelineFacade pipeline;
    pipeline.start("cpp design patterns");
}
