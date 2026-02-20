# THEOS yolunu ortam değişkeninden al, yoksa varsayılanı kullan
THEOS_PATH = $(THEOS)
ifeq ($(THEOS_PATH),)
  THEOS_PATH = /Users/runner/theos
endif

ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BypassTweak

BypassTweak_FILES = Tweak.mk
BypassTweak_CCFLAGS = -std=c++11 -fno-modules
BypassTweak_LDFLAGS = -ldobby

# Theos dosyalarını dahil etme (Doğru yol yapısı)
include $(THEOS_PATH)/makefiles/common.mk
include $(THEOS_PATH)/makefiles/tweak.mk
