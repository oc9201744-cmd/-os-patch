export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BaybarsBypass

# Dobby'nin çekirdek dosyalarını doğrudan derlemeye dahil ediyoruz
$(TWEAK_NAME)_FILES = Tweak.xm dobby_src/source/dobby.cpp $(wildcard dobby_src/source/MemoryAllocator/*.cc) $(wildcard dobby_src/source/Backend/ARM64/*.cc) $(wildcard dobby_src/source/Backend/UserMode/*.cc)

$(TWEAK_NAME)_CFLAGS = -fobjc-arc -I./include -Idobby_src/include -Idobby_src/source -Idobby_src/External/Logging -DDOBBY_GENERIC_ARM64
$(TWEAK_NAME)_LDFLAGS = -lpthread

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
