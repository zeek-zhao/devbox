#include <iostream>
#include <memory>

int destroyed = 0;

struct Node {
    std::shared_ptr<Node> next;
    std::weak_ptr<Node> weak_next;

    ~Node() { ++destroyed; }
};

int main() {
    auto exclusive = std::make_unique<int>(42);
    std::cout << "unique value: " << *exclusive << '\n';

    {
        auto first = std::make_shared<Node>();
        auto second = std::make_shared<Node>();
        first->next = second;
        second->next = first;

        std::cout << "before weak: first=" << first.use_count() << " second=" << second.use_count()
                  << '\n';

        second->next.reset();
        second->weak_next = first;
        std::cout << "after weak: first=" << first.use_count() << " second=" << second.use_count()
                  << '\n';
    }

    std::cout << "对象已析构: " << destroyed << '\n';
}
