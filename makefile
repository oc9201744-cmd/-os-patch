export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BaybarsBypass

# Tweak dosyan ve Dobby'nin ana kaynak dosyası (Static Linker hatasını çözer)
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -I./include -Idobby_src/include -Idobby_src/source
# Dobby'yi hazır kütüphane yerine "Framework" gibi bağlayacağız (Hata vermemesi için en temizi)
$(TWEAK_NAME)_LDFLAGS = -L./ -ldobby_static

# Dobby'nin statik kütüphanesini indirmek yerine Makefile içinde arıyoruz
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
