#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>

// --- DOBBY HEADER YERİNE BURAYI KULLAN ---
extern "C" {
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t size);
}
// -----------------------------------------

#define LOG(fmt, ...) NSLog(@"[Bypass] " fmt, ##__VA_ARGS__)

// Orijinal fonksiyon tipi
typedef void (*orig_sub_D372C_type)(void *arg0, ...);
orig_sub_D372C_type orig_sub_D372C = NULL;

// Hook fonksiyonumuz
void my_sub_D372C(void *arg0) {
    LOG(@"sub_D372C çağrıldı! Bypass ediliyor...");
    // Bypass için orijinali çağırmıyoruz
}

__attribute__((constructor))
static void init() {
    LOG("Bypass kütüphanesi yükleniyor...");
    
    // Kanka buraya dikkat: "Anogs.framework/Anogs" yerine sadece "libanogs" yazman daha garantidir
    const char *target_image = "libanogs"; 
    uintptr_t base = 0;
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, target_image)) {
            // ASLR Slide + 0x100000000 (iOS 64-bit standardı)
            base = _dyld_get_image_vmaddr_slide(i) + 0x100000000;
            LOG("Hedef image bulundu: %s, base = 0x%llx", name, (uint64_t)base);
            break;
        }
    }
    
    if (base != 0) {
        // Senin resimdeki ofset 0xD372C
        void *target_addr = (void *)(base + 0xD372C);
        LOG("Hedef adres: %p", target_addr);
        
        int ret = DobbyHook(target_addr, (void *)my_sub_D372C, (void **)&orig_sub_D372C);
        if (ret == 0) {
            LOG("Hook kuruldu!");
        } else {
            LOG("Hook hatası: %d", ret);
        }
    }
}
