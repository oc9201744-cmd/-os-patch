# iPhone 15 Pro Max ve iOS 15+ için arm64e şart
ARCHS = arm64e
TARGET = iphone:clang:latest:15.0

# Rootless (Dopamine vb.) için bunu açık tutuyoruz
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = TssBypass
# Dosya adını .mm yaptığımız için burada da güncelliyoruz
TssBypass_FILES = TssBypass.mm
TssBypass_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
