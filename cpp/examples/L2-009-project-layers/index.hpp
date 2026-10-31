#ifndef DEVBOX_L2_009_INDEX_HPP
#define DEVBOX_L2_009_INDEX_HPP

#include <string_view>

#include "storage.hpp"

class Index {
 public:
  std::string_view query(std::string_view term) const;

 private:
  Storage storage_;
};

#endif
