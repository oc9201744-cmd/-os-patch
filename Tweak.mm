#include <dobby.h>
#include <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>
#include <stdio.h>

// 1. Bütünlük Banı (9014 Alert) Hook'u
void (*orig_11824)(void *a1, void *a2);
void hook_11824(void *a1, void *a2) {
    // 9014 Bütünlük uyarısı tetiklendiğinde hiçbir eylem yapma, geri dön.
    return;
}

// 2. Report & Ortam Banı (Root Alert) Hook'u
void (*orig_63D4)(void *a1);
void hook_63D4(void *a1) {
    // Sistem raporu/alert tetiklendiğinde engelle, geri dön.
    return;
}

// ANOGS framework'ünün çalışma zamanındaki temel adresini (Base Address) bulur
uintptr_t get_anogs_base() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *image_name = _dyld_get_image_name(i);
        // anogs.framework modülünü arıyoruz
        if (strstr(image_name, "anogs")) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

// Kütüphane yüklendiğinde otomatik çalışacak bypass fonksiyonu
__attribute__((constructor))
void init_memory_patch() {
    uintptr_t anogs_base = get_anogs_base();
    
    if (anogs_base != 0) {
        // Analizden elde edilen offsetler
        uintptr_t integrity_ban_addr = anogs_base + 0x11824; 
        uintptr_t report_ban_addr = anogs_base + 0x63D4;
        
        // Dobby ile belleğe bypass yamalarını atıyoruz
        DobbyHook((void*)integrity_ban_addr, (void*)hook_11824, (void**)&orig_11824);
        DobbyHook((void*)report_ban_addr, (void*)hook_63D4, (void**)&orig_63D4);
    }
}
