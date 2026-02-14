#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>

// Substrate olmadan hafızaya yazma fonksiyonu
void patch_memory(uintptr_t address, uint32_t data) {
    mach_port_t task = mach_task_self();
    kern_return_t kr;

    // Yazma izni almak için korumayı kaldırıyoruz
    kr = vm_protect(task, address, sizeof(data), FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) return;

    // Veriyi (RET komutunu) yazıyoruz
    kr = vm_write(task, address, (vm_offset_t)&data, sizeof(data));
    
    // Korumayı eski haline getiriyoruz (Read + Execute)
    vm_protect(task, address, sizeof(data), FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
}

void setup_bypass() {
    // 1000F838C -> Ofset kısmını alıyoruz
    uintptr_t offset = 0xF838C; 
    uintptr_t base = _dyld_get_image_header(0);
    uintptr_t target_address = base + offset;

    // 0xD65F03C0 = ARM64 'RET' komutu
    patch_memory(target_address, 0xD65F03C0);
}

__attribute__((constructor))
static void init() {
    setup_bypass();
}
