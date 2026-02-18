#include <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <string.h>

// Dobby'nin header dosyasını tırnakla çağırıyoruz
#include "dobby.h" 

// ASLR (Adres Kayması) hesaplama
uintptr_t get_base_address(const char *image_name) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, image_name)) {
            return _dyld_get_image_vmaddr_slide(i) + 0x100000000;
        }
    }
    return 0;
}

void do_patch() {
    // --- AYARLAR ---
    const char *binName = "UygulamaBinaryAdi"; // Burayı değiştir kanka
    uintptr_t offset = 0xD3848;                // B.EQ satırı (TST + 4)
    // ---------------

    uintptr_t base = get_base_address(binName);
    if (base != 0) {
        void *target = (void *)(base + offset);
        
        // ARM64 NOP Hex: 0x1F 0x20 0x03 0xD5
        uint8_t nop_bytes[] = {0x1F, 0x20, 0x03, 0xD5};

        if (DobbyCodePatch(target, nop_bytes, 4) == 0) {
            NSLog(@"[KankaPatch] %s + 0x%lx adresine NOP atıldı!", binName, offset);
        }
    }
}

__attribute__((constructor))
static void init() {
    // Uygulama açılırken crash yememek için 1 saniye bekletiyoruz
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        do_patch();
    });
}
