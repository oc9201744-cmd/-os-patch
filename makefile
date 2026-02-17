TARGET := iphone:clang:latest:13.0
ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SecureBypass
# BURASI ÇOK ÖNEMLİ: Uzantı .xm olmalı
SecureBypass_FILES = Tweak.xm
SecureBypass_CFLAGS = -fobjc-arc
# UI için gerekli kütüphaneler
SecureBypass_FRAMEWORKS = UIKit Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
