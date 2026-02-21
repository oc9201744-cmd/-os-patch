#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>

// DobbyHook fonksiyonunu dışarıdan alıyoruz
extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// Loglama Makrosu
#define LOG(fmt, ...) NSLog(@"[AnogsBypass] " fmt, ##__VA_ARGS__)

// Analiz.txt 0x4224 adresindeki orijinal veriler (Integrity Check için)
unsigned char original_buffer[8] = {0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91}; 

uintptr_t target_base = 0;
int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

// --- Bütünlük kontrolünü kör eden kanca ---
int new_memcmp(const void *s1, const void *s2, size_t n) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;
    
    if (target_base != 0) {
        // Yamaladığın yerin adresi (Base + Offset)
        uintptr_t target_addr = target_base + 0x4224;

        // Eğer sistem bizim yamalı adresimizi taramaya kalkarsa orijinal veriyi gösteriyoruz
        if (addr1 == target_addr || addr2 == target_addr) {
            LOG("!!! INTEGRITY CHECK YAKALANDI !!! Orijinal veri taklit ediliyor...");
            if (addr1 == target_addr) return orig_memcmp(original_buffer, s2, n);
            return orig_memcmp(s1, original_buffer, n);
        }
    }
    return orig_memcmp(s1, s2, n);
}

// --- Anogs Yüklendiğinde Çalışacak Fonksiyon (Hatasız Versiyon) ---
static void on_image_load(const struct mach_header *mh, intptr_t slide) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        // Sistemdeki mevcut header'ı bulup ismini kontrol ediyoruz
        if (_dyld_get_image_header(i) == mh) {
            const char *name = _dyld_get_image_name(i);
            if (name && strstr(name, "anogs")) {
                target_base = (uintptr_t)slide;
                LOG("🔥 ANOGS YAKALANDI! Base (Slide): 0x%lx", (long)target_base);
            }
            break;
        }
    }
}

// --- Giriş Noktası ---
__attribute__((constructor))
static void setup_bypass() {
    LOG("Bypass Dylib Yüklendi.");

    // 1. memcmp kancasını hemen at
    void *memcmp_ptr = dlsym(RTLD_DEFAULT, "memcmp");
    if (memcmp_ptr) {
        if (DobbyHook(memcmp_ptr, (void *)new_memcmp, (void **)&orig_memcmp) == 0) {
            LOG("BAŞARILI: memcmp kancalandı.");
        } else {
            LOG("HATA: memcmp kancalanamadı!");
        }
    }

    // 2. Anogs'un yüklenmesini izle
    _dyld_register_func_for_add_image(on_image_load);
}
