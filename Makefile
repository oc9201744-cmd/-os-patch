export ARCHS = arm64e
export TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BypassTweak

# Dosyanın adı Tweak.mm olduğu için
$(TWEAK_NAME)_FILES = Tweak.mm

$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Iinclude
# libdobby.a ana dizinde olduğu için -L. kullanıyoruz
$(TWEAK_NAME)_LDFLAGS = -L. -ldobby

include $(THEOS_MAKE_PATH)/tweak.mk
