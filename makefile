ARCHS = arm64
TARGET := iphone:clang:latest:13.0
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SecureBypass
SecureBypass_FILES = Tweak.xm
SecureBypass_CFLAGS = -fobjc-arc
SecureBypass_FRAMEWORKS = UIKit Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
