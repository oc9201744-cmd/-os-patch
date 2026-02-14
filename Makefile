# Proje Hedefleri
TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e
DEBUG := 0
FINALPACKAGE := 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AnoBypass

# Derlenecek dosyalar
AnoBypass_FILES = Tweak.x
# ARC (Automatic Reference Counting) kullanımı
AnoBypass_CFLAGS = -fobjc-arc
# Gerekli frameworkler (Analizdeki UI öğeleri için)
AnoBypass_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
