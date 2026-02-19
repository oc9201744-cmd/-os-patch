#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>

extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

uintptr_t anogs_base = 0;
void *anogs_backup = NULL;
size_t anogs_size = 0x300000; 

int (*orig_memcmp)(const void *s1, const void *s2, size_t n);

// Fotoğraftaki gibi uint64_t (int64) kullanıyoruz
typedef uint64_t _QWORD;
typedef uint32_t _DWORD;
typedef uint16_t _WORD;

void (*orig_sub_6D1E0)(uint64_t a1);
void new_sub_6D1E0(uint64_t a1) {
    // 1. Önce orijinali çalıştır ki gerekli alanlar bellekte oluşsun
    if (orig_sub_6D1E0) {
        orig_sub_6D1E0(a1);
    }

    // 2. FOTOĞRAFTAKİ MANTIK: Tüm raporlama offsetlerini sıfırla
    // Senin paylaştığın sub_6D1E0 içindeki offsetlere göre:
    *(_QWORD *)(a1 + 1000) = 0LL;
    *(uint128_t *)(a1 + 984) = 0; // _OWORD karşılığı
    *(_BYTE *)(a1 + 1040) = 0;
    *(_WORD *)(a1 + 1360) = 0;
    
    // Fotoğraftaki adamın yaptığı gibi kritik bayrakları temizle
    *(_BYTE *)(a1 + 1362) = 0; // force_hb (Crash sebebi genelde buydu, şimdi safe)
    *(_DWORD *)(a1 + 328) = 0; // Hata sayacı
    
    // Eğer fotoğraftaki sub_18E644 senin analizindekiyle aynıysa bunları da ekle:
    // *(_QWORD *)(a1 + 104) = 0LL;
    // *(_QWORD *)(a1 + 912) = 0LL;
}

// Memcmp hook'un aynı kalıyor, Dobby izlerini gizlemek için şart
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
    void *m_ptr = dlsym(RTLD_DEFAULT, "memcmp");
    if (m_ptr) {
        DobbyHook(m_ptr, (void *)new_memcmp, (void **)&orig_memcmp);
    }

    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "anogs") || strstr(name, "ace_cs2"))) {
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            anogs_backup = malloc(anogs_size);
            memcpy(anogs_backup, (void *)anogs_base, anogs_size);
            
            // Kancayı atıyoruz
            DobbyHook((void *)(anogs_base + 0x6D1E0), (void *)new_sub_6D1E0, (void **)&orig_sub_6D1E0);
            break;
        }
    }
}
