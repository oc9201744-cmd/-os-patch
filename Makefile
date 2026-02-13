# iPhone 15 Pro Max ve PAC desteği için arm64e şarttır
ARCHS = arm64e
# iOS 15 ve üzeri tüm cihazlarda (iOS 17/18 dahil) çalışması için target ayarı
TARGET = iphone:clang:latest:15.0

# Theos standart ayarlarını içeri aktar
include $(THEOS)/makefiles/common.mk

# Dinamik kütüphane adı (Dylib ismi)
LIBRARY_NAME = TssBypass

# Derlenecek dosyaların listesi
# Dosya adının TssBypass.cpp ile birebir aynı olduğundan emin ol!
TssBypass_FILES = TssBypass.cpp

# Derleme bayrakları (Compiler Flags)
# -fobjc-arc: Otomatik referans sayımı
# -I./include: Dobby header dosyaları için yol
# -Wno-module-import-in-extern-c: Aldığın hatayı çözen kritik bayrak
TssBypass_CFLAGS = -fobjc-arc -I./include -Wno-module-import-in-extern-c -Wno-unused-variable

# Bağlantı bayrakları (Linker Flags)
# -L./: Mevcut dizindeki libdobby.dylib/a dosyasını görmesini sağlar
# -ldobby: Dobby kütüphanesini bağlar
TssBypass_LDFLAGS = -L./ -ldobby -Xlinker -fatal_warnings

# Library kurallarını içeri aktar
include $(THEOS_MAKE_PATH)/library.mk

# Derleme sonrası temizlik ve paketleme ayarı
after-install::
	install.exec "killall -9 ShadowTrackerExtra"
