#include <iostream>
#include <optional>
#include <string>
#include <variant>

void print_variant(const std::variant<int, std::string>& state) {
  if (std::holds_alternative<int>(state)) {
    if (const int* value = std::get_if<int>(&state)) {
      std::cout << "variant int: " << *value << '\n';
    }
  } else if (std::holds_alternative<std::string>(state)) {
    if (const std::string* value = std::get_if<std::string>(&state)) {
      std::cout << "variant string: " << *value << '\n';
    }
  }
}

int main() {
  const std::optional<int> missing;
  if (missing.has_value()) {
    std::cout << "optional value: " << *missing << '\n';
  } else {
    std::cout << "optional: missing\n";
  }

  const std::variant<int, std::string> count{42};
  print_variant(count);

  const std::variant<int, std::string> message{std::string{"ready"}};
  print_variant(message);
}
