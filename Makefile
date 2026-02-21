ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BypassTweak

# Sadece Tweak.xm dosyanı ve Dobby'yi dahil et
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Iinclude

# Substrate bağımlılığını tamamen yok eden ve Dobby'yi bağlayan satır:
$(TWEAK_NAME)_LDFLAGS = -L. -ldobby -undefined dynamic_lookup

# Sadece gerekli frameworkleri bırak
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
