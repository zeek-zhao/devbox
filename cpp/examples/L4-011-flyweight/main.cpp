#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <utility>

class Token {
public:
    explicit Token(std::string key) : key_(std::move(key)) {}
    void render(int position) const {
        std::cout << key_ << '@' << position << '\n';
    }

private:
    const std::string key_;
};

class TokenFactory {
public:
    std::shared_ptr<const Token> get(const std::string& key) {
        const auto found = tokens_.find(key);
        if (found != tokens_.end()) {
            return found->second;
        }
        const auto token = std::make_shared<const Token>(key);
        tokens_.emplace(key, token);
        ++creation_count_;
        return token;
    }
    std::size_t creation_count() const { return creation_count_; }

private:
    std::map<std::string, std::shared_ptr<const Token>> tokens_;
    std::size_t creation_count_ = 0;
};

int main() {
    TokenFactory factory;
    const auto first = factory.get("cpp");
    const auto second = factory.get("cpp");
    const auto third = factory.get("patterns");
    std::cout << std::boolalpha;
    std::cout << "same key, same instance: " << (first.get() == second.get()) << '\n';
    std::cout << "different key, different instance: "
              << (first.get() != third.get()) << '\n';
    std::cout << "creations: " << factory.creation_count() << '\n';
    first->render(1);
    second->render(8);
    first->render(1);
    third->render(2);
}
