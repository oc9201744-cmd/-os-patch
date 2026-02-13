ARCHS = arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = TssBypass
TssBypass_FILES = TssBypass.cpp
TssBypass_CFLAGS = -fobjc-arc -I./include -Wno-module-import-in-extern-c -Wno-unused-variable -Wno-unused-function
TssBypass_LDFLAGS = -L./ -ldobby -Xlinker -fatal_warnings -Xlinker -no_warn_duplicate_libraries

include $(THEOS_MAKE_PATH)/library.mk

clean::
	rm -rf .theos packages
