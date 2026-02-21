export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BypassTweak

# YAML tarafından indirilen KittyMemory dosyaları
KITTY_SRC = $(wildcard KittyMemory/*.cpp)

$(TWEAK_NAME)_FILES = Tweak.mm $(KITTY_SRC)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -IKittyMemory -Iinclude -DkNO_KEYSTONE -std=c++11
$(TWEAK_NAME)_LDFLAGS = -L. -ldobby -lobjc -undefined dynamic_lookup
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation Security

include $(THEOS_MAKE_PATH)/tweak.mk
