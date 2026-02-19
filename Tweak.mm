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

// --- SORUNLU FONKSİYONUN DÜZELTİLMİŞ HALİ ---
uint64_t (*orig_AnoSDKGetReportData3_0)();
uint64_t new_AnoSDKGetReportData3_0() {
    // 1. Orijinal fonksiyonu çağırıyoruz ki 'v1' referansı düzgünce oluşsun (Crash engelleme)
    uint64_t v1_result = 0;
    if (orig_AnoSDKGetReportData3_0) {
        v1_result = orig_AnoSDKGetReportData3_0();
    }

    // 2. ŞİMDİ MÜDAHALE: Eğer bir veri döndüyse, o verinin içini boşaltıyoruz
    // Bu sayede oyun "veri var" sanıyor ama veri aslında boş (0).
    if (v1_result != 0) {
        // v1 bir pointer ise içeriğini sıfırlıyoruz
        // Genelde 37 numaralı IOCTL verisi 0x40 veya 0x80 byte olur.
        memset((void *)v1_result, 0, 8); // İlk 8 byte'ı (rapor ID'sini) sıfırla
    }

    // 3. Oyunun beklediği o 'v1' adresini döndür ama içi temiz olsun
    return v1_result; 
}

// Bütünlük Kontrolü (Aynı kalıyor)
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

// Popup Bildirimi
void show_stealth_popup() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (!win) win = [[UIApplication sharedApplication] windows].firstObject;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"System" 
                                                                       message:@"Stealth Mode Active" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [win.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

__attribute__((constructor))
static void global_init() {
    void *m_ptr = dlsym(RTLD_DEFAULT, "memcmp");
    if (m_ptr) DobbyHook(m_ptr, (void *)new_memcmp, (void **)&orig_memcmp);

    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "anogs") || strstr(name, "ace_cs2"))) {
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            anogs_backup = malloc(anogs_size);
            memcpy(anogs_backup, (void *)anogs_base, anogs_size);
            
            // Düzeltilmiş Hook: 0x2DCC8 (Lütfen IDA'dan doğrula)
            DobbyHook((void *)(anogs_base + 0x2DCC8), (void *)new_AnoSDKGetReportData3_0, (void **)&orig_AnoSDKGetReportData3_0);
            
            show_stealth_popup();
            break;
        }
    }
}
