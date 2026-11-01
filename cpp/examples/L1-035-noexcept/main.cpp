#include <iostream>
#include <type_traits>
#include <utility>

struct NoThrowMove {
    NoThrowMove() = default;
    NoThrowMove(NoThrowMove&&) noexcept = default;
};

void guaranteed_not_to_throw() noexcept {}

void may_throw() {}

int main() {
    NoThrowMove value;

    std::cout << std::boolalpha;
    std::cout << "nothrow move constructible: "
              << std::is_nothrow_move_constructible_v<NoThrowMove> << '\n';
    std::cout << "noexcept guaranteed_not_to_throw(): " << noexcept(guaranteed_not_to_throw())
              << '\n';
    std::cout << "noexcept may_throw(): " << noexcept(may_throw()) << '\n';
    std::cout << "noexcept move construction: " << noexcept(NoThrowMove(std::move(value))) << '\n';
}
