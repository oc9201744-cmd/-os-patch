#include <stdio.h>
#include <string.h>
#include <dlfcn.h>
#include <stdint.h>
#include <sys/mman.h>
#include <mach-o/dyld.h>

// --- Interpose Makrosu ---
typedef struct interpose_substitution {
    const void* replacement;
    const void* original;
} interpose_substitution_t;

#define INTERPOSE_FUNCTION(replacement, original) \
    __attribute__((used)) static const interpose_substitution_t interpose_##replacement \
    __attribute__((section("__DATA,__interpose"))) = { (const void*)(unsigned long)&replacement, (const void*)(unsigned long)&original }

// --- Extern Tanımlamalar ---
extern "C" {
    int ptrace(int request, int pid, void* addr, int data);
    long AnoSDKDelReportData3_0();
    long AnoSDKGetReportData3_0();
}

// --- 1. strcmp (anti_sp2s) Bypass ---
int my_strcmp(const char *s1, const char *s2) {
    if (s2 != NULL && strstr(s2, "anti_sp2s")) return 0;
    return strcmp(s1, s2);
}
INTERPOSE_FUNCTION(my_strcmp, strcmp);

// --- 2. ptrace (Anti-Debug) Bypass ---
int my_ptrace(int request, int pid, void* addr, int data) {
    return 0; 
}
INTERPOSE_FUNCTION(my_ptrace, ptrace);

// --- 3. Raporlama Bypass ---
long my_DelReport() { return 0; }
long my_GetReport() { return 0; }
INTERPOSE_FUNCTION(my_DelReport, AnoSDKDelReportData3_0);
INTERPOSE_FUNCTION(my_GetReport, AnoSDKGetReportData3_0);

// --- 4. mprotect Bypass (Frida'daki bonus) ---
int my_mprotect(void *addr, size_t len, int prot) {
    // Frida'daki gibi her zaman RWX (7) zorla
    return mprotect(addr, len, 7);
}
INTERPOSE_FUNCTION(my_mprotect, mprotect);

// --- 5. Inline Patching (sub_F012C & Diğer Offsetler) ---
void patch_offset(const char* moduleName, uintptr_t offset, uint32_t instruction) {
    uintptr_t base = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        if (strstr(_dyld_get_image_name(i), moduleName)) {
            base = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }
    
    if (base != 0) {
        uintptr_t target = base + offset;
        // Jailbreaksiz cihazlarda bu kısım mprotect (7) sayesinde çalışabilir
        mprotect((void *)(target & ~0xFFF), 0x1000, PROT_READ | PROT_WRITE | PROT_EXEC);
        *(uint32_t *)target = instruction; // Örn: 0xD65F03C0 (RET)
        printf("[+] Patched %s at offset 0x%lx\n", moduleName, offset);
    }
}

// --- Ana Yükleyici ---
__attribute__((constructor))
static void initialize() {
    printf("[*] Tüm Bypasslar Devreye Alındı: strcmp, ptrace, mprotect, AnoSDK 🔥\n");

    // sub_F012C ve diğer offset patch'lerini burada yapıyoruz
    // 0xD65F03C0 = ARM64 RET komutu
    patch_offset("anogs", 0xF012C, 0xD65F03C0); 
    patch_offset("anogs", 0x2DD28, 0xD65F03C0); // DelReport fallback
    patch_offset("anogs", 0x80927, 0xD65F03C0); // GetReport fallback
}
