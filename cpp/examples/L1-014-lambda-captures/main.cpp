#include <iostream>

int main() {
  int threshold = 5;
  const auto by_value = [threshold] { return threshold; };
  const auto by_reference = [&threshold] { return threshold; };

  threshold = 9;

  std::cout << "value capture: " << by_value() << '\n';
  std::cout << "reference capture: " << by_reference() << '\n';
}
