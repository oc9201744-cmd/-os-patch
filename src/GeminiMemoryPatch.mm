#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <stdint.h> // HATA BURADAYDI: uintptr_t için bu şart!

// Hafızaya yazma fonksiyonu
void patch_memory(uintptr_t address, uint32_t data) {
    mach_port_t task = mach_task_self();
    kern_return_t kr;

    // Yazma izni al
    kr = vm_protect(task, address, sizeof(data), FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) return;

    // RET komutunu yaz
    kr = vm_write(task, address, (vm_offset_t)&data, sizeof(data));
    
    // İzinleri eski haline getir (Read + Execute)
    vm_protect(task, address, sizeof(data), FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

void setup_bypass() {
    // Ofsetimiz (ShadowTrackerExtra içindeki yer)
    uintptr_t offset = 0xF838C; 
    
    // Adres tipini zorla dönüştürerek taban adresi al
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
    
    // Hedef adresi hesapla
    uintptr_t target_address = base + offset;

    // 0xD65F03C0 = ARM64 mimarisi için 'RET' (Fonksiyonu bitir)
    patch_memory(target_address, 0xD65F03C0);
}

// Uygulama belleğe yüklendiği an çalışır
__attribute__((constructor))
static void init() {
    setup_bypass();
}
