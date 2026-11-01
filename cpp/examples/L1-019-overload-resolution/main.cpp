#include <iostream>
#include <string_view>

std::string_view select(int) {
    return "int";
}

std::string_view select(long) {
    return "long";
}

std::string_view select(double) {
    return "double";
}

template <typename T> std::string_view select(T) {
    return "template";
}

int main() {
    short short_value = 7;

    std::cout << "int argument: " << select(10) << '\n';
    std::cout << "long argument: " << select(10L) << '\n';
    std::cout << "double argument: " << select(2.5) << '\n';
    std::cout << "short argument: " << select(short_value) << '\n';
}
