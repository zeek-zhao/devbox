#include <iostream>
#include <type_traits>

static_assert(std::is_integral_v<int>, "the value type must be integral");
static_assert(std::is_same_v<decltype(1 + 2), int>, "integer addition must produce int");
static_assert(sizeof(short) <= sizeof(int), "int must be at least as large as short");

int main() {
    std::cout << std::boolalpha;
    std::cout << "int is integral: " << std::is_integral_v<int> << '\n';
    std::cout << "addition type is int: " << std::is_same_v<decltype(1 + 2), int> << '\n';
    std::cout << "sizeof(short) <= sizeof(int): " << (sizeof(short) <= sizeof(int)) << '\n';
}
