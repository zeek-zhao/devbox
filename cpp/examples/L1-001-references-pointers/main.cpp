#include <iostream>

int main() {
  int value = 7;
  int& reference = value;
  int* optional = nullptr;

  std::cout << "reference value: " << reference << '\n';
  std::cout << "pointer is null: " << std::boolalpha << (optional == nullptr)
            << '\n';

  int values[]{10, 20, 30};
  int* cursor = values;
  ++cursor;
  std::cout << "array offset 1: " << *cursor << '\n';
}
