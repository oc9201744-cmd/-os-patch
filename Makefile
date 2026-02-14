# Derleme yapılacak mimariler (A12+ cihazlar için arm64e şart)
ARCHS = arm64 arm64e

# Hedef iOS sürümü (En stabil sonuç için 14.0 idealdir)
TARGET := iphone:clang:latest:14.0

# Derleyicinin "eskimiş kod" hatalarını görmezden gelmesini sağlayan kritik ayar
ADDITIONAL_CFLAGS = -Wno-deprecated-declarations -Wno-error=deprecated-declarations -fobjc-arc

include $(THEOS)/makefiles/common.mk

# Tweak ismin (Control ve Plist dosyalarıyla aynı olmalı)
TWEAK_NAME = AnoBypass

# Derlenecek dosyalar
AnoBypass_FILES = Tweak.x
AnoBypass_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

# Derleme sonrası temizlik ve paketleme ayarları
after-install::
	install.exec "killall -9 Job"
