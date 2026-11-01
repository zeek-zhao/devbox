#include <iostream>

#define SQUARE(x) x* x

constexpr int square(int value) {
    return value * value;
}

int main() {
    std::cout << "macro SQUARE(1 + 2): " << SQUARE(1 + 2) << '\n';
    std::cout << "constexpr square(1 + 2): " << square(1 + 2) << '\n';
}
