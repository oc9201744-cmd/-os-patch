ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BypassTweak
BypassTweak_FILES = Tweak.mm

# Modül hatasını kapatmak ve C++ standartlarını belirlemek için:
BypassTweak_CCFLAGS = -fno-modules -std=c++11
BypassTweak_LDFLAGS = -ldobby

include $(THEOS_MAKE_PATH)/tweak.mk
