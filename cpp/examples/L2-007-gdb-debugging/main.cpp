#include <iostream>

void report_query_error() { std::cout << "query error reported\n"; }

void find_query() { report_query_error(); }

int main() {
  find_query();
  return 0;
}
