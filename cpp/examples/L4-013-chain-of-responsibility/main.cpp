#include <iostream>
#include <memory>
#include <string_view>
#include <utility>

enum class Level { info, warning, error, unknown };

class Handler {
public:
    virtual ~Handler() = default;

    void set_next(std::unique_ptr<Handler> next) {
        next_ = std::move(next);
    }

    virtual std::string_view handle(Level level) const {
        return next_ ? next_->handle(level) : "unhandled";
    }

private:
    std::unique_ptr<Handler> next_;
};

class InfoHandler final : public Handler {
public:
    std::string_view handle(Level level) const override {
        return level == Level::info ? "info" : Handler::handle(level);
    }
};

class WarningHandler final : public Handler {
public:
    std::string_view handle(Level level) const override {
        return level == Level::warning ? "warning" : Handler::handle(level);
    }
};

class ErrorHandler final : public Handler {
public:
    std::string_view handle(Level level) const override {
        return level == Level::error ? "error" : Handler::handle(level);
    }
};

int main() {
    std::unique_ptr<Handler> chain = std::make_unique<InfoHandler>();
    auto warning = std::make_unique<WarningHandler>();
    warning->set_next(std::make_unique<ErrorHandler>());
    chain->set_next(std::move(warning));

    for (const auto level : {Level::info, Level::warning, Level::error,
                             Level::unknown}) {
        std::cout << chain->handle(level) << '\n';
    }
}
