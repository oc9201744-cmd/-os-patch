# Mimariyi hem eski hem yeni cihazlar için ayarlıyoruz
export ARCHS = arm64 arm64e
# Target versiyonu iOS 14.0 ve üstü olarak belirliyoruz
export TARGET = iphone:clang:latest:14.0

TWEAK_NAME = BaybarsBypass

# Derlenecek ana dosya (Adı Tweak.xm olmalı)
$(TWEAK_NAME)_FILES = Tweak.xm

# Gerekli framework'ler
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation

# Derleme bayrakları: 
# -fobjc-arc: Otomatik bellek yönetimi
# -Wno-deprecated-declarations: Eski kod uyarılarını hata olarak görme (keyWindow hatasını geçer)
# -Wno-unused-variable: Kullanılmayan değişken uyarılarını görmezden gel
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable

# Theos'un ana kurallarını dahil ediyoruz
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk
