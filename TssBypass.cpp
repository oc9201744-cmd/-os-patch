#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <cstdint>
#include <cstdio>
#include <sys/mman.h>
#include <unistd.h>
#include <vector>

// iPhone 15 Pro Max (A17 Pro) için 16KB sayfa yapısı
#define PAGE_SIZE 0x4000 

uintptr_t get_image_vmaddr_slide() {
    return _dyld_get_image_vmaddr_slide(0);
}

uintptr_t calculate_address(uintptr_t offset) {
    return get_image_vmaddr_slide() + offset;
}

// Güvenli Patch Fonksiyonu
bool apply_patch(uintptr_t offset, std::vector<uint8_t> bytes) {
    uintptr_t target_addr = calculate_address(offset);
    size_t size = bytes.size();

    // 1. Sayfayı hizala (Hizalamazsan vm_protect hata verir)
    uintptr_t page_start = target_addr & ~(PAGE_SIZE - 1);
    
    // 2. Bellek korumasını kaldır (Read/Write/Copy)
    // VM_PROT_COPY zorunludur, aksi halde sistem "yazamazsın" der.
    kern_return_t kr = vm_protect(mach_task_self(), (vm_address_t)page_start, PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    if (kr != KERN_SUCCESS) {
        return false;
    }

    // 3. Byte'ları yaz
    memcpy((void *)target_addr, bytes.data(), size);

    // 4. Korumayı eski haline getir (Read/Execute)
    vm_protect(mach_task_self(), (vm_address_t)page_start, PAGE_SIZE, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    
    // 5. Instruction Cache'i temizle (CPU'nun yeni kodu görmesi için şart!)
    sys_icache_invalidate((void *)target_addr, size);

    return true;
}

__attribute__((constructor))
static void init() {
    // Uygulamanın tam yüklenmesi için kısa bir gecikme
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // KULLANIM ÖRNEĞİ:
        // Offset: 0x1234567, Yazılacaklar: RET (True) -> 0x200080D2 0xC0035FD6 (Little Endian)
        // if(apply_patch(0x1234567, {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6})) {
        //     printf("[TssBypass] Patch Basarili!\n");
        // }
    });
}
