#include "storage.hpp"

#include <iostream>

std::string_view Storage::find(std::string_view term) const {
  const std::string_view result = term == "alpha" ? "document-1" : "not-found";
  std::cout << "storage: " << term << " -> " << result << '\n';
  return result;
}
