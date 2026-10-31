#include <iostream>
#include <memory>
#include <string>
#include <utility>

class Component {
public:
    virtual ~Component() = default;
    virtual std::string describe() const = 0;
};

class Result final : public Component {
public:
    std::string describe() const override { return "result"; }
};

class Decorator : public Component {
public:
    explicit Decorator(std::shared_ptr<const Component> component)
        : component_(std::move(component)) {}

protected:
    const Component& wrapped() const { return *component_; }

private:
    std::shared_ptr<const Component> component_;
};

class Cache final : public Decorator {
public:
    using Decorator::Decorator;
    std::string describe() const override {
        return "cache(" + wrapped().describe() + ")";
    }
};

class Statistics final : public Decorator {
public:
    using Decorator::Decorator;
    std::string describe() const override {
        return "stats(" + wrapped().describe() + ")";
    }
};

int main() {
    const std::shared_ptr<const Component> result = std::make_shared<Result>();
    std::cout << "before: " << result->describe() << '\n';
    const std::shared_ptr<const Component> cached = std::make_shared<Cache>(result);
    const std::shared_ptr<const Component> measured =
        std::make_shared<Statistics>(cached);
    std::cout << "decorated: " << measured->describe() << '\n';
    const std::shared_ptr<const Component> reversed =
        std::make_shared<Cache>(std::make_shared<Statistics>(result));
    std::cout << "reversed: " << reversed->describe() << '\n';
    std::cout << "after: " << result->describe() << '\n';
}
