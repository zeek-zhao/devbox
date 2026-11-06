#include <chrono>
#include <iostream>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

// 快速失败（fail fast）：不可恢复的错误在入口处立即中止，且中止发生在
// 任何副作用之前——资源一样都没占，坏状态没有机会产生。
// 与「重试/降级」的分界：可恢复的才值得绕路，不可恢复的越早停损失越小。

static std::vector<std::string> g_work; // 模拟已占用的资源

static void cleanup() {
    std::cout << "cleanup: release " << g_work.size() << " items\n";
    g_work.clear();
}

static void start_batch(int workers) {
    if (workers <= 0) {
        // 入口检查：配置错误不可恢复，先拒绝、再谈资源——
        // 抛出时 g_work 还是空的，调用方无需回滚任何东西。
        throw std::runtime_error("config: workers must be positive");
    }
    g_work.push_back("conn");
    g_work.push_back("buffer");
    std::cout << "batch: started with " << workers << " workers\n";
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
}

int main() {
    // 场景 1：坏配置。fail fast = 零副作用失败。
    try {
        start_batch(0);
        std::cout << "bad: ran (should not happen)\n";
    } catch (const std::runtime_error& e) {
        std::cout << "fail-fast: " << e.what() << '\n';
        cleanup(); // release 0：拒绝发生在占用资源之前
    }

    // 场景 2：好配置，正常走完。
    start_batch(4);
    cleanup();
    return 0;
}
