# iPhone 15 Pro Max (A17 Pro) için arm64e şart
ARCHS = arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = TssBypass

# Dosya isminin TssBypass.cpp olduğundan emin ol
TssBypass_FILES = TssBypass.cpp

# CFLAGS: Modül hatalarını ve PAC uyarılarını susturur
TssBypass_CFLAGS = -fobjc-arc -I./include -Wno-module-import-in-extern-c -Wno-unused-variable -Wno-unused-function

# LDFLAGS: arm64e kütüphanesini (libdobby.dylib) bağlar
TssBypass_LDFLAGS = -L./ -ldobby -Xlinker -fatal_warnings -Xlinker -no_warn_duplicate_libraries

include $(THEOS_MAKE_PATH)/library.mk

# Temizlik
clean::
	rm -rf .theos packages
