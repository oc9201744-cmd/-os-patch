ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BypassTweak
BypassTweak_FILES = Tweak.xm
BypassTweak_CFLAGS = -I./include   # include klasöründeki dobby.h için
BypassTweak_LDFLAGS = -L. -ldobby   # ana dizindeki libdobby.a için

include $(THEOS_MAKE_PATH)/tweak.mk
