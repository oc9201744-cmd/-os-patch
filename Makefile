export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BypassTweak

# BURASI ÇOK ÖNEMLİ: Dosya adın DobbyProxy.cpp ise aynen böyle yazılmalı
$(TWEAK_NAME)_FILES = DobbyProxy.cpp

$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Iinclude
$(TWEAK_NAME)_LDFLAGS = -Llibs -ldobby

include $(THEOS_MAKE_PATH)/tweak.mk
