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

// --- 1. FONKSİYON: AnoSDKGetReportData3_0 ---
// Bu fonksiyon rapor verisi döndürüyor.
uint64_t (*orig_AnoSDKGetReportData3_0)();
uint64_t new_AnoSDKGetReportData3_0() {
    // Orijinali çağırıp sistemi uyandırmıyoruz.
    // IDA çıktısında return v1 (v1=0) diyor. Biz de direkt 0 döndürüyoruz.
    return 0LL; 
}

// --- 2. FONKSİYON: AnoSDKDelReportData3_0 (0x2DCC8) ---
// Bu fonksiyon raporları siliyor/yönetiyor.
uint64_t (*orig_AnoSDKDelReportData3_0)();
uint64_t new_AnoSDKDelReportData3_0() {
    // Bu fonksiyonun çalışması güvenlidir ama rapor yokmuş gibi davranmasını sağlıyoruz.
    // Orijinali çağırmak yerine direkt başarı (0 veya orijinal başlangıç değeri) dönebiliriz.
    return 0LL;
}

// --- 3. FONKSİYON: sub_6BBFC ---
// IDA çıktındaki 'result + 964' kontrolünü susturmak için
uint64_t (*orig_sub_6BBFC)();
uint64_t new_sub_6BBFC() {
    uintptr_t res = (uintptr_t)orig_sub_6BBFC();
    if (res != 0) {
        // Hata bayrağını (result + 964) sıfırla ki JUMPOUT tetiklenmesin
        *(uint32_t *)(res + 964) = 0;
    }
    return (uint64_t)res;
}

// --- GİZLİLİK KATMANI (Bütünlük Kontrolü) ---
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
    if (m_ptr) DobbyHook(m_ptr, (void *)new_memcmp, (void **)&orig_memcmp);

    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && (strstr(name, "anogs") || strstr(name, "ace_cs2"))) {
            anogs_base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            anogs_backup = malloc(anogs_size);
            memcpy(anogs_backup, (void *)anogs_base, anogs_size);
            
            // IDA çıktısındaki adreslere göre hooklar:
            // GetReportData:
            DobbyHook((void *)(anogs_base + 0x2DCC8), (void *)new_AnoSDKGetReportData3_0, (void **)&orig_AnoSDKGetReportData3_0);
            
            // sub_6BBFC (964 offset kontrolü):
            DobbyHook((void *)(anogs_base + 0x6BBFC), (void *)new_sub_6BBFC, (void **)&orig_sub_6BBFC);
            
            break;
        }
    }
}
