export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BypassTweak

# --- OTOMATİK KURULUM VE YOL DÜZELTME ---
ifeq ($(wildcard KittyMemory/KittyMemory.hpp),)
$(shell git clone https://github.com/joeyjurjens/KittyMemory.git)
# Dosyaları üst klasöre taşıyarak yolu basitleştiriyoruz
$(shell cp -r KittyMemory/KittyMemory/* KittyMemory/)
endif

$(TWEAK_NAME)_FILES = Tweak.mm $(wildcard KittyMemory/*.cpp)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -IKittyMemory -Iinclude -Wno-error
$(TWEAK_NAME)_LDFLAGS = -L. -ldobby -lobjc -undefined dynamic_lookup
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation Security

include $(THEOS_MAKE_PATH)/tweak.mk
