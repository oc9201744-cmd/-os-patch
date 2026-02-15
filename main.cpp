#include <iostream>
#include <substrate.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#include <string.h>

// --- Orijinal Fonksiyon Pointer'ları ---
int (*old_strcmp)(const char *s1, const char *s2);
long (*old_DelReport)(void);
long (*old_GetReport)(void);
int (*old_ptrace)(int request, pid_t pid, caddr_t addr, int data);

// --- Hook Fonksiyonları ---

// 1. strcmp Bypass: anti_sp2s kontrolünü her zaman geç
int new_strcmp(const char *s1, const char *s2) {
    if (s2 != NULL && strstr(s2, "anti_sp2s")) {
        return 0; // Eşleşme var gibi davran
    }
    return old_strcmp(s1, s2);
}

// 2. Raporlama Bypass: Rapor gönderme fonksiyonlarını sustur
long new_ReportData_Bypass() {
    return 0; // Başarılı ama boş döndür
}

// 3. ptrace Bypass: Anti-debug engelle
int new_ptrace(int request, pid_t pid, caddr_t addr, int data) {
    return 0; // Her zaman başarılı dön
}

// --- Bellek Yaması (Inline Patch) Yardımcısı ---
void patch_memory(uintptr_t address, uint32_t instruction) {
    // Jailbreaksiz cihazlarda bellek yazma izni kısıtlıdır.
    // Ancak constructor içinde dylib yüklenirken denenebilir.
    // 0xC0035FD6 = ARM64 'RET' komutu
    *(uint32_t *)address = instruction;
}

// --- Ana Yükleyici ---
void setup_bypass() {
    // 1. Standart C Fonksiyonlarını Hookla
    MSHookFunction((void *)strcmp, (void *)&new_strcmp, (void **)&old_strcmp);
    MSHookFunction((void *)ptrace, (void *)&new_ptrace, (void **)&old_ptrace);

    // 2. AnoSDK (anogs) Modülünü Bul ve İçindeki Fonksiyonları Hookla
    uintptr_t anogs_base = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, "anogs") || strstr(name, "libanogs.so")) {
            anogs_base = (uintptr_t)_dyld_get_image_header(i);
            
            // Sembolleri bul (Eğer export edilmişse)
            void* handle = dlopen(name, RTLD_LAZY);
            if (handle) {
                void* delReportSym = dlsym(handle, "AnoSDKDelReportData3_0");
                if (delReportSym) MSHookFunction(delReportSym, (void *)&new_ReportData_Bypass, (void **)&old_DelReport);
                
                void* getReportSym = dlsym(handle, "AnoSDKGetReportData3_0");
                if (getReportSym) MSHookFunction(getReportSym, (void *)&new_ReportData_Bypass, (void **)&old_GetReport);
            }

            // 3. Inline Patch (Offset tabanlı - sub_F012C örneği)
            // Not: Jailbreaksiz cihazlarda bu kısım mprotect kısıtlamasına takılabilir.
            // Bu yüzden MSHookFunction (sembol varsa) daha güvenlidir.
            if (anogs_base != 0) {
                // patch_memory(anogs_base + 0xF012C, 0xD65F03C0); 
            }
            break;
        }
    }
}

// Dylib yüklendiği an çalışacak constructor
__attribute__((constructor))
static void initialize() {
    setup_bypass();
}
