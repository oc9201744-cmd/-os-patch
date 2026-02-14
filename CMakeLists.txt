cmake_minimum_required(VERSION 3.14)
project(GeminiBypass LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)

add_library(GeminiBypass SHARED
    src/GeminiMemoryPatch.cpp
)

set_target_properties(GeminiBypass PROPERTIES
    OUTPUT_NAME "GeminiBypass"
    PREFIX ""
    SUFFIX ".dylib"
)

target_compile_options(GeminiBypass PRIVATE -Os -fvisibility=hidden)
target_link_libraries(GeminiBypass "-framework Foundation" "-framework UIKit")