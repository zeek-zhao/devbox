#include <atomic>
#include <iostream>
#include <thread>

int main() {
    int payload = 0;
    int received_value = 0;
    std::atomic<int> ready{0};

    std::thread producer([&] {
        payload = 42;
        ready.store(1, std::memory_order_release);
    });
    std::thread consumer([&] {
        while (ready.load(std::memory_order_acquire) == 0) {
        }
        received_value = payload;
    });

    producer.join();
    consumer.join();
    std::cout << "published-value: " << received_value << '\n';
}
