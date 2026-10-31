#include "index.h"

#include <chrono>
#include <iostream>

int main(int argc, char* argv[]) {
  if (argc != 3) {
    std::cerr << "usage: bench_index <file> <query>\n";
    return 2;
  }

  const auto start = std::chrono::steady_clock::now();
  devbox::InvertedIndex index;
  if (!index.build(argv[1])) {
    std::cerr << "failed to read input file\n";
    return 1;
  }
  const auto indexed = std::chrono::steady_clock::now();
  const auto* matches = index.find(argv[2]);
  const auto queried = std::chrono::steady_clock::now();

  const auto index_microseconds =
      std::chrono::duration_cast<std::chrono::microseconds>(indexed - start).count();
  const auto query_microseconds =
      std::chrono::duration_cast<std::chrono::microseconds>(queried - indexed).count();
  std::cerr << "index_us=" << index_microseconds
            << " query_us=" << query_microseconds
            << " matches=" << (matches == nullptr ? 0 : matches->size()) << '\n';
  return 0;
}
