# Mimari ve Hedef Sürüm
ARCHS = arm64
TARGET = iphone:clang:latest:14.0

# Hata ayıklama modunu kapat, son paket modunu aç
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

# Tweak Adı (Plist ve Control dosyasıyla uyumlu olmalı)
TWEAK_NAME = antibanpatch

# Derlenecek dosyalar
antibanpatch_FILES = Tweak.mm

# Gerekli Kütüphaneler
antibanpatch_LIBRARIES = substrate
antibanpatch_FRAMEWORKS = UIKit Foundation

# C++11 Standartları ve Uyarı Engelleme (Memory Patch için kritik)
antibanpatch_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -std=c++11
antibanpatch_CCFLAGS = -std=c++11

include $(THEOS_MAKE_PATH)/tweak.mk
