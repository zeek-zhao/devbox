#include <iostream>
#include <memory>
#include <string_view>

class Product {
public:
    virtual ~Product() = default;
    virtual std::string_view name() const = 0;
};

class JsonParser final : public Product {
public:
    std::string_view name() const override { return "json parser"; }
};

class TextParser final : public Product {
public:
    std::string_view name() const override { return "text parser"; }
};

class Factory {
public:
    virtual ~Factory() = default;
    virtual std::unique_ptr<Product> create() const = 0;
};

class JsonFactory final : public Factory {
public:
    std::unique_ptr<Product> create() const override {
        return std::make_unique<JsonParser>();
    }
};

class TextFactory final : public Factory {
public:
    std::unique_ptr<Product> create() const override {
        return std::make_unique<TextParser>();
    }
};

void use_factory(const Factory* factory) {
    const std::unique_ptr<Product> product = factory->create();
    std::cout << product->name() << '\n';
}

int main() {
    const std::unique_ptr<Factory> json = std::make_unique<JsonFactory>();
    const std::unique_ptr<Factory> text = std::make_unique<TextFactory>();
    use_factory(json.get());
    use_factory(text.get());
}
