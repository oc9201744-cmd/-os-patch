# Mimariyi hem eski hem yeni nesil iPhone'lar için ayarlıyoruz
export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

# Proje Adı
TWEAK_NAME = BaybarsBypass

# Derlenecek dosyalar
$(TWEAK_NAME)_FILES = Tweak.xm

# Derleme seçenekleri: ARC açık, include klasörünü gösteriyoruz
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -I./include

# KRİTİK SATIR: Linker'a kütüphanenin tam yolunu veriyoruz
# -L./ -ldobby yerine direkt dosya ismini yazmak "unknown file type" hatasını önler
$(TWEAK_NAME)_LDFLAGS = ./libdobby.a

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
