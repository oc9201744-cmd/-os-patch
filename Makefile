# Mimari ve iOS sürümü
export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

# Proje adı
TWEAK_NAME = BaybarsBypass

# Derlenecek dosya
$(TWEAK_NAME)_FILES = Tweak.mm

# Dobby kütüphanesini ve header klasörünü tanıtıyoruz
$(TWEAK_NAME)_LDFLAGS = ./libdobby.a
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -I. -I./include

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
