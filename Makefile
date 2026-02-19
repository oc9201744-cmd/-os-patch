export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BypassTweak

# İsim birebir aynı olmalı: Tweak.mm
$(TWEAK_NAME)_FILES = Tweak.mm

$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Iinclude
$(TWEAK_NAME)_LDFLAGS = -Llibs -ldobby

include $(THEOS_MAKE_PATH)/tweak.mk
