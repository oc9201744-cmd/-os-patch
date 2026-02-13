# Projenin adı
LIBRARY_NAME = TssBypass

# Hedef Mimari (iPhone 15 Pro Max için arm64e şart)
ARCHS = arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TssBypass_FILES = TssBypass.cpp
TssBypass_CFLAGS = -fobjc-arc -I./include
TssBypass_LDFLAGS = -L./ -ldobby

include $(THEOS_MAKE_PATH)/library.mk
