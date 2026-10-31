#include "command.hpp"

#include <iostream>

#include "index.hpp"

void Command::execute(std::string_view term) const {
  const Index index;
  const auto result = index.query(term);
  std::cout << "command: " << term << " -> " << result << '\n';
}
