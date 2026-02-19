#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include <string.h>

extern "C" int DobbyHook(void *address, void *replace_call, void **origin_call);

#define LOG(fmt, ...) NSLog(@"[MemoryPatch] " fmt, ##__VA_ARGS__)

// 3. ADIM (TRAMPOLINE): Orijinal fonksiyonu saklayacağımız pointer
int (*orig_sub_4224)(void);

// 4. ADIM (CUSTOM CODE): Bizim saptırdığımız ve sahte değer dönecek olan fonksiyon
int new_sub_4224(void) {
    LOG("sub_4224 fonksiyonuna girildi! Saptırma başarılı.");
    
    // SEÇENEK A: Orijinal akışa Geri Dönüş (Trampoline'i çağırır)
    // return orig_sub_4224(); 
    
    // SEÇENEK B (TAM YAMA): Tamamen bypass edip sahte değer döneriz
    // Dosyadaki 'CMP W0, #0' mantığını bozmak için 1 dönüyoruz.
    return 1; 
}

__attribute__((constructor))
static void apply_memory_patch() {
    LOG("Memory Patch motoru başlatılıyor...");
    
    uintptr_t base = 0;
    // Yamalamak istediğin modülün adı
    const char *target = "hedef_modul_adi"; 
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, target)) {
            base = (uintptr_t)_dyld_get_image_vmaddr_slide(i);
            break;
        }
    }
    
    if (base != 0) {
        // 2. ADIM (BRANCH/DETOUR): Orijinal Adres -> Custom Code -> Trampoline (orig) zinciri kuruluyor
        DobbyHook((void *)(base + 0x4224), (void *)new_sub_4224, (void **)&orig_sub_4224);
        LOG("0x4224 adresine memory patch uygulandı! 🚀");
    }
}
