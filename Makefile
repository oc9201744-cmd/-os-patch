export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BypassTweak

# Rehberdeki tanımlamalar:
KITTYMEMORY_PATH = KittyMemory
KITTYMEMORY_SRC = $(wildcard $(KITTYMEMORY_PATH)/*.cpp)

# Tweak dosyalarına KittyMemory kaynaklarını ekle
$(TWEAK_NAME)_FILES = Tweak.mm $(KITTYMEMORY_SRC)

# C++11 gereksinimi ve Keystone'u devre dışı bırakma (Sadece Byte Patch kullanacağımız için)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -I$(KITTYMEMORY_PATH) -Iinclude -DkNO_KEYSTONE -std=c++11
$(TWEAK_NAME)_LDFLAGS = -L. -ldobby -lobjc -undefined dynamic_lookup
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation Security

include $(THEOS_MAKE_PATH)/tweak.mk
