# Baybars Pure iOS Memory Patch Makefile
# No Substrate - No Jailbreak Required

export THEOS_DEVICE_IP = 127.0.0.1
TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BaybarsBypass

# Ana kod dosyan
BaybarsBypass_FILES = Health.xm

# Flagler: Uyarıları hata sayma, iOS 17/18 için yolu aç
BaybarsBypass_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-error

# BURASI KRİTİK: Substrate kütüphanesini sildik, sadece iOS kütüphanelerini kullanacak
BaybarsBypass_LIBRARIES = 

include $(THEOS)/makefiles/tweak.mk
