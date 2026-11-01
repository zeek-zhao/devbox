#include <algorithm>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <utility>
#include <vector>

class Observer {
public:
    virtual ~Observer() = default;
    virtual void update(int version) = 0;
};

class CacheObserver final : public Observer {
public:
    void update(int version) override { std::cout << "cache invalidated: " << version << '\n'; }
};

class DisplayObserver final : public Observer {
public:
    void update(int version) override { std::cout << "display refreshed: " << version << '\n'; }
};

class Subject {
public:
    void subscribe(std::shared_ptr<Observer> observer) {
        if (!observer) {
            throw std::invalid_argument("observer must not be null");
        }
        if (std::find(observers_.begin(), observers_.end(), observer) != observers_.end()) {
            throw std::invalid_argument("observer already registered");
        }
        observers_.push_back(std::move(observer));
    }

    void unsubscribe(const std::shared_ptr<Observer>& observer) {
        if (std::erase(observers_, observer) == 0) {
            throw std::invalid_argument("observer is not registered");
        }
    }

    void set_version(int version) {
        if (version == version_) {
            return;
        }
        version_ = version;
        const auto snapshot = observers_;
        for (const auto& observer : snapshot) {
            observer->update(version);
        }
    }

private:
    int version_ = 0;
    std::vector<std::shared_ptr<Observer>> observers_;
};

int main() {
    Subject subject;
    const std::shared_ptr<Observer> cache = std::make_shared<CacheObserver>();
    const std::shared_ptr<Observer> display = std::make_shared<DisplayObserver>();
    subject.subscribe(cache);
    subject.subscribe(display);
    subject.set_version(1);
    subject.unsubscribe(cache);
    subject.set_version(2);
}
