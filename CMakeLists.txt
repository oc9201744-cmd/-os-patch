# Minimum CMake sürümü
cmake_minimum_required(VERSION 3.14)

# iOS için toolchain dosyasını kullan (ios.toolchain.cmake)
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/ios.toolchain.cmake" CACHE PATH "iOS toolchain")

# iOS platform tipi (cihaz + simulator kombine)
set(PLATFORM OS64COMBINED CACHE STRING "iOS platform type")

# Minimum iOS sürümü
set(DEPLOYMENT_TARGET "13.0" CACHE STRING "Minimum iOS version")

# Proje adı ve dili
project(GeminiBypass LANGUAGES CXX)

# C++ standardı
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Derlenecek dosya
add_library(GeminiBypass SHARED
    src/GeminiMemoryPatch.cpp
)

# Çıktı ayarları (.dylib olsun)
set_target_properties(GeminiBypass PROPERTIES
    OUTPUT_NAME "GeminiBypass"
    PREFIX ""
    SUFFIX ".dylib"
)

# Derleme seçenekleri (küçük ve gizli olsun)
target_compile_options(GeminiBypass PRIVATE
    -Os
    -fvisibility=hidden
    -fvisibility-inlines-hidden
    -fno-objc-arc
    -Wno-deprecated-declarations
)

# Bağlanacak framework'ler
target_link_libraries(GeminiBypass
    "-framework Foundation"
    "-framework UIKit"
    "-framework CoreFoundation"
)