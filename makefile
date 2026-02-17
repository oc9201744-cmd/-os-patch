# Mimariyi arm64 ve arm64e (yeni cihazlar) olarak tutuyoruz
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:13.0

# Jailsiz sistemlerde kütüphaneyi bağımsız (standalone) yapar
export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

# TWEAK_NAME yerine LIBRARY_NAME kullanarak dylib çıktısı alıyoruz
LIBRARY_NAME = Health
Health_FILES = Health.xm
Health_CFLAGS = -fobjc-arc

# Kingmod'un kullandığı sistem kütüphaneleri (Frameworkler)
Health_FRAMEWORKS = UIKit Foundation CoreGraphics
# Bellek izinleri için gerekli LDFLAGS
Health_LDFLAGS = -Wl,-segprot,__TEXT,rwx,rwx

include $(THEOS_MAKE_PATH)/library.mk
