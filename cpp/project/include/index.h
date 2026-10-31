#ifndef DEVBOX_CPP_PROJECT_INDEX_H
#define DEVBOX_CPP_PROJECT_INDEX_H

#include <cstddef>
#include <string>
#include <unordered_map>
#include <vector>

namespace devbox {

class InvertedIndex {
 public:
  bool build(const std::string& path);
  const std::vector<std::size_t>* find(const std::string& query) const;
  const std::string& line(std::size_t one_based_line) const;

 private:
  std::unordered_map<std::string, std::vector<std::size_t>> postings_;
  std::vector<std::string> lines_;
};

}  // namespace devbox

#endif
