export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BaybarsBypass
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_LDFLAGS = ./libdobby.a

# -I./include ekleyerek derleyicinin include klasörüne bakmasını sağladık
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -I. -I./include

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
