#include <cstdlib>
#include <iostream>

extern "C" int api_create_message(int value, char** out_message);

int main() {
    char* message = nullptr;
    const int status = api_create_message(42, &message);
    if (status != 0) {
        std::cout << "status: " << status << '\n';
        return 1;
    }

    std::cout << "status: " << status << "\nmessage: " << message
              << "\nownership: C allocates; C++ calls free\n";
    std::free(message);

    const int invalid_output_status = api_create_message(42, nullptr);
    std::cout << "null-output-error: " << invalid_output_status << '\n';
    return invalid_output_status == 1 ? 0 : 1;
}
