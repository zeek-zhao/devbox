#include <iostream>
#include <string>
#include <string_view>

int main() {
    std::string source{"query"};
    const std::string_view view{source};
    const std::string owned{view};

    source[0] = 'Q';

    std::cout << "view: " << view << '\n';
    std::cout << "owned: " << owned << '\n';
}
