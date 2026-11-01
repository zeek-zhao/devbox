#include <iostream>
#include <string>

template <typename T> T doubled(const T& value) {
    return value + value;
}

int main() {
    std::cout << "int: " << doubled(7) << '\n';
    std::cout << "string: " << doubled(std::string{"cpp"}) << '\n';
}
