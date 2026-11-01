#include "index.hpp"

#include <iostream>

std::string_view Index::query(std::string_view term) const {
    const auto result = storage_.find(term);
    std::cout << "index: " << term << " -> " << result << '\n';
    return result;
}
