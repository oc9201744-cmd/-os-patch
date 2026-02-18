export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BaybarsBypass
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

# Hata veren eski satırı sil ve bunu yapıştır:
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
