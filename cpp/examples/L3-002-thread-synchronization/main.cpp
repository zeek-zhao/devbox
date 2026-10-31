#include <algorithm>
#include <array>
#include <condition_variable>
#include <iostream>
#include <mutex>
#include <thread>

int main() {
    std::mutex mutex;
    std::condition_variable condition;
    bool ready = false;
    int shared_value = 0;
    std::array<int, 2> results{};

    std::thread consumer([&] {
        std::unique_lock<std::mutex> lock(mutex);
        condition.wait(lock, [&] { return ready; });
        results[0] = shared_value;
    });
    std::thread producer([&] {
        {
            std::lock_guard<std::mutex> lock(mutex);
            shared_value = 42;
            ready = true;
            results[1] = 7;
        }
        condition.notify_one();
    });

    consumer.join();
    producer.join();
    std::sort(results.begin(), results.end());
    std::cout << "results: " << results[0] << ' ' << results[1] << '\n';
}
