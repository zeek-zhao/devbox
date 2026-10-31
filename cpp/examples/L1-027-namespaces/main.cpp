#include <iostream>

namespace first {
void describe() { std::cout << "first::describe\n"; }
}

namespace second {
void describe() { std::cout << "second::describe\n"; }
}

namespace scope {
int label = 1;
}

int main() {
  first::describe();
  second::describe();

  using first::describe;
  describe();

  using namespace scope;
  int label = 2;
  std::cout << "scope::label: " << scope::label << '\n';
  std::cout << "local label: " << label << '\n';
}
