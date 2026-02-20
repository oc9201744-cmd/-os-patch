// Sistem başlıklarını Dobby'den önce ekleyerek modül hatasını çözüyoruz
#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <stdint.h>

// Dobby'yi dahil et
#include "dobby.h"

// --- Ofsetler (Analiz.txt dosyasından alınan statik adresler) ---
// Not: Bu adresler anogs.framework içindeki statik adreslerdir.
#define OFFSET_9014_INTEGRITY 0x11824
#define OFFSET_ROOT_ALERT      0x63D4
#define OFFSET_REPORT_DATA     0x23398

// Hook sonrası orijinal fonksiyonları saklamak için (Gerekirse çağrılabilir)
void (*orig_integrity)(void *a1, void *a2);
void (*orig_root)(void *a1);
void (*orig_report)(void *a1, void *a2);

// --- Bypass Fonksiyonları ---
void hook_integrity(void *a1, void *a2) { return; }
void hook_root(void *a1) { return; }
void hook_report(void *a1, void *a2) { return; }

// --- ASLR Hesaplama ve Modül Bulma ---
uintptr_t get_anogs_base_address() {
    uintptr_t base = 0;
    uint32_t image_count = _dyld_image_count();
    
    for (uint32_t i = 0; i < image_count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "anogs")) {
            base = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }
    return base;
}

// --- Bellek Yaması Başlatıcı ---
__attribute__((constructor))
static void start_bypass() {
    // 1. ASLR Base Adresini bul (Dinamik adres)
    uintptr_t base = get_anogs_base_address();
    
    if (base != 0) {
        // ASLR Hesaplaması: Gerçek Adres = Base + Ofset
        
        // Bütünlük Kontrolü Bypass
        DobbyHook((void *)(base + OFFSET_9014_INTEGRITY), (void *)hook_integrity, (void **)&orig_integrity);
        
        // Root/Jailbreak Alert Bypass
        DobbyHook((void *)(base + OFFSET_ROOT_ALERT), (void *)hook_root, (void **)&orig_root);
        
        // SDK Veri Raporlama Bypass
        DobbyHook((void *)(base + OFFSET_REPORT_DATA), (void *)hook_report, (void **)&orig_report);
        
        printf("[Bypass] anogs aktif edildi! Base: 0x%lx\n", base);
    }
}
