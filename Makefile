ARCHS = arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = TssBypass
TssBypass_FILES = TssBypass.cpp
TssBypass_CFLAGS = -fobjc-arc -I./include -Wno-module-import-in-extern-c
# libdobby.a dosyasını dizinde arayıp bağlar
TssBypass_LDFLAGS = -L./ -ldobby

include $(THEOS_MAKE_PATH)/library.mk
