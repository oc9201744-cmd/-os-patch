# Mimari ve Hedef Sürüm
export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

# Tweak İsmi (Senin verdiğin isim)
TWEAK_NAME = BaybarsBypass

# Derlenecek dosyalar (.mm kullandığın için .mm yazdık)
$(TWEAK_NAME)_FILES = Tweak.mm

# CMake ile oluşan kütüphaneyi bağlıyoruz
$(TWEAK_NAME)_LDFLAGS = ./libdobby.a

# Include dizinlerini derleyiciye tanıtıyoruz (Hata almamak için kritik)
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -I. -I./include

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
