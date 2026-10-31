cmake_minimum_required(VERSION 3.28)
project(devbox_cpp_project LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(project_index src/index.cpp)
target_include_directories(project_index PUBLIC include)
target_compile_options(project_index PRIVATE -Wall -Wextra -Wpedantic)

add_executable(devbox-cpp-project src/main.cpp)
target_link_libraries(devbox-cpp-project PRIVATE project_index)
target_compile_options(devbox-cpp-project PRIVATE -Wall -Wextra -Wpedantic)
target_link_options(devbox-cpp-project PRIVATE -static-libstdc++ -static-libgcc)

add_executable(test_index tests/test_index.cpp)
target_link_libraries(test_index PRIVATE project_index)
target_compile_options(test_index PRIVATE -Wall -Wextra -Wpedantic -UNDEBUG)

add_executable(bench_index bench/bench_index.cpp)
target_link_libraries(bench_index PRIVATE project_index)
target_compile_options(bench_index PRIVATE -Wall -Wextra -Wpedantic)

enable_testing()
add_test(NAME index_tests COMMAND test_index)
