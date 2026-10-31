#include <cstddef>

int main() {
  int* values = new int[2];
  volatile std::size_t index = 2;
  values[index] = 7;
  delete[] values;
}
