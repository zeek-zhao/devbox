#include <iostream>
#include <optional>
#include <stdexcept>
#include <vector>

int main() {
  const std::vector<int> values{10, 20};

  try {
    static_cast<void>(values.at(values.size()));
  } catch (const std::out_of_range&) {
    std::cout << "at exception: std::out_of_range\n";
  }

  std::cout << "operator[] on valid index: " << values[1] << '\n';
  std::cout << "operator[]: unchecked\n";

  const std::optional<int> missing;
  std::cout << std::boolalpha;
  std::cout << "optional has value: " << missing.has_value() << '\n';
}
