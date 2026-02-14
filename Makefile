ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

# No-JB cihazlarda dylib'in imza hatalarını ve eksik kütüphane hatalarını önler
ADDITIONAL_CFLAGS = -Wno-deprecated-declarations -Wno-error=deprecated-declarations -fobjc-arc
AnoBypass_LDFLAGS += -undefined dynamic_lookup

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnoBypass
AnoBypass_FILES = Tweak.x
AnoBypass_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
