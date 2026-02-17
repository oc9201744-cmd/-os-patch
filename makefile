# Paralel derleme için (Hızlandırır)
export MAKEFLAGS = -j$(shell nproc 2>/dev/null || sysctl -n hw.ncpu)

TARGET := iphone:clang:latest:13.0
ARCHS = arm64
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SecureBypass
# Dosya adını .xm yaptığına emin ol!
SecureBypass_FILES = Tweak.xm
SecureBypass_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
