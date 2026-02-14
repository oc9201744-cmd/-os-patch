cmake_minimum_required(VERSION 3.14)

# iPhone 15 Pro Max (A17 Pro) için arm64e şarttır
set(CMAKE_OSX_ARCHITECTURES "arm64;arm64e")
set(CMAKE_OSX_SYSROOT "iphoneos")
set(CMAKE_OSX_DEPLOYMENT_TARGET "15.0")

# Proje dillerine OBJCXX ekliyoruz
project(GeminiBypass LANGUAGES CXX OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ARC'yi kapat (Yama yaparken hata vermemesi için)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "NO")

# Kaynak dosya: src/ içindeki GeminiMemoryPatch.cpp
add_library(GeminiBypass SHARED
    src/GeminiMemoryPatch.cpp
)

# ÖNEMLİ: .cpp dosyasını Objective-C++ olarak derlemesini zorla
set_source_files_properties(src/GeminiMemoryPatch.cpp PROPERTIES COMPILE_FLAGS "-x objective-c++")

set_target_properties(GeminiBypass PROPERTIES
    OUTPUT_NAME "GeminiBypass"
    PREFIX ""
    SUFFIX ".dylib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

# Derleme bayrakları
target_compile_options(GeminiBypass PRIVATE
    -Os
    -fvisibility=hidden
    -fno-objc-arc
)

# Ban analizi (Ioctl/Lock) için gerekli Framework'ler
target_link_libraries(GeminiBypass
    "-framework Foundation"
    "-framework UIKit"
    "-framework CoreFoundation"
    "-framework Security"
    "-framework IOKit"
)
