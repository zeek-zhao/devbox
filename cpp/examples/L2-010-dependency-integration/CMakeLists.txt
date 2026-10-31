cmake_minimum_required(VERSION 3.16)
project(dependency_integration LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
find_package(Threads REQUIRED)
option(DEVBOX_ENABLE_OPTIONAL_LOGGING "Enable optional logging" OFF)

add_executable(dependency_demo main.cpp)
target_compile_features(dependency_demo PRIVATE cxx_std_20)
target_compile_options(dependency_demo PRIVATE -Wall -Wextra -pedantic)
target_link_libraries(dependency_demo PRIVATE Threads::Threads)
target_compile_definitions(
  dependency_demo PRIVATE
  DEVBOX_ENABLE_OPTIONAL_LOGGING=$<BOOL:${DEVBOX_ENABLE_OPTIONAL_LOGGING}>
)
