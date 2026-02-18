export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BaybarsBypass

# Senin kodun + Dobby'nin ana dosyaları
$(TWEAK_NAME)_FILES = Tweak.xm $(wildcard dobby_src/source/*.cc) $(wildcard dobby_src/source/MemoryAllocator/*.cc) $(wildcard dobby_src/source/Backend/ARM64/*.cc)

$(TWEAK_NAME)_CFLAGS = -fobjc-arc -I./include -Idobby_src/include -Idobby_src/source -DDOBBY_GENERIC_ARM64
$(TWEAK_NAME)_LDFLAGS = -lpthread

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
