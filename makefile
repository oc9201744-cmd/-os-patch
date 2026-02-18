export THEOS_DEVICE_IP = 127.0.0.1
TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BaybarsBypass

BaybarsBypass_FILES = Health.xm
BaybarsBypass_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-error
BaybarsBypass_LIBRARIES = substrate

# PLİST HATASINI ÇÖZEN SATIR (Eğer dosya adın farklıysa burayı düzelt)
BaybarsBypass_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/

include $(THEOS)/makefiles/tweak.mk
