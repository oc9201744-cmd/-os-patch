#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import "dobby.h"   // Dobby başlık dosyasını projene ekle

// Log için (hem konsola hem syslog'a)
#define LOG(fmt, ...) NSLog(@"[Bypass] " fmt, ##__VA_ARGS__)

// Orijinal fonksiyon tipi (parametreleri bilinmiyor, genelde ilk parametre X0)
typedef void (*sub_D372C_func)(void *arg0, ...);
sub_D372C_func orig_sub_D372C = NULL;

// Hook fonksiyonumuz
void my_sub_D372C(void *arg0) {
    LOG(@"sub_D372C çağrıldı! Bypass ediliyor, ekrana yazı bastırılıyor...");
    
    // İstersen orijinal fonksiyonu çağır (açıklama satırını kaldır)
    // orig_sub_D372C(arg0);
    
    // Eğer bypass etmek istiyorsan, burada direkt return et.
    // Dönüş değeri void varsayıldı, eğer int döndürüyorsa uygun bir değer döndür.
}

// Constructor: library yüklendiğinde otomatik çalışır
__attribute__((constructor))
static void init() {
    LOG("Bypass kütüphanesi yükleniyor...");
    
    // 1. Hedef image'ın base adresini bul
    uintptr_t base = 0;
    // Örnek: "libhedef.dylib" ismini kendi library'nle değiştir
    const char *target_image = "libhedef.dylib";
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, target_image)) {
            base = (uintptr_t)_dyld_get_image_header(i);
            LOG("Hedef image bulundu: %s, base = 0x%llx", name, (uint64_t)base);
            break;
        }
    }
    
    if (base == 0) {
        LOG("Hata: %s bulunamadı!", target_image);
        return;
    }
    
    // 2. Hedef fonksiyon adresini hesapla (offset 0xD372C)
    void *target_addr = (void *)(base + 0xD372C);
    LOG("Hedef adres: %p", target_addr);
    
    // 3. Dobby hook kur
    int ret = DobbyHook(target_addr, (void *)my_sub_D372C, (void **)&orig_sub_D372C);
    if (ret == 0) {
        LOG("Hook başarıyla kuruldu!");
    } else {
        LOG("Hook kurulamadı! Hata kodu: %d", ret);
    }
}