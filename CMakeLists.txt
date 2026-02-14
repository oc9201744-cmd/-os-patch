# ios-cmake toolchain (2025-2026 uyumlu, PLATFORM zorunluluğunu kaldırdık)
# https://github.com/leetal/ios-cmake

cmake_minimum_required(VERSION 3.14)

# Default platform if not set
if(NOT PLATFORM)
  set(PLATFORM OS64COMBINED CACHE STRING "Target platform" FORCE)
endif()

if(NOT DEPLOYMENT_TARGET)
  set(DEPLOYMENT_TARGET "13.0" CACHE STRING "Minimum iOS version" FORCE)
endif()

# Sysroot and architectures
if(PLATFORM MATCHES "OS.*")
  set(CMAKE_OSX_SYSROOT iphoneos)
  set(CMAKE_OSX_ARCHITECTURES "arm64;arm64e")
elseif(PLATFORM MATCHES "SIMULATOR.*")
  set(CMAKE_OSX_SYSROOT iphonesimulator)
  set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
elseif(PLATFORM STREQUAL "MACCATALYST")
  set(CMAKE_OSX_SYSROOT macosx)
  set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
else()
  message(FATAL_ERROR "Unknown platform: ${PLATFORM}. Valid: OS64COMBINED, SIMULATORARM64, etc.")
endif()

set(CMAKE_OSX_DEPLOYMENT_TARGET "${DEPLOYMENT_TARGET}" CACHE STRING "Deployment target" FORCE)

message(STATUS "Platform: ${PLATFORM}")
message(STATUS "Architectures: ${CMAKE_OSX_ARCHITECTURES}")
message(STATUS "Deployment target: ${CMAKE_OSX_DEPLOYMENT_TARGET}")
message(STATUS "Sysroot: ${CMAKE_OSX_SYSROOT}")