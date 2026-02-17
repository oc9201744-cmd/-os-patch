# Dosya adın Tweak.mm olduğu için buraya tam yazıyoruz
TWEAK_NAME = SecureBypass
SecureBypass_FILES = Tweak.mm
SecureBypass_FRAMEWORKS = UIKit Foundation AudioToolbox
SecureBypass_LIBRARIES = substrate

# Mimari ayarları (Non-JB için arm64 şart)
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0

# Derleme sırasında imzalama hatasını engelle
export SIGN_SKIP = 1

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
