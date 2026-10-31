#include <iostream>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>

class Document {
public:
    explicit Document(std::string text) : text_(std::move(text)) {}
    const std::string& text() const { return text_; }
    void replace(std::string text) { text_ = std::move(text); }

private:
    std::string text_;
};

class Command {
public:
    virtual ~Command() = default;
    virtual void execute() = 0;
    virtual void undo() = 0;
};

class ReplaceCommand final : public Command {
public:
    ReplaceCommand(Document& document, std::string replacement)
        : document_(document), replacement_(std::move(replacement)) {}

    void execute() override {
        if (before_) {
            throw std::logic_error("command already executed");
        }
        before_ = document_.text();
        document_.replace(replacement_);
    }

    void undo() override {
        if (!before_) {
            throw std::logic_error("command has no saved state");
        }
        document_.replace(*before_);
        before_.reset();
    }

private:
    Document& document_;
    std::string replacement_;
    std::optional<std::string> before_;
};

class Invoker {
public:
    explicit Invoker(std::unique_ptr<Command> command)
        : command_(std::move(command)) {
        if (!command_) {
            throw std::invalid_argument("command must not be null");
        }
    }
    void execute() { command_->execute(); }
    void undo() { command_->undo(); }

private:
    std::unique_ptr<Command> command_;
};

int main() {
    Document document("original");
    Invoker invoker(std::make_unique<ReplaceCommand>(document, "replacement"));
    std::cout << "before: " << document.text() << '\n';
    invoker.execute();
    std::cout << "after execute: " << document.text() << '\n';
    invoker.undo();
    std::cout << "after undo: " << document.text() << '\n';
}
