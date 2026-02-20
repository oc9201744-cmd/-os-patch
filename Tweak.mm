// 1. Önce sistem headerlarını ekle (Dobby'den önce!)
#include <sys/types.h>
#include <stdio.h>
#include <string.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <stdint.h>

// 2. Modül hatasını aşmak için Dobby'yi elle tanımla veya sistem headerlarından sonra çağır
#include "dobby.h"

// --- Ofset Tanımları (Analiz.txt dosyasından) ---
// ASLR hesaplaması bu değerler üzerine otomatik eklenecek
#define OFFSET_9014_BAN    0x11824
#define OFFSET_ROOT_BAN    0x63D4
#define OFFSET_REPORT      0x23398

// Orijinal fonksiyonları saklamak için
static void (*orig_9014)(void *a1, void *a2);
static void (*orig_root)(void *a1);

// --- Bypass (Hook) Fonksiyonları ---
// Bu fonksiyonlar tetiklendiğinde hiçbir işlem yapmadan geri döner (Return)
void hook_9014(void *a1, void *a2) {
    return;
}

void hook_root(void *a1) {
    return;
}

// --- ASLR Taban Adresi Hesaplama ---
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

// --- Bellek Yaması Başlatıcı ---
__attribute__((constructor))
static void init_anogs_bypass() {
    // Bellekteki anogs taban adresini (ASLR Base) bulur
    uintptr_t anogs_base = get_anogs_base();
    
    if (anogs_base != 0) {
        // ASLR Hesaplaması: Base + Ofset = Gerçek Bellek Adresi
        
        // 9014 Bütünlük Banı Bypass
        DobbyHook((void *)(anogs_base + OFFSET_9014_BAN), (void *)hook_9014, (void **)&orig_9014);
        
        // Root/Report Banı Bypass
        DobbyHook((void *)(anogs_base + OFFSET_ROOT_BAN), (void *)hook_root, (void **)&orig_root);
        
        printf("[Bypass] anogs.framework yamalandı. Base: 0x%lx\n", anogs_base);
    } else {
        printf("[Bypass] anogs bulunamadı, bekleniyor...\n");
    }
}
