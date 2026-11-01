#include <iostream>
#include <limits>

int main() {
    const unsigned int wrapped = std::numeric_limits<unsigned int>::max() + 1u;

    int sum = 0;
    const bool addition_overflow = __builtin_add_overflow(std::numeric_limits<int>::max(), 1, &sum);

    int product = 0;
    const bool multiplication_overflow =
        __builtin_mul_overflow(std::numeric_limits<int>::max(), 2, &product);

    constexpr bool negative_compares_less = static_cast<unsigned int>(-1) < 1u;

    std::cout << "unsigned wraparound: " << wrapped << '\n';
    std::cout << std::boolalpha;
    std::cout << "signed addition overflow detected: " << addition_overflow << '\n';
    std::cout << "signed multiplication overflow detected: " << multiplication_overflow << '\n';
    std::cout << "-1 < 1u after unsigned conversion: " << negative_compares_less << '\n';
}
