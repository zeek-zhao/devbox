#include <iostream>
#include <mutex>

int main() {
    std::mutex guard;
    {
        const std::lock_guard<std::mutex> lock{guard};
        std::cout << "dependency: Threads found\n";
    }
#if DEVBOX_ENABLE_OPTIONAL_LOGGING
    std::cout << "optional: on\n";
#else
    std::cout << "optional: off\n";
#endif
}
