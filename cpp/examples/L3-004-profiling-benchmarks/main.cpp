#include <chrono>
#include <cstddef>
#include <iostream>
#include <vector>

namespace {

std::size_t linear_search(const std::vector<int>& data, int target, std::size_t& comparisons) {
    comparisons = 0;
    for (std::size_t index = 0; index < data.size(); ++index) {
        ++comparisons;
        if (data[index] == target) {
            return index;
        }
    }
    return data.size();
}

std::size_t binary_search(const std::vector<int>& data, int target, std::size_t& comparisons) {
    comparisons = 0;
    std::size_t low = 0;
    std::size_t high = data.size();
    while (low < high) {
        const std::size_t middle = low + (high - low) / 2;
        ++comparisons;
        if (data[middle] < target) {
            low = middle + 1;
        } else {
            high = middle;
        }
    }
    ++comparisons;
    return low;
}

} // namespace

int main() {
    constexpr std::size_t size = 1000000;
    constexpr std::size_t binary_repeats = 1000;

    std::vector<int> data(size);
    for (std::size_t index = 0; index < size; ++index) {
        data[index] = static_cast<int>(index * 2);
    }
    const int target = data.back();

    std::size_t linear_comparisons = 0;
    std::size_t binary_comparisons = 0;

    const auto linear_begin = std::chrono::steady_clock::now();
    const std::size_t linear_index = linear_search(data, target, linear_comparisons);
    const auto linear_end = std::chrono::steady_clock::now();

    const auto binary_begin = std::chrono::steady_clock::now();
    std::size_t binary_index = 0;
    for (std::size_t repeat = 0; repeat < binary_repeats; ++repeat) {
        binary_index = binary_search(data, target, binary_comparisons);
    }
    const auto binary_end = std::chrono::steady_clock::now();

    const auto linear_ns =
        std::chrono::duration_cast<std::chrono::nanoseconds>(linear_end - linear_begin).count();
    const auto binary_ns_total =
        std::chrono::duration_cast<std::chrono::nanoseconds>(binary_end - binary_begin).count();
    const auto binary_ns_per_call = binary_ns_total / static_cast<long long>(binary_repeats);

    std::cout << "size: " << size << '\n';
    std::cout << "target: " << target << '\n';
    std::cout << "linear index: " << linear_index << " comparisons: " << linear_comparisons << '\n';
    std::cout << "binary index: " << binary_index << " comparisons: " << binary_comparisons << '\n';
    std::cout << "comparison ratio: " << linear_comparisons / binary_comparisons << '\n';

    // 墙钟时间不写进 expected（规范 §6 黑名单），只把「有 100 倍以上差距」这个
    // 稳定结论打出来。真实比值在 1e4 量级，留 100 倍余量不会因噪声翻转。
    if (linear_ns > 100 * binary_ns_per_call) {
        std::cout << "timing: linear slower than binary by >100x\n";
    } else {
        std::cout << "timing: inconclusive\n";
        return 1;
    }
}
