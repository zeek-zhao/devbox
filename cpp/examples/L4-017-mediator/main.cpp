#include <algorithm>
#include <iostream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

class Colleague;

class Mediator {
public:
    virtual ~Mediator() = default;
    virtual void send(const Colleague& sender, std::string_view message) const = 0;
};

class Colleague {
public:
    Colleague(Mediator& mediator, std::string name)
        : mediator_(&mediator), name_(std::move(name)) {}
    void send(std::string_view message) const { mediator_->send(*this, message); }
    void receive(std::string_view message) const {
        std::cout << name_ << " received: " << message << '\n';
    }

private:
    Mediator* mediator_;
    std::string name_;
};

class ChatRoom final : public Mediator {
public:
    void attach(Colleague& colleague) {
        if (std::find(colleagues_.begin(), colleagues_.end(), &colleague) != colleagues_.end()) {
            throw std::invalid_argument("colleague already attached");
        }
        colleagues_.push_back(&colleague);
    }
    void send(const Colleague& sender, std::string_view message) const override {
        if (std::find(colleagues_.begin(), colleagues_.end(), &sender) == colleagues_.end()) {
            throw std::invalid_argument("sender is not attached");
        }
        for (const auto* colleague : colleagues_) {
            if (colleague != &sender) {
                colleague->receive(message);
            }
        }
    }

private:
    std::vector<Colleague*> colleagues_;
};

int main() {
    ChatRoom room;
    Colleague alice(room, "Alice");
    Colleague bob(room, "Bob");
    room.attach(alice);
    room.attach(bob);
    alice.send("hello");
    bob.send("reply");
}
