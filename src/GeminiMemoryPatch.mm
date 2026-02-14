#include <substrate.h>
#include <mach-o/dyld.h>

// ShadowTrackerExtra içindeki hedef ofsetin
uintptr_t get_ShadowTrackerExtra_Base() {
    return _dyld_get_image_header(0); // Ana uygulama (ShadowTrackerExtra) genellikle index 0'dır
}

void setup_bypass() {
    // Senin log kaydındaki ve bak.txt içindeki o kritik ofset
    // Not: Fonksiyonun tam başlangıç adresini (sub_...) kullanmak en sağlıklısıdır.
    uintptr_t target_offset = 0xF838C; 
    uintptr_t absolute_address = get_ShadowTrackerExtra_Base() + target_offset;

    // ARM64 için 'RET' komutu (Hemen geri dön, hiçbir rapor paketleme)
    uint32_t patch_instruction = 0xD65F03C0; 

    // Hafızaya yamayı yazıyoruz
    MSHookMemory((void *)absolute_address, &patch_instruction, sizeof(patch_instruction));
}

// Uygulama açıldığında çalıştır
__attribute__((constructor))
static void initialize() {
    setup_bypass();
}
