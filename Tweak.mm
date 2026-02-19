#include <string.h>
#include <dlfcn.h>
#import <Foundation/Foundation.h>

// Loglama için kısa yol
#define LOG(fmt, ...) NSLog(@"[AnogsBypass] " fmt, ##__VA_ARGS__)

// Orijinal veriyi saklayacak tampon
// Dosyandaki 0x4224 adresinin ilk 8 byte'ı: STP X29, X30, [SP,#-0x10]! ve MOV X29, SP
unsigned char original_buffer[8] = {0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91}; 

uintptr_t target_base = 0;
int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

int new_memcmp(const void *s1, const void *s2, size_t n) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;
    uintptr_t target_addr = target_base + 0x4224;

    // Eğer tarama bizim yamalı adresimize denk gelirse (Burası kör etme noktası)
    if (addr1 == target_addr || addr2 == target_addr) {
        LOG("!!! INTEGRITY CHECK YAKALANDI !!! Adres: 0x4224 taranıyor. Sahte veri gönderiliyor...");
        
        if (addr1 == target_addr) return orig_memcmp(original_buffer, s2, n);
        return orig_memcmp(s1, original_buffer, n);
    }

    return orig_memcmp(s1, s2, n);
}

__attribute__((constructor))
static void setup_bypass() {
    // 1. Yazdırma Aktif: Tweak'in yüklendiğini bildir
    LOG("Bypass Dylib Yüklendi. Base aranıyor...");

    // Hedef kütüphaneyi bul (Örn: ShadowTrackerExtra veya anogs)
    target_base = (uintptr_t)_dyld_get_image_vmaddr_slide(0); 
    LOG("Base Adresi Bulundu: 0x%lx", target_base);

    // 2. Yazdırma Aktif: memcmp hooklanıyor mu kontrol et
    if (DobbyHook((void *)memcmp, (void *)new_memcmp, (void **)&orig_memcmp) == 0) {
        LOG("BAŞARILI: memcmp hooklandı. Tarayıcı artık kör.");
    } else {
        LOG("HATA: memcmp hooklanamadı!");
    }
}
