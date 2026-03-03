cmake_minimum_required(VERSION 3.20)
project(Tohum VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Core VM library
add_library(tohum_core STATIC
    src/value.cpp
    src/vm.cpp
)
target_include_directories(tohum_core PUBLIC include)

# REPL executable
add_executable(tohum src/main.cpp)
target_link_libraries(tohum PRIVATE tohum_core)

# Install
install(TARGETS tohum RUNTIME DESTINATION bin)
