#include <iostream>

constexpr int square(int value) {
  return value * value;
}

static_assert(square(4) == 16);

int main() {
  int runtime_value = 5;
  std::cout << "runtime square: " << square(runtime_value) << '\n';
}
