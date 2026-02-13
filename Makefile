ARCHS = arm64
TARGET = iphone:clang:latest:14.0
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = antibanpatch

antibanpatch_FILES = Tweak.mm
antibanpatch_LIBRARIES = substrate
antibanpatch_FRAMEWORKS = UIKit Foundation
antibanpatch_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
