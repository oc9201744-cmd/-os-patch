export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BaybarsBypass
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Idobby_src/include -Idobby_src/source -Idobby_src/External/Logging -DDOBBY_GENERIC_ARM64
$(TWEAK_NAME)_LDFLAGS = -lpthread

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
