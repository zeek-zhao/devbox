#include "index_c.h"
#include "index.h"

#include <cstdio>
#include <exception>
#include <new>

struct devbox_index {
    devbox::InvertedIndex value;
};

namespace {
int fail(int code, const char* message, char* error, std::size_t capacity) noexcept {
    if (error != nullptr && capacity != 0) {
        std::snprintf(error, capacity, "%s", message);
    }
    return code;
}
} // namespace

extern "C" int devbox_index_open(const char* path, devbox_index** output, char* error,
                                 std::size_t capacity) {
    if (output == nullptr) {
        return fail(DEVBOX_INPUT, "output handle is null", error, capacity);
    }
    *output = nullptr;
    if (path == nullptr) {
        return fail(DEVBOX_INPUT, "input path is null", error, capacity);
    }
    try {
        auto index = std::make_unique<devbox_index>();
        if (!index->value.build(path)) {
            return fail(DEVBOX_INPUT, index->value.last_error().c_str(), error, capacity);
        }
        *output = index.release();
        return DEVBOX_OK;
    } catch (const std::exception& exception) {
        return fail(DEVBOX_INTERNAL, exception.what(), error, capacity);
    } catch (...) {
        return fail(DEVBOX_INTERNAL, "non-standard exception at C ABI boundary", error, capacity);
    }
}

extern "C" int devbox_index_count(const devbox_index* index, const char* word, std::size_t* count,
                                  char* error, std::size_t capacity) {
    if (index == nullptr || word == nullptr || count == nullptr) {
        return fail(DEVBOX_INPUT, "null query argument", error, capacity);
    }
    *count = 0;
    try {
        const auto result = index->value.query(word);
        if (std::holds_alternative<devbox::InvertedIndex::QueryError>(result)) {
            return fail(DEVBOX_INPUT, "query must be one ASCII word", error, capacity);
        }
        if (const auto* match = std::get_if<devbox::InvertedIndex::Match>(&result)) {
            *count = match->lines().size();
        }
        return DEVBOX_OK;
    } catch (const std::exception& exception) {
        return fail(DEVBOX_INTERNAL, exception.what(), error, capacity);
    } catch (...) {
        return fail(DEVBOX_INTERNAL, "non-standard exception at C ABI boundary", error, capacity);
    }
}

extern "C" void devbox_index_close(devbox_index* index) {
    delete index;
}
