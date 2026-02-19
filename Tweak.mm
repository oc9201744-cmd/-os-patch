#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>
#include <substrate.h>

// Dobby'yi dışarıdan dahil ediyoruz
extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

// Tip tanımlamaları
typedef uint64_t _QWORD;
typedef uint32_t _DWORD;
typedef uint16_t _WORD;
typedef uint8_t  _BYTE;

uintptr_t anogs_base = 0;
void *anogs_backup = NULL;
size_t anogs_size = 0x400000; // Analizlerine göre kapsamı geniş tuttuk

// --- 1. KENDİMİZİ GİZLEME (Dylib Detection Bypass) ---
// ACE listeyi tararken bizim dylib'i bulamasın diye
const char* (*orig_dyld_get_image_name)(uint32_t image_index);
const char* new_dyld_get_image_name(uint32_t image_index) {
    const char *name = orig_dyld_get_image_name(image_index);
    if (name && (strstr(name, "BypassTweak") || strstr(name, "Dobby") || strstr(name, ".dylib"))) {
        // Kendimizi sistem kütüphanesiymiş gibi gösteriyoruz
        return "/System/Library/Frameworks/UIKit.framework/UIKit";
    }
    return name;
}

// --- 2. VERİ TEMİZLEME (sub_6D1E0 Patch) ---
// Senin analiz ettiğin, raporların hazırlandığı ana fonksiyon
void (*orig_sub_6D1E0)(uint64_t a1);
void new_sub_6D1E0(uint64_t a1) {
    if (orig_sub_6D1E0) orig_sub_6D1E0(a1);

    // Senin IDA analizindeki kritik offsetleri sıfırlıyoruz
    if (a1) {
        *(_QWORD *)(a1 + 1000) = 0LL;
        *(_BYTE *)(a1 + 1040) = 0;
        *(_WORD *)(a1 + 1360) = 0;
        *(_BYTE *)(a1 + 1362) = 0; // force_hb (Kalp atışı/ban tetikleyici)
        *(_DWORD *)(a1 + 328) = 0; // Hata sayacı
        
        // Ekstra önlem: Diğer raporlama alanları
        *(_QWORD *)(a1 + 104) = 0LL;
        *(_QWORD *)(a1 + 912) = 0LL;
    }
}

// --- 3. RAPOR GÖNDERİMİNİ KESME (sub_8DFC Hook) ---
// TssIosMainThreadDispatcher -> SendCmd kısmını susturuyoruz
uint64_t (*orig_sub_8DFC)(uint64_t a1);
uint64_t new_sub_8DFC(uint64_t a1) {
    // Rapor postacısını burada durduruyoruz. 
    // ACE veri hazırlasa bile gönderilmesine izin vermiyoruz.
    return 0LL;
}

// --- 4. INTEGRITY (BÜTÜNLÜK) KANDIRMA (memcmp Bypass) ---
int (*orig_memcmp)(const void *s1, const void *s2, size_t n);
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

// --- BAŞLATICI ---
__attribute__((constructor))
static void global_init() {
    // Önce hayalet modunu aç (dyld kancası)
    void *dyld_name_ptr = dlsym(RTLD_DEFAULT, "_dyld_get_image_name");
    if (dyld_name_ptr) DobbyHook(dyld_name_ptr, (void *)new_dyld_get_image_name, (void **)&orig_dyld_get_image_name);

    // memcmp kancası (ACE tarayıcısını kör eder)
    void *m_ptr = dlsym(RTLD_DEFAULT, "memcmp");
    if (m_ptr) DobbyHook(m_ptr, (void *)new_memcmp, (void **)&orig_memcmp);

    // ACE modülünü bul ve diğer kancaları at
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "anogs") || strstr(name, "ace_cs2"))) {
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            
            // Orijinal halini yedekle (Kör tarama için)
            anogs_backup = malloc(anogs_size);
            memcpy(anogs_backup, (void *)anogs_base, anogs_size);
            
            // 0x6D1E0: Veri Temizleme
            DobbyHook((void *)(anogs_base + 0x6D1E0), (void *)new_sub_6D1E0, (void **)&orig_sub_6D1E0);
            
            // 0x8DFC: Postacı Susturma
            DobbyHook((void *)(anogs_base + 0x8DFC), (void *)new_sub_8DFC, (void **)&orig_sub_8DFC);
            
            break;
        }
    }
}
