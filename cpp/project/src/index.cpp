#include "index.h"

#include <cstddef>
#include <fcntl.h>
#include <string>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <utility>

namespace devbox {
namespace {

class MappedFile {
 public:
  explicit MappedFile(const std::string& path) {
    descriptor_ = open(path.c_str(), O_RDONLY);
    if (descriptor_ == -1) {
      return;
    }

    struct stat status {};
    if (fstat(descriptor_, &status) == -1 || status.st_size < 0) {
      close_descriptor();
      return;
    }

    size_ = static_cast<std::size_t>(status.st_size);
    if (size_ == 0) {
      valid_ = true;
      return;
    }

    void* mapping = mmap(nullptr, size_, PROT_READ, MAP_PRIVATE, descriptor_, 0);
    if (mapping == MAP_FAILED) {
      close_descriptor();
      size_ = 0;
      return;
    }
    data_ = static_cast<char*>(mapping);
    valid_ = true;
  }

  MappedFile(const MappedFile&) = delete;
  MappedFile& operator=(const MappedFile&) = delete;

  ~MappedFile() {
    if (data_ != nullptr) {
      munmap(data_, size_);
    }
    close_descriptor();
  }

  bool valid() const { return valid_; }
  const char* data() const { return data_; }
  std::size_t size() const { return size_; }

 private:
  void close_descriptor() {
    if (descriptor_ != -1) {
      close(descriptor_);
      descriptor_ = -1;
    }
  }

  int descriptor_ = -1;
  char* data_ = nullptr;
  std::size_t size_ = 0;
  bool valid_ = false;
};

bool is_word_character(unsigned char character) {
  return (character >= 'a' && character <= 'z') ||
         (character >= 'A' && character <= 'Z') ||
         (character >= '0' && character <= '9');
}

char lowercase_ascii(unsigned char character) {
  if (character >= 'A' && character <= 'Z') {
    return static_cast<char>(character - 'A' + 'a');
  }
  return static_cast<char>(character);
}

template <typename Callback>
void for_each_token(const std::string& text, Callback&& callback) {
  std::size_t offset = 0;
  while (offset < text.size()) {
    while (offset < text.size() &&
           !is_word_character(static_cast<unsigned char>(text[offset]))) {
      ++offset;
    }

    const std::size_t start = offset;
    while (offset < text.size() &&
           is_word_character(static_cast<unsigned char>(text[offset]))) {
      ++offset;
    }
    if (start != offset) {
      std::string token;
      token.reserve(offset - start);
      for (std::size_t index = start; index < offset; ++index) {
        token.push_back(lowercase_ascii(static_cast<unsigned char>(text[index])));
      }
      callback(std::move(token));
    }
  }
}

}  // namespace

bool InvertedIndex::build(const std::string& path) {
  MappedFile file(path);
  if (!file.valid()) {
    return false;
  }

  std::unordered_map<std::string, std::vector<std::size_t>> new_postings;
  std::vector<std::string> new_lines;
  std::size_t offset = 0;

  while (offset < file.size()) {
    const std::size_t line_start = offset;
    while (offset < file.size() && file.data()[offset] != '\n') {
      ++offset;
    }
    const std::size_t line_number = new_lines.size() + 1;
    std::string text(file.data() + line_start, offset - line_start);
    new_lines.push_back(text);
    for_each_token(text, [&new_postings, line_number](std::string token) {
      auto& postings = new_postings[token];
      if (postings.empty() || postings.back() != line_number) {
        postings.push_back(line_number);
      }
    });
    if (offset < file.size()) {
      ++offset;
    }
  }

  postings_ = std::move(new_postings);
  lines_ = std::move(new_lines);
  return true;
}

const std::vector<std::size_t>* InvertedIndex::find(const std::string& query) const {
  std::string normalized;
  normalized.reserve(query.size());
  for (const unsigned char character : query) {
    if (!is_word_character(character)) {
      return nullptr;
    }
    normalized.push_back(lowercase_ascii(character));
  }
  if (normalized.empty()) {
    return nullptr;
  }

  const auto found = postings_.find(normalized);
  return found == postings_.end() ? nullptr : &found->second;
}

const std::string& InvertedIndex::line(std::size_t one_based_line) const {
  return lines_.at(one_based_line - 1);
}

}  // namespace devbox
