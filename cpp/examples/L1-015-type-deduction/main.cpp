#include <iostream>
#include <type_traits>

int main() {
  const int source = 7;
  auto value = source;
  const auto& reference = source;
  decltype(auto) exact_reference = (source);

  std::cout << std::boolalpha;
  std::cout << "auto is int: " << std::is_same_v<decltype(value), int> << '\n';
  std::cout << "auto is reference: "
            << std::is_reference_v<decltype(value)> << '\n';
  std::cout << "auto is const: " << std::is_const_v<decltype(value)> << '\n';
  std::cout << "const auto& is const reference: "
            << std::is_same_v<decltype(reference), const int&> << '\n';
  std::cout << "decltype(auto) is const reference: "
            << std::is_same_v<decltype(exact_reference), const int&> << '\n';
}
