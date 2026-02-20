#include <mach-o/dyld.h>
#include <stdint.h>
#include <string.h>
#include <stdio.h>

// Dobby'nin çekirdek fonksiyonunu dışarıdan (extern) tanımlıyoruz
extern "C" int DobbyHook(void *target_address, void *replace_address, void **original_address);

// --- Analiz.txt dosyasından gelen Ban Ofsetleri ---
#define OFFSET_9014_INTEGRITY 0x11824
#define OFFSET_ROOT_REPORT     0x63D4

// --- Bypass (Susturma) Fonksiyonları ---
// Bu fonksiyonlar çağrıldığında hiçbir işlem yapmadan (void) geri döner.
void handle_integrity_bypass(void *a1, void *a2) { return; }
void handle_report_bypass(void *a1) { return; }

// --- Otomatik ASLR Taban Adresi Hesaplayıcı ---
// iOS sistem kütüphanesi (dyld) kullanarak anogs'un bellekteki yerini bulur.
uintptr_t find_anogs_base() {
    uintptr_t base = 0;
    uint32_t count = _dyld_image_count();
    
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        // Bellekteki tüm modülleri tarayıp anogs'u buluyoruz
        if (name != NULL && strstr(name, "anogs")) {
            base = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }
    return base;
}

// --- Bellek Yaması Başlatıcı (Constructor) ---
__attribute__((constructor))
static void apply_ios_bypass() {
    // 1. ASLR Taban Adresini dinamik olarak hesapla
    uintptr_t anogs_base = find_anogs_base();
    
    if (anogs_base != 0) {
        // 2. ASLR Hesaplaması: (Bellekteki Başlangıç + Statik Ofset)
        
        // Bütünlük Banı (9014) Bypass Uygula
        DobbyHook((void *)(anogs_base + OFFSET_9014_INTEGRITY), (void *)handle_integrity_bypass, NULL);
        
        // Root/Report Banı Bypass Uygula
        DobbyHook((void *)(anogs_base + OFFSET_ROOT_REPORT), (void *)handle_report_bypass, NULL);
        
        // Başarılı logu (Console üzerinden görülebilir)
        printf("[iOS-Bypass] anogs yamalandı. Base: 0x%lx\n", anogs_base);
    }
}
