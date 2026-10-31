#include <iostream>
#include <string_view>

class Pipeline {
public:
    virtual ~Pipeline() = default;
    void run() const {
        std::cout << "prepare\n";
        std::cout << step() << '\n';
        std::cout << "verify\n";
    }

protected:
    virtual std::string_view step() const = 0;
};

class ParsePipeline final : public Pipeline {
protected:
    std::string_view step() const override { return "parse text"; }
};

class IndexPipeline final : public Pipeline {
protected:
    std::string_view step() const override { return "build index"; }
};

int main() {
    ParsePipeline parse;
    IndexPipeline index;
    const Pipeline* pipelines[] = {&parse, &index};
    for (const Pipeline* pipeline : pipelines) {
        pipeline->run();
    }
}
