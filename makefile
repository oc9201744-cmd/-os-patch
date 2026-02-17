TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SecureBypass
SecureBypass_FILES = Tweak.mm
SecureBypass_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
SecureBypass_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"