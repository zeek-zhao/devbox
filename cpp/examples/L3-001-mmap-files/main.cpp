#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <fcntl.h>
#include <iostream>
#include <string>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

namespace {

bool map_and_print(const char* path) {
    const int fd = open(path, O_RDONLY);
    if (fd == -1) {
        std::perror("open");
        return false;
    }

    struct stat info {};
    if (fstat(fd, &info) == -1) {
        std::perror("fstat");
        close(fd);
        return false;
    }
    if (info.st_size < 0) {
        std::cerr << "invalid file size\n";
        close(fd);
        return false;
    }

    const auto file_bytes = static_cast<std::size_t>(info.st_size);
    if (file_bytes == 0) {
        std::cout << "mapped-bytes: 0\nfile-bytes: 0\ncontent: <empty>\n";
        if (close(fd) == -1) {
            std::perror("close");
            return false;
        }
        return true;
    }

    const long page_size = sysconf(_SC_PAGESIZE);
    if (page_size <= 0) {
        std::cerr << "invalid page size\n";
        close(fd);
        return false;
    }
    const auto page_bytes = static_cast<std::size_t>(page_size);
    if (file_bytes > static_cast<std::size_t>(-1) - (page_bytes - 1)) {
        std::cerr << "file size overflow\n";
        close(fd);
        return false;
    }
    const std::size_t mapped_bytes = ((file_bytes + page_bytes - 1) / page_bytes) * page_bytes;
    void* const mapping = mmap(nullptr, mapped_bytes, PROT_READ, MAP_PRIVATE, fd, 0);
    if (mapping == MAP_FAILED) {
        std::perror("mmap");
        close(fd);
        return false;
    }

    const auto* const content = static_cast<const char*>(mapping);
    std::cout << "mapped-bytes: " << mapped_bytes << "\nfile-bytes: " << file_bytes
              << "\ncontent: ";
    std::cout.write(content, static_cast<std::streamsize>(file_bytes));
    std::cout << '\n';

    const bool unmapped = munmap(mapping, mapped_bytes) == 0;
    if (!unmapped) {
        std::perror("munmap");
    }
    const bool closed = close(fd) == 0;
    if (!closed) {
        std::perror("close");
    }
    return unmapped && closed;
}

bool write_file(const char* path, const char* content, std::size_t length) {
    const int fd = open(path, O_CREAT | O_TRUNC | O_WRONLY, 0600);
    if (fd == -1) {
        std::perror("open");
        return false;
    }
    const ssize_t written = write(fd, content, length);
    if (written < 0 || static_cast<std::size_t>(written) != length) {
        std::perror("write");
        close(fd);
        return false;
    }
    if (close(fd) == -1) {
        std::perror("close");
        return false;
    }
    return true;
}

} // namespace

int main() {
    const std::string base = std::string{getenv("TMPDIR") == nullptr ? "/tmp" : getenv("TMPDIR")} +
                             "/devbox-cpp-L3-001-mmap-files";
    const std::string data_path = base + "-data";
    const std::string empty_path = base + "-empty";
    constexpr char content[] = "mapped-data";
    constexpr std::size_t content_bytes = sizeof(content) - 1;

    if (!write_file(data_path.c_str(), content, content_bytes) ||
        !write_file(empty_path.c_str(), "", 0)) {
        return 1;
    }
    if (!map_and_print(data_path.c_str()) || !map_and_print(empty_path.c_str())) {
        return 1;
    }
    if (unlink(data_path.c_str()) == -1 || unlink(empty_path.c_str()) == -1) {
        std::perror("unlink");
        return 1;
    }
}
