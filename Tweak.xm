#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

// 1. Sistem kütüphanelerini Dobby'den ÖNCE çağırıyoruz (Hata almamak için)
#include <stdint.h>
#include <sys/types.h>

// 2. Dobby kütüphanesini dahil ediyoruz
#include "include/dobby.h"

// 3. PAC (Pointer Authentication) temizleme fonksiyonu
// arm64e (iPhone XS ve üstü) cihazlarda ban yememek için şart
static void* clean_ptr(void* ptr) {
#if defined(__arm64e__)
    return (void*)((uintptr_t)ptr & 0x0000000FFFFFFFFF);
#else
    return ptr;
#endif
}

// 4. Ana Framework (Anogs) yüklendiğinde çalışacak kısım
static void on_load(const struct mach_header *mh, intptr_t slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        // Eğer yüklenen dosya oyunun koruma framework'ü ise
        if (info.dli_fname && strstr(info.dli_fname, "Anogs")) {
            
            // --- SENİN BYPASS VERİLERİN ---
            uintptr_t offset = 0xD3844; 
            void *target_addr = (void *)(slide + offset);
            void *final_addr = clean_ptr(target_addr);
            
            // Yama: MOV W1, #0xC0
            uint32_t patch_hex = 0x52801801;
            
            // Dobby ile güvenli runtime yaması
            if (DobbyCodePatch(final_addr, (uint8_t *)&patch_hex, sizeof(patch_hex)) == 0) {
                NSLog(@"[Baybars] BYPASS AKTIF EDILDI! Adres: %p", final_addr);
            } else {
                NSLog(@"[Baybars] Bypass Hatası: Dobby yazamadı.");
            }
            // ------------------------------
        }
    }
}

// 5. Dylib belleğe yüklendiği an tetiklenen constructor
__attribute__((constructor))
static void init() {
    // Tüm framework yüklemelerini izle
    _dyld_register_func_for_add_image(&on_load);
}
