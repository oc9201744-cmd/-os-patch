export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0
export SYSROOT = $(THEOS)/sdks/iPhoneOS14.5.sdk # SDK yoluna göre düzenle

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BypassTweak

# .xm yerine .mm kullanarak Logos işlemcisini (Substrate gerektiren) devre dışı bırakıyoruz
$(TWEAK_NAME)_FILES = Tweak.mm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Iinclude
# Substrate'i aramayı durduran ve Dobby'yi bağlayan sihirli satır:
$(TWEAK_NAME)_LDFLAGS = -L. -ldobby -undefined dynamic_lookup

$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation Security

include $(THEOS_MAKE_PATH)/tweak.mk
