#ifndef DEVBOX_L2_009_STORAGE_HPP
#define DEVBOX_L2_009_STORAGE_HPP

#include <string_view>

class Storage {
public:
    std::string_view find(std::string_view term) const;
};

#endif
