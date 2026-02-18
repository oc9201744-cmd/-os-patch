#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>

extern "C" {
    int DobbyHook(void *address, void *replace_call, void **origin_call);
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t size);
}

#define LOG(fmt, ...) NSLog(@"[Bypass] " fmt, ##__VA_ARGS__)

typedef void (*orig_sub_D372C_type)(void *arg0, ...);
orig_sub_D372C_type orig_sub_D372C = NULL;

void my_sub_D372C(void *arg0) {
    LOG(@"sub_D372C çağrıldı! Bypass ediliyor...");
    // Orijinal fonksiyonu çağırmıyoruz -> bypass
}

__attribute__((constructor))
static void init() {
    LOG("Bypass kütüphanesi yükleniyor...");
    
    const char *target_image = "libanogs"; // Hedef image adı (kısmi eşleşme)
    uintptr_t base = 0;
    
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, target_image)) {
            // _dyld_get_image_header(i) zaten slide uygulanmış adresi verir
            base = (uintptr_t)_dyld_get_image_header(i);
            LOG("Hedef image bulundu: %s", name);
            LOG("Base adres (header): 0x%llx", (uint64_t)base);
            break;
        }
    }
    
    if (base == 0) {
        LOG("Hata: '%s' içeren image bulunamadı! Tüm image'lar:", target_image);
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            LOG("Image %2u: %s", i, _dyld_get_image_name(i));
        }
        return;
    }
    
    // Offset 0xD372C (kullanıcının verdiği)
    void *target_addr = (void *)(base + 0xD372C);
    LOG("Hedef fonksiyon adresi: %p", target_addr);
    
    int ret = DobbyHook(target_addr, (void *)my_sub_D372C, (void **)&orig_sub_D372C);
    if (ret == 0) {
        LOG("Hook başarıyla kuruldu!");
    } else {
        LOG("Hook kurulamadı! Hata kodu: %d", ret);
    }
}