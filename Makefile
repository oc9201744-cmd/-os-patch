export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BypassTweak

# --- OTOMATİK KURULUM FIX ---
# Sadece bir kez çalışması için kontrol ekliyoruz
ifeq ($(KITTY_READY),)
$(shell [ ! -d KittyMemory ] && git clone https://github.com/joeyjurjens/KittyMemory.git)
export KITTY_READY = 1
endif

$(TWEAK_NAME)_FILES = Tweak.mm $(wildcard KittyMemory/KittyMemory/*.cpp)
# KittyMemory'nin içindeki dosyaları bulabilmesi için header yollarını kesinleştiriyoruz
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -IKittyMemory/KittyMemory -Iinclude -Wno-error
$(TWEAK_NAME)_LDFLAGS = -L. -ldobby -lobjc -undefined dynamic_lookup
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation Security

include $(THEOS_MAKE_PATH)/tweak.mk
