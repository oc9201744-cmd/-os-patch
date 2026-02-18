export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BaybarsBypass

$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
