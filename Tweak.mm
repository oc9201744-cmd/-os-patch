#include <Foundation/Foundation.h>
#include "dobby.h"
#include <mach-o/dyld.h>
#include <stdint.h>
#include <string.h>

// 1. Modülün (Uygulamanın) Base Adresini Bulma
uintptr_t get_base_address(const char *image_name) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, image_name)) {
            return _dyld_get_image_vmaddr_slide(i) + 0x100000000; // ASLR Slide + Header
        }
    }
    return 0;
}

// 2. Patch İşlemi
void apply_memory_patches() {
    // "UygulamaAdi" kısmını senin uygulamanın binary adı ile değiştir
    uintptr_t base = get_base_address("UygulamaAdi");
    
    if (base != 0) {
        NSLog(@"[Patch] Base Adres Bulundu: 0x%lx", base);

        // ÖRNEK: loc_D3844'teki B.EQ (Branch if Equal) komutunu NOP yapalım
        // Ofset: 0xD3844 + 4 (TST'den sonraki satır olduğu için)
        // Not: IDA'daki tam adresi kontrol et, 0xD3848 olabilir.
        
        void *target_addr = (void *)(base + 0xD3848); 

        // ARM64 için NOP hex kodu: 0x1F2003D5
        uint8_t nop_bytes[] = {0x1F, 0x20, 0x03, 0xD5};

        // Dobby ile belleğe yazma (Memory Protection'ı otomatik halleder)
        if (DobbyCodePatch(target_addr, nop_bytes, 4) == kMemoryOperationSuccess) {
            NSLog(@"[Patch] Başarıyla uygulandı!");
        } else {
            NSLog(@"[Patch] Hata oluştu!");
        }
    } else {
        NSLog(@"[Patch] Modül bulunamadı!");
    }
}

// Uygulama yüklenirken otomatik çalışır
__attribute__((constructor))
static void initialize() {
    // Uygulama tam yüklendikten sonra patch atmak daha güvenlidir
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_memory_patches();
    });
}
