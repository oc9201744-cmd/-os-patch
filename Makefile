TARGET := iphone:clang:latest:13.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnoBypass
AnoBypass_FILES = Tweak.x
AnoBypass_CFLAGS = -fobjc-arc
AnoBypass_LDFLAGS = -L. -ldobby

include $(THEOS_MAKE_PATH)/tweak.mk
