#include <iostream>
#include <string_view>

int main(int argc, char* argv[]) {
  if (argc == 2 && std::string_view{argv[1]} == "--help") {
    std::cout << "usage: query --query TERM | --help\n";
    return 0;
  }
  if (argc == 3 && std::string_view{argv[1]} == "--query") {
    std::cout << "query: " << argv[2] << '\n';
    return 0;
  }
  if (argc == 1) {
    std::cout << "error: missing query\n";
    std::cout << "usage: query --query TERM | --help\n";
    return 2;
  }
  std::cout << "error: invalid option or arguments\n";
  std::cout << "usage: query --query TERM | --help\n";
  return 2;
}
