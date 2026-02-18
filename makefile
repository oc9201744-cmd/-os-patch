export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BaybarsBypass
$(TWEAK_NAME)_FILES = Tweak.xm
# Dobby kütüphanesini dylib içine statik olarak gömer
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -I./include -fptrauth-calls
$(TWEAK_NAME)_LDFLAGS = -L./ -ldobby

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
