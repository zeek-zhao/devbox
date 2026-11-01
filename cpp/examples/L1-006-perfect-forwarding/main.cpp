#include <iostream>
#include <utility>

struct Tracked {
    static int copies;
    static int moves;

    Tracked() = default;

    Tracked(const Tracked&) { ++copies; }

    Tracked(Tracked&&) noexcept { ++moves; }
};

int Tracked::copies = 0;
int Tracked::moves = 0;

void receive(Tracked) {}

template <typename T> void forward_to_receive(T&& value) {
    receive(std::forward<T>(value));
}

int main() {
    Tracked item;

    forward_to_receive(item);
    std::cout << "forward(lvalue): copies=" << Tracked::copies << " moves=" << Tracked::moves
              << '\n';

    Tracked::copies = 0;
    Tracked::moves = 0;
    forward_to_receive(Tracked{});
    std::cout << "forward(rvalue): copies=" << Tracked::copies << " moves=" << Tracked::moves
              << '\n';
}
