#include <chrono>
#include <cstddef>
#include <iostream>

int main() {
  constexpr std::size_t iterations = 10000;
  std::size_t comparisons = 0;
  std::size_t matches = 0;

  const auto start = std::chrono::steady_clock::now();
  for (std::size_t index = 0; index < iterations; ++index) {
    ++comparisons;
    if (index < iterations / 2) {
      ++matches;
    }
  }
  const auto finish = std::chrono::steady_clock::now();
  const auto elapsed = finish - start;
  if (elapsed < decltype(elapsed)::zero()) {
    return 1;
  }

  std::cout << "iterations: " << iterations << "\ncomparisons: " << comparisons
            << "\nmatches: " << matches << "\nbenchmark: measured\n";
}
