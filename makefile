# Baybars Bypass - Professional Makefile
# iOS 17 & 18 Support for iPhone 15 Pro (arm64e)

export THEOS_DEVICE_IP = 127.0.0.1
TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BaybarsBypass

# Dosyalar
BaybarsBypass_FILES = Health.xm

# Flagler: -Wno-error sayesinde "deprecated" uyarıları derlemeyi durdurmaz
BaybarsBypass_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-error

# Kütüphaneler
BaybarsBypass_LIBRARIES = substrate

include $(THEOS)/makefiles/tweak.mk

# Derleme sonrası temizlik
after-install::
	install.exec "killall -9 ShadowTrackerExtra"
