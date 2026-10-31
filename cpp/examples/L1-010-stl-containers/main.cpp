#include <iostream>
#include <set>
#include <vector>

int main() {
  std::vector<int> sequence;
  sequence.push_back(4);
  sequence.push_back(7);
  std::cout << "vector after push_back:";
  for (int value : sequence) {
    std::cout << ' ' << value;
  }
  std::cout << '\n';

  std::set<int> values;
  values.insert(20);
  values.insert(10);
  values.insert(20);
  std::cout << "set after insert:";
  for (int value : values) {
    std::cout << ' ' << value;
  }
  std::cout << '\n';

  std::cout << "find(10): "
            << (values.find(10) != values.end() ? "found" : "missing") << '\n';
  std::cout << "erase(20): " << values.erase(20) << '\n';
  std::cout << "set after erase:";
  for (int value : values) {
    std::cout << ' ' << value;
  }
  std::cout << '\n';
}
