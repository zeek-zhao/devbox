#include <concepts>
#include <cstddef>
#include <iostream>
#include <string>

template <typename T>
concept HasSize = requires(const T& value) {
  { value.size() } -> std::convertible_to<std::size_t>;
};

template <typename T>
inline constexpr bool has_size_v = HasSize<T>;

int main() {
  std::cout << std::boolalpha;
  std::cout << "has_size_v<std::string>: " << has_size_v<std::string> << '\n';
  std::cout << "has_size_v<int>: " << has_size_v<int> << '\n';
}
