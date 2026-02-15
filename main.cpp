#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>
#include <sys/mman.h>
#include <mach-o/dyld.h>

// --- Interpose Yapısı (Sadece Sistem Fonksiyonları İçin) ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// --- Sistem Fonksiyonu Hookları ---
extern "C" int ptrace(int request, int pid, void* addr, int data);

int my_strcmp(const char *s1, const char *s2) {
    if (s2 != NULL && strstr(s2, "anti_sp2s")) return 0;
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(my_strcmp, strcmp);

int my_ptrace(int request, int pid, void* addr, int data) {
    return 0; 
}
INTERPOSE_FUNCTION(my_ptrace, ptrace);

int my_mprotect(void *addr, size_t len, int prot) {
    return mprotect(addr, len, 7);
}
INTERPOSE_FUNCTION(my_mprotect, mprotect);

// --- Offset Tabanlı Yama (Inline Patch) ---
// Semboller gizli olduğu için direkt bu fonksiyonu kullanıyoruz
void patch_at_offset(const char* moduleName, uintptr_t offset) {
    uintptr_t base = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char* name = _dyld_get_image_name(i);
        if (strstr(name, moduleName)) {
            base = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }
    
    if (base != 0) {
        uintptr_t target = base + offset;
        // Sayfa korumasını RWX yap
        mprotect((void *)(target & ~0xFFF), 0x1000, PROT_READ | PROT_WRITE | PROT_EXEC);
        // ARM64 'RET' (0xD65F03C0) yazarak fonksiyonu etkisizleştir
        *(uint32_t *)target = 0xD65F03C0;
        printf("[+] %s + 0x%lx adresine RET yazildi.\n", moduleName, offset);
    }
}

__attribute__((constructor))
static void initialize() {
    printf("[*] Bypass ARM64: Interpose + Offset Patch Aktif 🔥\n");

    // AnoSDK sembolleri hata verdiği için onları buraya offset olarak ekledik
    // Bu offsetler senin anogs.txt dosyasındaki adreslerdir
    patch_at_offset("anogs", 0xF012C); // Raporlama Wrapper
    patch_at_offset("anogs", 0x2DD28); // DelReport (Eski offset)
    patch_at_offset("anogs", 0x80927); // GetReport (Eski offset)
}
