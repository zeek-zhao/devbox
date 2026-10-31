#include "index.h"

#include <chrono>
#include <iostream>
#include <numeric>

// L3-004-profiling-benchmarks: warm up, repeat, report the median of batched queries.
int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "usage: bench_index <file> <query>\n";
        return 2;
    }

    try {
        for (const std::size_t workers : {1U, 4U}) {
            std::vector<long long> builds, queries;
            devbox::InvertedIndex index;
            std::size_t checksum = 0;
            for (int repeat = 0; repeat < 8; ++repeat) {
                const auto start = std::chrono::steady_clock::now();
                if (!index.build(argv[1], workers, devbox::TextParserFactory{})) {
                    throw std::runtime_error(index.last_error());
                }
                const auto indexed = std::chrono::steady_clock::now();
                for (int query = 0; query < 1000; ++query) {
                    const auto* match = index.find(argv[2]);
                    checksum += match == nullptr ? 0 : match->size();
                }
                const auto queried = std::chrono::steady_clock::now();
                if (repeat != 0) {
                    builds.push_back(
                        std::chrono::duration_cast<std::chrono::microseconds>(indexed - start)
                            .count());
                    queries.push_back(
                        std::chrono::duration_cast<std::chrono::nanoseconds>(queried - indexed)
                            .count() /
                        1000);
                }
            }
            std::sort(builds.begin(), builds.end());
            std::sort(queries.begin(), queries.end());
            std::cerr << "workers=" << workers << " samples=7 queries_per_sample=1000"
                      << " index_median_us=" << builds[3] << " query_median_ns=" << queries[3]
                      << " checksum=" << checksum << '\n';
        }
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "benchmark: " << error.what() << '\n';
        return 1;
    }
}
