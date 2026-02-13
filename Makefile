ARCHS = arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = TssBypass
TssBypass_FILES = TssBypass.cpp

# Header dosyasını include klasöründen okur
TssBypass_CFLAGS = -fobjc-arc -I./include -Wno-module-import-in-extern-c -Wno-unused-variable

# Eğer libdobby.a dosyan ana dizindeyse bu çalışır
TssBypass_LDFLAGS = -L./ -ldobby

include $(THEOS_MAKE_PATH)/library.mk
