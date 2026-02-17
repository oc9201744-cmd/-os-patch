# İmzalama hatasını (ldid) atlatmak için:
export SIGN_SKIP = 1

# Substrate kütüphanesini ve frameworkleri tanıtmak için:
SecureBypass_FRAMEWORKS = UIKit Foundation AudioToolbox
SecureBypass_LIBRARIES = substrate

# Eğer hala 'ldid' hatası alırsan şu satırı da ekle:
export CODESIGN_IPA = 0
