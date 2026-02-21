export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BypassTweak

# --- OTOMATİK KURULUM DÜZELTMESİ ---
# Klasör varsa bile silip tertemiz çekmek veya yolu garantiye almak için
KITTY_CHECK := $(shell if [ ! -f KittyMemory/KittyMemory.hpp ]; then rm -rf KittyMemory; git clone https://github.com/joeyjurjens/KittyMemory.git; fi)

$(TWEAK_NAME)_FILES = Tweak.mm $(wildcard KittyMemory/KittyMemory/*.cpp)
# Üstteki satırda KittyMemory/KittyMemory/*.cpp yaptık çünkü repo içinde bir alt klasör daha olabiliyor.

$(TWEAK_NAME)_CFLAGS = -fobjc-arc -IKittyMemory -Iinclude -Wno-error
$(TWEAK_NAME)_LDFLAGS = -L. -ldobby -lobjc -undefined dynamic_lookup
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation Security

include $(THEOS_MAKE_PATH)/tweak.mk
