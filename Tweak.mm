#include <stdint.h>
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include "dobby.h"

// --- Modül Base Adresini Bulma (ASLR Çözücü) ---
uintptr_t get_module_base(const char *module_name) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, module_name)) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i) + 0x100000000; 
            // Not: Bazı sürümlerde sadece slide yeterli olur, duruma göre bakacağız.
        }
    }
    return 0;
}

// --- Hook Fonksiyonları ---
int (*orig_Anogs_Check)(void);
int fake_Anogs_Check() {
    // Güvenlik taramasını "Temiz" döndürür
    return 0; 
}

void start_bypass() {
    // 1. ANOGS Modülünün ASLR'li adresini buluyoruz
    // Analiz.txt bu modüle ait olduğu için offsetler bunun üzerine binmeli
    uintptr_t anogs_base = 0;
    uint32_t img_count = _dyld_image_count();
    
    for (uint32_t i = 0; i < img_count; i++) {
        if (strstr(_dyld_get_image_name(i), "anogs")) {
            // ASLR Kayma miktarını (Slide) alıyoruz
            anogs_base = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }

    if (anogs_base == 0) {
        NSLog(@"[KINGMOD] HATA: anogs modülü bulunamadı, bypass iptal!");
        return;
    }

    NSLog(@"[KINGMOD] anogs Base Bulundu: %p", (void *)anogs_base);

    // --- CASE 35 & ACE_CS2 Hookları ---
    
    // Analiz.txt'deki offsetleri ASLR'li base ile topluyoruz
    // Örnek: sub_23C74 -> anogs_base + 0x23C74
    void *target_func = (void *)(anogs_base + 0x23C74); 
    
    if (target_func) {
        DobbyHook(target_func, (void *)fake_Anogs_Check, (void **)&orig_Anogs_Check);
        NSLog(@"[KINGMOD] Inline Hook Başarılı!");
    }

    // --- Memory Scan Bypass (Patch) ---
    uint8_t ret_patch[] = {0xC0, 0x03, 0x5F, 0xD6}; // RET
    DobbyCodePatch((void *)(anogs_base + 0x2D108), ret_patch, 4);
}

__attribute__((constructor))
static void initialize() {
    // Oyunun ve Anogs'un belleğe tam yerleşmesi için 15 saniye şart!
    // Erken yama yapmak ASLR henüz hesaplanmadığı için crash yaptırır.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        start_bypass();
    });
}
