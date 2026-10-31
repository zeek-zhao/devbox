#include <iostream>

struct Point {
  int x;
  int y;

  Point operator+(const Point& other) const {
    return {x + other.x, y + other.y};
  }

  bool operator==(const Point& other) const {
    return x == other.x && y == other.y;
  }
};

int main() {
  const Point first{1, 2};
  const Point second{3, 4};
  const Point third{2, 2};
  const Point sum = first + second + third;
  const Point expected{6, 8};

  std::cout << "sum: (" << sum.x << ',' << sum.y << ")\n";
  std::cout << "equal: " << (sum == expected ? "true" : "false") << '\n';
}
