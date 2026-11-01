#include <iostream>
#include <string>
#include <utility>

class Text;
class Number;

class Visitor {
public:
    virtual ~Visitor() = default;
    virtual std::string visit(const Text& text) const = 0;
    virtual std::string visit(const Number& number) const = 0;
};

class Element {
public:
    virtual ~Element() = default;
    virtual std::string accept(const Visitor& visitor) const = 0;
};

class Text final : public Element {
public:
    explicit Text(std::string value) : value_(std::move(value)) {}
    const std::string& value() const { return value_; }
    std::string accept(const Visitor& visitor) const override { return visitor.visit(*this); }

private:
    std::string value_;
};

class Number final : public Element {
public:
    explicit Number(int value) : value_(value) {}
    int value() const { return value_; }
    std::string accept(const Visitor& visitor) const override { return visitor.visit(*this); }

private:
    int value_;
};

class DescribeVisitor final : public Visitor {
public:
    std::string visit(const Text& text) const override { return "describe text: " + text.value(); }
    std::string visit(const Number& number) const override {
        return "describe number: " + std::to_string(number.value());
    }
};

class MeasureVisitor final : public Visitor {
public:
    std::string visit(const Text& text) const override {
        return "measure text: " + std::to_string(text.value().size());
    }
    std::string visit(const Number& number) const override {
        return "measure number: " + std::to_string(std::to_string(number.value()).size());
    }
};

int main() {
    Text text("cpp");
    Number number(42);
    DescribeVisitor describe;
    MeasureVisitor measure;
    const Element* elements[] = {&text, &number};
    const Visitor* visitors[] = {&describe, &measure};
    for (const Visitor* visitor : visitors) {
        for (const Element* element : elements) {
            std::cout << element->accept(*visitor) << '\n';
        }
    }
}
