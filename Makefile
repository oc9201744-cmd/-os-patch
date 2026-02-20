# Mimari ve Hedef Sürüm
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BypassTweak
BypassTweak_FILES = Tweak.mm

# -L. geçerli dizine bakar, -ldobby libdobby.dylib dosyasını bağlar
BypassTweak_LDFLAGS = -L. -ldobby
BypassTweak_CCFLAGS = -std=c++11 -fno-modules

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
