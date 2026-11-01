#include <iostream>
#include <memory>
#include <string>
#include <utility>
#include <vector>

class Prototype {
public:
    virtual ~Prototype() = default;
    virtual std::unique_ptr<Prototype> clone() const = 0;
    virtual void set_word(std::size_t index, std::string word) = 0;
    virtual const std::string& word(std::size_t index) const = 0;
};

class Index final : public Prototype {
public:
    Index() : words_{"cpp", "patterns"} { ++construction_count_; }
    Index(const Index&) = default;

    std::unique_ptr<Prototype> clone() const override { return std::make_unique<Index>(*this); }
    void set_word(std::size_t index, std::string word) override {
        words_.at(index) = std::move(word);
    }
    const std::string& word(std::size_t index) const override { return words_.at(index); }
    static int construction_count() { return construction_count_; }

private:
    std::vector<std::string> words_;
    inline static int construction_count_ = 0;
};

int main() {
    const std::unique_ptr<Prototype> original = std::make_unique<Index>();
    std::cout << "constructions before clone: " << Index::construction_count() << '\n';
    const std::unique_ptr<Prototype> copy = original->clone();
    copy->set_word(0, "clone");
    std::cout << "original: " << original->word(0) << '\n';
    std::cout << "copy: " << copy->word(0) << '\n';
    std::cout << "constructions after clone: " << Index::construction_count() << '\n';
}
