#include <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <string.h>

// Dobby'nin fonksiyonunu dışarıdan (libdobby.a) manuel olarak çağırıyoruz
extern "C" int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t size);

// ASLR (Adres Kayması) hesaplama
uintptr_t get_base_address(const char *image_name) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, image_name)) {
            // ARM64 iOS uygulamaları genellikle 0x100000000 base adresinden başlar
            return _dyld_get_image_vmaddr_slide(i) + 0x100000000;
        }
    }
    return 0;
}

void apply_patches() {
    // BURAYI DEĞİŞTİR: Hedef uygulama adı
    const char *targetBin = "HedefUygulama"; 
    
    uintptr_t base = get_base_address(targetBin);
    if (base != 0) {
        // Ofset: Resimdeki TST'den sonraki satır (B.EQ)
        // loc_D3844 + 4 byte = 0xD3848
        void *patch_addr = (void *)(base + 0xD3848);

        // ARM64 NOP Hex: 1F 20 03 D5
        uint8_t nop_patch[] = {0x1F, 0x20, 0x03, 0xD5};

        if (DobbyCodePatch(patch_addr, nop_patch, 4) == 0) {
            NSLog(@"[Patch] Başarılı: 0x%lx adresine NOP yazıldı.", (uintptr_t)patch_addr);
        }
    }
}

__attribute__((constructor))
static void init() {
    // Uygulama belleğe yüklendikten 1 saniye sonra patchle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_patches();
    });
}
