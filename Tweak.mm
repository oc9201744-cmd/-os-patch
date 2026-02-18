#include <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <string.h>
#include "./dobby.h" // Aynı dizinde olduğunu belirttik

// Uygulamanın (veya kütüphanenin) ASLR kaymasını hesaplayan fonksiyon
uintptr_t get_base_address(const char *image_name) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, image_name)) {
            // iOS 64-bit base address + slide
            return _dyld_get_image_vmaddr_slide(i) + 0x100000000;
        }
    }
    return 0;
}

void apply_patch() {
    // BURAYI DEĞİŞTİR: Hedef uygulamanın binary adını yaz (Örn: "MobileNotes")
    const char *target_binary = "HedefUygulama"; 
    
    uintptr_t base = get_base_address(target_binary);
    
    if (base != 0) {
        // BURAYI KONTROL ET: IDA'daki tam ofseti buraya yaz
        // loc_D3844'teki TST'den sonraki B.EQ satırı muhtemelen +4'tedir.
        uintptr_t patch_address = base + 0xD3848; 

        // ARM64 NOP (No Operation) Instruction Hex: 0x1F2003D5
        // Küçük endian (little endian) olarak diziyoruz:
        uint8_t nop_instr[] = {0x1F, 0x20, 0x03, 0xD5};

        // Dobby ile belleği yamala
        if (DobbyCodePatch((void *)patch_address, nop_instr, 4) == 0) {
            NSLog(@"[MemoryPatch] Başarıyla 0x%lx adresine uygulandı!", patch_address);
        } else {
            NSLog(@"[MemoryPatch] Yama başarısız oldu!");
        }
    } else {
        NSLog(@"[MemoryPatch] '%s' bulunamadı, base adres 0.", target_binary);
    }
}

// Dylib yüklendiğinde otomatik çalışan constructor
__attribute__((constructor))
static void initialize() {
    // Uygulama tamamen belleğe yerleşsin diye 1 saniye bekleyip patch atıyoruz
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        apply_patch();
    });
}
