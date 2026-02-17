# Mimariyi arm64 ve arm64e (yeni cihazlar) olarak ayarlıyoruz
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:13.0

# Derleme sırasında debug loglarını kapatıp hızı artırır
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Health
# Tweak.xm adını Health.xm yaparak anogs.c taramasından kaçıyoruz
Health_FILES = Health.xm
Health_CFLAGS = -fobjc-arc

# UI ve Sistem fonksiyonları için gerekli frameworkler
Health_FRAMEWORKS = UIKit Foundation CoreGraphics

# --- KRİTİK SATIR: INTEGRITY BYPASS İÇİN BELLEK İZNİ ---
# Bu satır, kod bölümünü (TEXT segment) çalışma anında değiştirilebilir yapar.
# Dinamik hook ve patch işlemlerinin ban yedirmemesi için şarttır.
Health_LDFLAGS = -Wl,-segprot,__TEXT,rwx,rwx

include $(THEOS_MAKE_PATH)/tweak.mk

# Derlemeden sonra otomatik temizlik yapması için
after-install::
	install.exec "killall -9 ShadowTrackerExtra" # Oyunun adıyla değiştir
