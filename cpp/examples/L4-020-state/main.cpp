#include <iostream>
#include <memory>
#include <stdexcept>
#include <string_view>
#include <utility>

class State {
public:
    virtual ~State() = default;
    virtual std::string_view name() const = 0;
    virtual std::unique_ptr<State> handle() const = 0;
};

class Done final : public State {
public:
    std::string_view name() const override { return "done"; }
    std::unique_ptr<State> handle() const override { return std::make_unique<Done>(); }
};

class Running final : public State {
public:
    std::string_view name() const override { return "running"; }
    std::unique_ptr<State> handle() const override { return std::make_unique<Done>(); }
};

class Pending final : public State {
public:
    std::string_view name() const override { return "pending"; }
    std::unique_ptr<State> handle() const override { return std::make_unique<Running>(); }
};

class Task {
public:
    explicit Task(std::unique_ptr<State> state) : state_(std::move(state)) {
        if (!state_) {
            throw std::invalid_argument("state must not be null");
        }
    }
    void request() {
        auto next = state_->handle();
        if (!next) {
            throw std::logic_error("state transition returned null");
        }
        state_ = std::move(next);
    }
    std::string_view state_name() const { return state_->name(); }

private:
    std::unique_ptr<State> state_;
};

int main() {
    Task task(std::make_unique<Pending>());
    std::cout << task.state_name() << '\n';
    task.request();
    std::cout << task.state_name() << '\n';
    task.request();
    std::cout << task.state_name() << '\n';
}
