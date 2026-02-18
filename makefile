export THEOS_DEVICE_IP = 127.0.0.1
TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BaybarsBypass

# Burada Health.xm dosyasını derlemesini söylüyoruz
BaybarsBypass_FILES = Health.xm
BaybarsBypass_CFLAGS = -fobjc-arc
# Jailbreak'siz cihazlar için Substrate kütüphanesini ekliyoruz
BaybarsBypass_LIBRARIES = substrate

include $(THEOS)/makefiles/tweak.mk
