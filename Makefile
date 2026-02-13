ARCHS = arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = TssBypass
TssBypass_FILES = TssBypass.cpp
TssBypass_CFLAGS = -fobjc-arc -I./include
TssBypass_LDFLAGS = -L./ -ldobby -Wl,-all_load

include $(THEOS_MAKE_PATH)/library.mk
