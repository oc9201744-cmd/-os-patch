ARCHS = arm64
TARGET := iphone:clang:latest:13.0
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = Health
Health_FILES = Health.xm
Health_CFLAGS = -fobjc-arc
# Integrity Bypass için gereken bellek flagleri
Health_LDFLAGS = -Wl,-segprot,__TEXT,rwx,rwx 

include $(THEOS_MAKE_PATH)/library.mk
