#include <iostream>
#include <string_view>

enum class ErrorCode { invalid_input, storage_failure };

struct Error {
  ErrorCode code;
  std::string_view context;
  std::string_view message;
};

int report(const Error& error) {
  const int exit_code =
      error.code == ErrorCode::invalid_input ? 2 : 3;
  std::cout << "error: " << error.message << " [" << error.context << "]\n";
  return exit_code;
}

int main(int argc, char* argv[]) {
  if (argc != 2) {
    std::cout << "usage: diagnostics input|storage\n";
    return 2;
  }
  const std::string_view kind{argv[1]};
  if (kind == "input") {
    return report({ErrorCode::invalid_input, "query term",
                   "query term must not be empty"});
  }
  if (kind == "storage") {
    return report({ErrorCode::storage_failure, "documents/index.txt",
                   "cannot read index"});
  }
  std::cout << "error: unknown error scenario [argument]\n";
  return 2;
}
