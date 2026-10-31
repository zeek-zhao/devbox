cmake_minimum_required(VERSION 3.16)
project(cmake_targets_demo LANGUAGES CXX)

add_library(message src/message.cpp include/message.hpp)
target_compile_features(message PUBLIC cxx_std_20)
target_compile_options(message PRIVATE -Wall -Wextra -pedantic)
target_include_directories(message PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include")

add_executable(cmake-targets main.cpp)
target_compile_options(cmake-targets PRIVATE -Wall -Wextra -pedantic)
target_link_libraries(cmake-targets PRIVATE message)
set_target_properties(message cmake-targets PROPERTIES CXX_EXTENSIONS OFF)

install(TARGETS cmake-targets RUNTIME DESTINATION bin)
install(DIRECTORY include/ DESTINATION include)
