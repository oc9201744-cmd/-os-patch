# THEOS yolunu otomatik algıla
THEOS_DEVICE_IP = 127.0.0.1
THEOS_DEVICE_PORT = 2222

ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BypassTweak

# BURASI ÇOK KRİTİK: Dosya adının Tweak.mm olduğundan emin ol
BypassTweak_FILES = Tweak.mm
BypassTweak_CCFLAGS = -std=c++11 -fno-modules
BypassTweak_LDFLAGS = -ldobby

# Theos dosyalarını dahil et
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
