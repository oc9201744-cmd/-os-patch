# Mimariyi arm64 yapıyoruz (Jailsiz cihazlar için en stabil olanı)
ARCHS = arm64
TARGET := iphone:clang:latest:13.0

# DEBUG modunu kapatıyoruz ki dylib boyutu küçük ve hızlı olsun
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

# TWEAK_NAME yerine LIBRARY_NAME kullanıyoruz (.dylib çıktısı için)
LIBRARY_NAME = Health
Health_FILES = Health.xm
Health_CFLAGS = -fobjc-arc

# Jailsiz cihazda MSHook yerine kendi yama motorumuzu kullanacağımız için 
# harici framework bağımlılığını (Substrate) minimuma indiriyoruz.
Health_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/library.mk
