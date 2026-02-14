# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

#  Copyright (c) 2011 Petroules Corporation
#  Copyright (c) 2015-2020 Alexander Lamaison
#  Copyright (c) 2018-2020 Ruslan Baratov
#  All rights reserved.

# This file is part of the ios-cmake project, which is released under the
# BSD 3-Clause license. See https://github.com/leetal/ios-cmake

# This file defines the following variables:
#   PLATFORM: the iOS platform being compiled for (e.g. OS64, SIMULATORARM64, etc.)
#   CMAKE_OSX_SYSROOT: the SDK path
#   CMAKE_OSX_ARCHITECTURES: the architectures to build for
#   CMAKE_OSX_DEPLOYMENT_TARGET: the minimum deployment target

cmake_minimum_required(VERSION 3.14...3.28)

option(ENABLE_ARC "Whether ARC is enabled" ON)
option(ENABLE_BITCODE "Whether to enable bitcode" OFF)
option(ENABLE_ARC_OR_BITCODE "Whether ARC or bitcode is enabled" ON)

set(ALL_VALID_ARCHS "arm64;arm64e;x86_64;armv7;armv7s")

set(PLATFORM "" CACHE STRING "Target platform to build for")
set_property(CACHE PLATFORM PROPERTY STRINGS
    OS64 OS64COMBINED SIMULATORARM64 SIMULATOR64 SIMULATORARMV7 SIMULATORARMV7S SIMULATORX86_64 MACCATALYST
)

set(DEPLOYMENT_TARGET "" CACHE STRING "Minimum iOS version")
set(ARCHS "" CACHE STRING "Architectures to build for")

if(NOT PLATFORM)
    message(FATAL_ERROR "PLATFORM must be set (e.g. OS64, OS64COMBINED, SIMULATORARM64)")
endif()

if(NOT DEPLOYMENT_TARGET)
    if(PLATFORM MATCHES "OS.*")
        set(DEPLOYMENT_TARGET "13.0" CACHE STRING "Minimum iOS version" FORCE)
    elseif(PLATFORM MATCHES "SIMULATOR.*")
        set(DEPLOYMENT_TARGET "13.0" CACHE STRING "Minimum iOS version" FORCE)
    elseif(PLATFORM STREQUAL "MACCATALYST")
        set(DEPLOYMENT_TARGET "13.0" CACHE STRING "Minimum macOS version" FORCE)
    else()
        message(FATAL_ERROR "Unknown platform: ${PLATFORM}")
    endif()
endif()

# Set SDK name
if(PLATFORM MATCHES "OS.*")
    set(CMAKE_OSX_SYSROOT iphoneos)
elseif(PLATFORM MATCHES "SIMULATOR.*")
    set(CMAKE_OSX_SYSROOT iphonesimulator)
elseif(PLATFORM STREQUAL "MACCATALYST")
    set(CMAKE_OSX_SYSROOT macosx)
else()
    message(FATAL_ERROR "Unknown platform: ${PLATFORM}")
endif()

# Set architectures
if(ARCHS)
    set(CMAKE_OSX_ARCHITECTURES "${ARCHS}")
else()
    if(PLATFORM STREQUAL "OS64")
        set(CMAKE_OSX_ARCHITECTURES "arm64;arm64e")
    elseif(PLATFORM STREQUAL "OS64COMBINED")
        set(CMAKE_OSX_ARCHITECTURES "arm64;arm64e;x86_64")
    elseif(PLATFORM STREQUAL "SIMULATORARM64")
        set(CMAKE_OSX_ARCHITECTURES "arm64")
    elseif(PLATFORM STREQUAL "SIMULATOR64")
        set(CMAKE_OSX_ARCHITECTURES "x86_64")
    elseif(PLATFORM STREQUAL "MACCATALYST")
        set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
    else()
        message(FATAL_ERROR "Unknown platform: ${PLATFORM}")
    endif()
endif()

# Set deployment target
set(CMAKE_OSX_DEPLOYMENT_TARGET "${DEPLOYMENT_TARGET}" CACHE STRING "Deployment target" FORCE)

# Bitcode and ARC settings
if(ENABLE_BITCODE)
    set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE "YES")
else()
    set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE "NO")
endif()

if(ENABLE_ARC)
    set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES")
else()
    set(CMAKE_XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "NO")
endif()

message(STATUS "Platform: ${PLATFORM}")
message(STATUS "Architectures: ${CMAKE_OSX_ARCHITECTURES}")
message(STATUS "Deployment target: ${CMAKE_OSX_DEPLOYMENT_TARGET}")
message(STATUS "Sysroot: ${CMAKE_OSX_SYSROOT}")
