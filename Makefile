TARGET = bypass
ARCHS = arm64
SDKVERSION = 16.0

# Compiler and linker flags
CC = clang
CXX = clang++

# Include paths (include/dobby.h)
INCLUDE_PATHS = -I./include

# Library paths (libdobby.a is in the current directory)
LIBRARY_PATHS = -L.

# Libraries to link
LIBRARIES = -ldobby -framework Foundation -framework UIKit

# Compiler flags
CFLAGS = -arch $(ARCHS) -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) -miphoneos-version-min=12.0 $(INCLUDE_PATHS) -fobjc-arc
CXXFLAGS = $(CFLAGS) -std=c++17
LDFLAGS = -arch $(ARCHS) -isysroot $(shell xcrun --sdk iphoneos --show-sdk-path) $(LIBRARY_PATHS) $(LIBRARIES)

# Source files
SOURCES = Tweak.mm

# Object files
OBJECTS = $(SOURCES:.mm=.o)

all: $(TARGET).dylib

$(TARGET).dylib: $(OBJECTS)
	$(CXX) $(OBJECTS) $(LDFLAGS) -dynamiclib -o $@

%.o: %.mm
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET).dylib

install:
	@echo "Non-jailbroken device installation requires manual IPA injection."
