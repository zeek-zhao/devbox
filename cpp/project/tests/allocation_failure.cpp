#include <cstdlib>
#include <new>
#include <utility>

// Isolate replacement allocation functions from optimized call sites: GCC otherwise
// mistakes the matching malloc/free implementation for mismatched new/delete.
thread_local bool fail_next_allocation{false};

void* operator new(std::size_t size) {
    if (std::exchange(fail_next_allocation, false)) {
        throw std::bad_alloc{};
    }
    if (void* allocation = std::malloc(size == 0 ? 1 : size)) {
        return allocation;
    }
    throw std::bad_alloc{};
}
void operator delete(void* allocation) noexcept {
    std::free(allocation);
}
void operator delete(void* allocation, std::size_t) noexcept {
    std::free(allocation);
}
