#include <iostream>

enum class State { ready = 1, running = 2 };

const char* state_name(State state) {
  switch (state) {
    case State::ready:
      return "ready";
    case State::running:
      return "running";
  }
  return "unknown";
}

int main() {
  const State state = State::running;
  const int serialized_value = static_cast<int>(state);

  std::cout << "state: " << state_name(state) << '\n';
  std::cout << "serialized value: " << serialized_value << '\n';
}
