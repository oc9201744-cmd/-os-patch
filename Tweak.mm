#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>

// Dobby fonksiyonu
extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// Global değişkenler
uintptr_t anogs_base = 0;
void *anogs_backup = NULL;
size_t anogs_size = 0x300000; 

int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

// 1. SENİN ANALİZ ETTİĞİN FONKSİYON: sub_6D1E0
void (*orig_sub_6D1E0)(uint64_t a1);
void new_sub_6D1E0(uint64_t a1) {
    // Önce orijinal fonksiyonun kendi işini (struct kurulumu) yapmasına izin veriyoruz
    if (orig_sub_6D1E0) {
        orig_sub_6D1E0(a1);
    }

    // ŞİMDİ SADECE SENİN PAYLAŞTIĞIN KODDAKİ VERİLERİ SIFIRLIYORUZ:
    // Bu kısımlar senin paylaştığın pseudocode içindeki raporlama alanlarıdır.
    *(uint64_t *)(a1 + 1000) = 0LL;
    *(uint8_t *)(a1 + 1040) = 0;
    *(uint16_t *)(a1 + 1360) = 0;
    *(uint8_t *)(a1 + 1362) = 0; // force_hb (kalp atışını durdurur)
    *(uint32_t *)(a1 + 328) = 0;  // Hata sayacı
    
    // Buraya senin analizinde gördüğün diğer offsetleri de ekleyebilirsin.
}

// 2. INTEGRITY (BÜTÜNLÜK) KÖR ETME
// Bu kısım Dobby'nin yaptığı değişikliği ACE'den saklamak için mecburi.
int new_memcmp(const void *s1, const void *s2, size_t n) {
    uintptr_t addr1 = (uintptr_t)s1;
    uintptr_t addr2 = (uintptr_t)s2;

    if (anogs_base != 0 && anogs_backup != NULL) {
        if (addr1 >= anogs_base && addr1 < (anogs_base + anogs_size)) {
            size_t offset = addr1 - anogs_base;
            return orig_memcmp((void *)((uintptr_t)anogs_backup + offset), s2, n);
        }
        if (addr2 >= anogs_base && addr2 < (anogs_base + anogs_size)) {
            size_t offset = addr2 - anogs_base;
            return orig_memcmp(s1, (void *)((uintptr_t)anogs_backup + offset), n);
        }
    }
    return orig_memcmp(s1, s2, n);
}

__attribute__((constructor))
static void global_init() {
    // memcmp hook (Dobby'yi gizlemek için)
    void *m_ptr = dlsym(RTLD_DEFAULT, "memcmp");
    if (m_ptr) {
        DobbyHook(m_ptr, (void *)new_memcmp, (void **)&orig_memcmp);
    }

    // ACE / anogs modülünü bul
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "anogs") || strstr(name, "ace_cs2"))) {
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            
            // Orijinal halini belleğe yedekle (Kör tarama için)
            anogs_backup = malloc(anogs_size);
            memcpy(anogs_backup, (void *)anogs_base, anogs_size);
            
            // SENİN OFFSETİN: 0x6D1E0
            DobbyHook((void *)(anogs_base + 0x6D1E0), (void *)new_sub_6D1E0, (void **)&orig_sub_6D1E0);
            
            break;
        }
    }
}
