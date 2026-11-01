#include <charconv>
#include <cstddef>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>

class Expression {
public:
    virtual ~Expression() = default;
    virtual int interpret() const = 0;
};

class Number final : public Expression {
public:
    explicit Number(int value) : value_(value) {}
    int interpret() const override { return value_; }

private:
    int value_;
};

class Add final : public Expression {
public:
    Add(std::unique_ptr<Expression> left, std::unique_ptr<Expression> right)
        : left_(std::move(left)), right_(std::move(right)) {}
    int interpret() const override { return left_->interpret() + right_->interpret(); }

private:
    std::unique_ptr<Expression> left_;
    std::unique_ptr<Expression> right_;
};

class Subtract final : public Expression {
public:
    Subtract(std::unique_ptr<Expression> left, std::unique_ptr<Expression> right)
        : left_(std::move(left)), right_(std::move(right)) {}
    int interpret() const override { return left_->interpret() - right_->interpret(); }

private:
    std::unique_ptr<Expression> left_;
    std::unique_ptr<Expression> right_;
};

class Parser {
public:
    explicit Parser(std::string_view input) : input_(input) {}

    std::unique_ptr<Expression> parse() {
        auto tree = number();
        skip_spaces();
        while (position_ < input_.size()) {
            const char operation = input_[position_++];
            if (operation != '+' && operation != '-') {
                throw std::invalid_argument(std::string("invalid character: ") + operation);
            }
            auto right = number();
            if (operation == '+') {
                tree = std::make_unique<Add>(std::move(tree), std::move(right));
            } else {
                tree = std::make_unique<Subtract>(std::move(tree), std::move(right));
            }
            skip_spaces();
        }
        return tree;
    }

private:
    void skip_spaces() {
        while (position_ < input_.size() && input_[position_] == ' ') {
            ++position_;
        }
    }

    std::unique_ptr<Expression> number() {
        skip_spaces();
        if (position_ == input_.size()) {
            throw std::invalid_argument("expected number");
        }
        if (input_[position_] < '0' || input_[position_] > '9') {
            throw std::invalid_argument(std::string("invalid character: ") + input_[position_]);
        }
        int value = 0;
        const char* first = input_.data() + position_;
        const auto [end, error] = std::from_chars(first, input_.data() + input_.size(), value);
        if (error != std::errc{}) {
            throw std::invalid_argument("number out of range");
        }
        position_ += static_cast<std::size_t>(end - first);
        return std::make_unique<Number>(value);
    }

    std::string_view input_;
    std::size_t position_ = 0;
};

int main() {
    const auto expression = Parser("8 + 3 - 2").parse();
    std::cout << "8 + 3 - 2 = " << expression->interpret() << '\n';
    try {
        const auto invalid = Parser("8 + x").parse();
        std::cout << "unexpected result: " << invalid->interpret() << '\n';
        return 1;
    } catch (const std::invalid_argument& error) {
        std::cout << "error: " << error.what() << '\n';
    }
}
