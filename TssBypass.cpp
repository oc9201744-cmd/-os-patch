#include <mach/mach.h>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <vector>
#include <string.h>

// Bellek yaması yapan fonksiyon
void patch_memory(uintptr_t address, std::vector<uint8_t> data) {
    kern_return_t kr;
    mach_port_t self = mach_task_self();
    
    // 1. Bellek sayfasının yazma iznini aç
    kr = vm_protect(self, (vm_address_t)address, data.size(), FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) return;

    // 2. Yeni byte'ları kopyala
    memcpy((void *)address, data.data(), data.size());

    // 3. İzinleri eski haline getir (Sadece Okuma ve Çalıştırma)
    vm_protect(self, (vm_address_t)address, data.size(), FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

// Uygulamanın ana modülünün (ASLR dahil) adresini bulur
uintptr_t get_base_address() {
    return (uintptr_t)_dyld_get_image_header(0);
}

__attribute__((constructor))
static void init() {
    // Uygulama başladığında 1 saniye bekle (Hafıza tam yüklenmesi için)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t base = get_base_address();
        
        // ÖRNEK YAMA: 
        // 0x123456 adresindeki fonksiyonu "return true" yap (arm64 için: RET)
        // Burayı kendi ofsetlerinle doldurabilirsin
        // uintptr_t target = base + 0x123456; 
        // patch_memory(target, {0xC0, 0x03, 0x5F, 0xD6}); 
    });
}
