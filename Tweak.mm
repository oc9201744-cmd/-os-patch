#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import "dobby.h"   // dobby.h bu dosyayla aynı klasörde olmalı

#define LOG(fmt, ...) NSLog(@"[Bypass] " fmt, ##__VA_ARGS__)

// Orijinal fonksiyon tipi
typedef void (*orig_sub_D372C_type)(void *arg0, ...);
orig_sub_D372C_type orig_sub_D372C = NULL;

// Hook fonksiyonumuz
void my_sub_D372C(void *arg0) {
    LOG(@"sub_D372C çağrıldı! Bypass ediliyor, ekrana yazı bastırılıyor...");
    
    // Orijinal fonksiyonu çağırmak istersen (bypass ETMEZ):
    // orig_sub_D372C(arg0);
    
    // Direkt return yaparak bypass et (orijinal kod ÇALIŞMAZ):
    // return;
}

// Constructor: library yüklendiğinde otomatik çalışır
__attribute__((constructor))
static void init() {
    LOG("Bypass kütüphanesi yükleniyor...");
    
    // Hedef image adı (framework ise "İsim.framework/İsim" formatında)
    const char *target_image = "Anogs.framework/Anogs"; // <-- BURAYI KENDİNE GÖRE DÜZENLE
    uintptr_t base = 0;
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, target_image)) {
            base = (uintptr_t)_dyld_get_image_header(i);
            LOG("Hedef image bulundu: %s, base = 0x%llx", name, (uint64_t)base);
            break;
        }
    }
    
    if (base == 0) {
        LOG("Hata: %s bulunamadı! Mevcut image'lar:", target_image);
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            LOG("Image %u: %s", i, _dyld_get_image_name(i));
        }
        return;
    }
    
    // Hedef fonksiyon adresi (offset 0xD372C)
    void *target_addr = (void *)(base + 0xD372C);
    LOG("Hedef adres: %p", target_addr);
    
    // Dobby hook kur
    int ret = DobbyHook(target_addr, (void *)my_sub_D372C, (void **)&orig_sub_D372C);
    if (ret == 0) {
        LOG("Hook başarıyla kuruldu!");
    } else {
        LOG("Hook kurulamadı! Hata kodu: %d", ret);
    }
}
