cmake_minimum_required(VERSION 3.14)

set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/ios.toolchain.cmake" CACHE PATH "")
set(PLATFORM OS64COMBINED CACHE STRING "")
set(DEPLOYMENT_TARGET "13.0" CACHE STRING "")

project(GeminiBypass LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ARC'yi kapat (iOS patch'lerde sorun çıkarıyor)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "NO")

add_library(GeminiBypass SHARED
    src/GeminiMemoryPatch.cpp
)

set_target_properties(GeminiBypass PROPERTIES
    OUTPUT_NAME "GeminiBypass"
    PREFIX ""
    SUFFIX ".dylib"
)

# Daha az hata için
target_compile_options(GeminiBypass PRIVATE
    -Os
    -fvisibility=hidden
    -fno-objc-arc
)

target_link_libraries(GeminiBypass
    "-framework Foundation"
    "-framework UIKit"
    "-framework CoreFoundation"
    "-framework IOKit"  # Ekstra: iOS'ta mach port için
)