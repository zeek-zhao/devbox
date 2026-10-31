#ifndef DEVBOX_L2_009_COMMAND_HPP
#define DEVBOX_L2_009_COMMAND_HPP

#include <string_view>

class Command {
 public:
  void execute(std::string_view term) const;
};

#endif
