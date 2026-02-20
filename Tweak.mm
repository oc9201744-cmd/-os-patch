#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <mach-o/dyld.h>
#include <stdint.h>

// Dobby'nin header hatasını aşmak için manuel tanım
extern "C" int DobbyHook(void *target_address, void *replace_address, void **original_address);

// --- Analiz.txt dosyasından aldığımız statik ofsetler ---
#define OFFSET_9014_BAN    0x11824
#define OFFSET_ROOT_BAN    0x63D4

// Orijinal fonksiyonlar (İhtiyaç halinde)
static void (*orig_9014)(void *a1, void *a2);
static void (*orig_root)(void *a1);

// --- Bypass (Ban Fonksiyonlarını Etkisiz Hale Getir) ---
void hook_9014(void *a1, void *a2) { return; }
void hook_root(void *a1) { return; }

// --- Otomatik ASLR Taban Adresi Hesaplama ---
uintptr_t get_anogs_base() {
    uintptr_t base = 0;
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "anogs")) {
            base = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }
    return base;
}

// --- Tweak Yüklendiğinde Çalışacak Kısım ---
__attribute__((constructor))
static void start_anogs_bypass() {
    // 1. Çalışma zamanında ASLR Base adresini bul
    uintptr_t anogs_base = get_anogs_base();
    
    if (anogs_base != 0) {
        // ASLR HESABI: (Base Address + Static Offset)
        // 9014 Bütünlük Banını Yamala
        DobbyHook((void *)(anogs_base + OFFSET_9014_BAN), (void *)hook_9014, (void **)&orig_9014);
        
        // Root/Report Banını Yamala
        DobbyHook((void *)(anogs_base + OFFSET_ROOT_BAN), (void *)hook_root, (void **)&orig_root);

        printf("[DoobyBypass] anogs aktif! ASLR Base: 0x%lx\n", anogs_base);
    }
}
