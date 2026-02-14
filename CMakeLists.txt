cmake_minimum_required(VERSION 3.14)

# A17 Pro (arm64e) ve iOS Ayarları
set(CMAKE_OSX_ARCHITECTURES "arm64;arm64e")
set(CMAKE_OSX_SYSROOT "iphoneos")
set(CMAKE_OSX_DEPLOYMENT_TARGET "15.0")

# Proje dillerine mutlaka OBJCXX eklemeliyiz (Çünkü .mm kullanıyoruz)
project(GeminiBypass LANGUAGES CXX OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ARC'yi kapatıyoruz (Memory Patch için manuel kontrol daha iyi)
set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "NO")

# GÖRÜNTÜYE GÖRE GÜNCELLENDİ: src içindeki .mm dosyanı ekliyoruz
add_library(GeminiBypass SHARED
    src/GeminiMemoryPatch.mm
)

set_target_properties(GeminiBypass PROPERTIES
    OUTPUT_NAME "GeminiBypass"
    PREFIX ""
    SUFFIX ".dylib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
)

# Derleme bayrakları ve Optimizasyon
target_compile_options(GeminiBypass PRIVATE
    -Os
    -fvisibility=hidden
    -fno-objc-arc
)

# Ban analizi (BEQ/Lock/Ioctl) için gerekli kütüphaneler
target_link_libraries(GeminiBypass
    "-framework Foundation"
    "-framework UIKit"
    "-framework CoreFoundation"
    "-framework Security"
    "-framework IOKit"
)
