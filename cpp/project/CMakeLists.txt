cmake_minimum_required(VERSION 3.28)
project(devbox_cpp_project VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# L2-001-multifile-odr L2-002-cmake-targets L2-003-reproducible-build
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
# L2-010-dependency-integration: platform Threads is explicit, no downloaded dependency.
find_package(Threads REQUIRED)
set(DEVBOX_SANITIZER "none" CACHE STRING "none, address or thread (separate build trees)")
set_property(CACHE DEVBOX_SANITIZER PROPERTY STRINGS none address thread)
# L2-006-sanitizers: never combine TSan with ASan.
if(NOT DEVBOX_SANITIZER MATCHES "^(none|address|thread)$")
    message(FATAL_ERROR "Unknown DEVBOX_SANITIZER: ${DEVBOX_SANITIZER}")
endif()

add_library(project_checks INTERFACE)
target_compile_options(project_checks INTERFACE -Wall -Wextra -Wpedantic -Werror)
if(DEVBOX_SANITIZER STREQUAL "address")
    target_compile_options(project_checks INTERFACE -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options(project_checks INTERFACE -fsanitize=address,undefined)
elseif(DEVBOX_SANITIZER STREQUAL "thread")
    target_compile_options(project_checks INTERFACE -fsanitize=thread -fno-omit-frame-pointer)
    target_link_options(project_checks INTERFACE -fsanitize=thread)
endif()

add_library(project_index src/index.cpp src/query.cpp src/index_c.cpp)
target_compile_features(project_index PUBLIC cxx_std_20)
target_include_directories(project_index PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
target_link_libraries(project_index PUBLIC Threads::Threads PRIVATE project_checks)

add_executable(devbox-cpp-project src/main.cpp)
target_link_libraries(devbox-cpp-project PRIVATE project_index)
target_link_libraries(devbox-cpp-project PRIVATE project_checks)
if(DEVBOX_SANITIZER STREQUAL "none")
    target_link_options(devbox-cpp-project PRIVATE -static-libstdc++ -static-libgcc)
endif()

add_executable(test_index tests/test_index.cpp tests/allocation_failure.cpp)
target_link_libraries(test_index PRIVATE project_index)
target_link_libraries(test_index PRIVATE project_checks)
target_compile_options(test_index PRIVATE -UNDEBUG)

add_executable(test_query tests/test_query.cpp)
target_link_libraries(test_query PRIVATE project_index project_checks)
target_compile_options(test_query PRIVATE -UNDEBUG)
add_executable(test_ffi tests/test_ffi.c)
target_link_libraries(test_ffi PRIVATE project_index project_checks)
target_compile_options(test_ffi PRIVATE -UNDEBUG)

add_executable(bench_index bench/bench_index.cpp)
target_link_libraries(bench_index PRIVATE project_index)
target_link_libraries(bench_index PRIVATE project_checks)

enable_testing()
add_test(NAME index_tests COMMAND test_index)
add_test(NAME query_tests COMMAND test_query)
add_test(NAME ffi_tests COMMAND test_ffi)
add_test(NAME cli_tests COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_cli.sh
    $<TARGET_FILE:devbox-cpp-project>)
set_tests_properties(index_tests query_tests ffi_tests cli_tests PROPERTIES TIMEOUT 60)
if(CMAKE_BUILD_TYPE STREQUAL "Debug" AND DEVBOX_SANITIZER STREQUAL "none")
    find_program(GDB_EXECUTABLE gdb)
    if(GDB_EXECUTABLE)
        add_test(NAME debugger_test COMMAND bash ${CMAKE_CURRENT_SOURCE_DIR}/tests/check-debug.sh
            $<TARGET_FILE:devbox-cpp-project>)
        set_tests_properties(debugger_test PROPERTIES TIMEOUT 60)
    endif()
endif()

install(TARGETS project_index devbox-cpp-project EXPORT devboxIndexTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES include/index.h include/index_c.h DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(EXPORT devboxIndexTargets NAMESPACE devbox:: DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/devboxIndex)
install(TARGETS project_checks EXPORT devboxIndexTargets)
configure_package_config_file(cmake/devboxIndexConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/devboxIndexConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/devboxIndex)
write_basic_package_version_file(${CMAKE_CURRENT_BINARY_DIR}/devboxIndexConfigVersion.cmake
    COMPATIBILITY SameMajorVersion)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/devboxIndexConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/devboxIndexConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/devboxIndex)

set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_GENERATOR TGZ)
include(CPack)
