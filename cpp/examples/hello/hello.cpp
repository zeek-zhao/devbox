// 用例 hello：确认工具链版本、C++20 特性、基本算法可用
#include <iostream>
#include <numeric>
#include <string>
#include <string_view>
#include <vector>

int main() {
    std::cout << "[hello] C++20 from devbox\n";

    // string_view 是 C++17 起的零拷贝视图，后面 L1 用例会反复用到
    std::string_view sv{"devbox"};
    std::cout << "string_view = " << sv.size() << " chars\n";

    // iota + accumulate：确认 <numeric> 可用，且模板推导正常
    std::vector<int> v(100);
    std::iota(v.begin(), v.end(), 1);
    std::cout << "sum(1..100) = " << std::accumulate(v.begin(), v.end(), 0) << "\n";

    return 0;
}
