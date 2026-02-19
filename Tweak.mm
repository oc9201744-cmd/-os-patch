#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>

// 1. HATA ÇÖZÜMÜ: DobbyHook fonksiyonunu derleyiciye tanıtıyoruz
extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// Loglama Makrosu
#define LOG(fmt, ...) NSLog(@"[AnogsBypass] " fmt, ##__VA_ARGS__)

// Orijinal veriyi saklayacak tampon (Analiz.txt 0x4224 adresindeki ilk 8 byte)
unsigned char original_buffer[8] = {0xFD, 0x7B, 0xBF, 0xA9, 0xFD, 0x03, 0x00, 0x91}; 

uintptr_t target_base = 0;
int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

// Bütünlük kontrolünü kör eden fonksiyon
int new_memcmp(const void *s1, const void *s2, size_t n) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;
    uintptr_t target_addr = target_base + 0x4224;

    // Eğer sistem bizim yamalı adresimizi taramaya kalkarsa
    if (addr1 == target_addr || addr2 == target_addr) {
        LOG("!!! INTEGRITY CHECK YAKALANDI !!! Sahte veri gönderiliyor...");
        
        if (addr1 == target_addr) return orig_memcmp(original_buffer, s2, n);
        return orig_memcmp(s1, original_buffer, n);
    }

    return orig_memcmp(s1, s2, n);
}

__attribute__((constructor))
static void setup_bypass() {
    LOG("Bypass Dylib Yüklendi. Sistem başlatılıyor...");

    // 2. HATA ÇÖZÜMÜ: _dyld_get_image_vmaddr_slide kullanımı için doğru index
    // 0 genellikle ana binary'dir (ShadowTrackerExtra)
    target_base = (uintptr_t)_dyld_get_image_vmaddr_slide(0); 
    LOG("Base Adresi: 0x%lx", target_base);

    // Integrity Check'i kör etmek için memcmp'yi kancala
    void *memcmp_ptr = dlsym(RTLD_DEFAULT, "memcmp");
    if (memcmp_ptr && DobbyHook(memcmp_ptr, (void *)new_memcmp, (void **)&orig_memcmp) == 0) {
        LOG("BAŞARILI: memcmp kancalandı. Tarayıcı kör edildi.");
    } else {
        LOG("HATA: memcmp kancalanamadı!");
    }
}
