#include <chrono>
#include <iostream>
#include <stdexcept>
#include <string>
#include <thread>

// 重试与退避：瞬时故障（网络抖动、锁冲突）值得重试，且重试要有上限、
// 有退避间隔；永久性错误重试无意义，必须一眼区分。
// 退避间隔用短 sleep 真睡（2ms/4ms/8ms），演练输出不受影响。

static bool is_transient(const std::runtime_error& e) {
    return e.what() == std::string("transient: connection reset");
}

// fail_times：前 n 次失败，之后成功（演练注入）。
static void call_remote(int fail_times, int attempt) {
    if (attempt <= fail_times) {
        throw std::runtime_error("transient: connection reset");
    }
}

static void call_dead() {
    throw std::runtime_error("permanent: bad request");
}

// 统一重试骨架：最多 max_attempts 次，指数退避，永久错误立即放弃。
static int retry(int fail_times, int max_attempts, int base_delay_ms) {
    for (int attempt = 1; attempt <= max_attempts; ++attempt) {
        try {
            call_remote(fail_times, attempt);
            std::cout << "attempt " << attempt << ": ok\n";
            return attempt;
        } catch (const std::runtime_error& e) {
            std::cout << "attempt " << attempt << ": " << e.what() << '\n';
            if (!is_transient(e)) {
                std::cout << "give up: non-transient\n";
                return -1;
            }
            if (attempt == max_attempts) {
                std::cout << "give up: attempts exhausted\n";
                return -1;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(base_delay_ms << (attempt - 1)));
        }
    }
    return -1;
}

int main() {
    // 场景 1：抖两次，第 3 次成功。
    retry(2, 5, 2);

    // 场景 2：一直抖，5 次耗尽。
    retry(99, 5, 2);

    // 场景 3：永久错误，第 1 次就放弃。
    for (int attempt = 1; attempt <= 3; ++attempt) {
        try {
            call_dead();
            std::cout << "dead attempt " << attempt << ": ok\n";
            break;
        } catch (const std::runtime_error& e) {
            std::cout << "dead attempt " << attempt << ": " << e.what() << '\n';
            std::cout << "dead: give up immediately\n";
            break;
        }
    }
    return 0;
}
