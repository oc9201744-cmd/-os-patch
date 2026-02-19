#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <string.h>

// GitHub'da açtığın klasörden çekiyoruz
#include "dobby.h" 

#define LOG(fmt, ...) NSLog(@"[AnogsBypass] " fmt, ##__VA_ARGS__)

// Orijinal fonksiyonu saklamak için değişken
typedef void (*orig_sub_D372C_type)(void *arg0, ...);
orig_sub_D372C_type orig_sub_D372C = NULL;

// Fonksiyon çağrıldığında buraya düşecek
void my_sub_D372C(void *arg0) {
    // Burayı boş bırakırsak fonksiyon hiçbir şey yapmadan geri döner (Bypass)
    LOG(@"Anogs Kontrolü Engellendi (0xD372C)");
}

__attribute__((constructor))
static void init() {
    LOG("Bypass motoru tetiklendi...");
    
    uintptr_t base = 0;
    const char *target_name = "Anogs.framework/Anogs"; // Framework yolu
    
    // Hafızada Anogs'u ara
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, target_name)) {
            // Slide değerini al (ASLR için)
            base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            LOG("Anogs bulundu! Base Slide: 0x%lx", base);
            break;
        }
    }
    
    if (base != 0) {
        // Hedef Adres = Slide + Offset (0xD372C)
        // Not: Bazı durumlarda base'e 0x100000000 eklemek gerekebilir, 
        // ama modern Dobby sürümleri genelde direkt slide ile çalışır.
        void *target_addr = (void *)(base + 0xD372C);
        
        LOG("Hook deneniyor: %p", target_addr);
        
        // Dobby ile fonksiyonun kafasına çöküyoruz
        int ret = DobbyHook(target_addr, (void *)my_sub_D372C, (void **)&orig_sub_D372C);
        
        if (ret == 0) {
            LOG("Anogs Bypass BASARILI!");
        } else {
            LOG("Hook Hatası! Kod: %d", ret);
        }
    } else {
        LOG("HATA: Anogs.framework hafızada bulunamadı!");
    }
}
