#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h> // ÖNEMLİ: sys_icache_invalidate için

uintptr_t get_slide() {
    return _dyld_get_image_vmaddr_slide(0);
}

void patch_memory(uintptr_t offset, unsigned char* patch, size_t size) {
    uintptr_t addr = get_slide() + offset;
    mach_port_t task = mach_task_self();
    
    // Sayfa hizalaması (16KB sayfa yapısı için şart)
    uintptr_t page_start = addr & ~0x3FFF;
    size_t page_size = (addr + size - page_start + 0x3FFF) & ~0x3FFF;

    // 1. Yazma izni al
    kern_return_t kr = vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) return;

    // 2. Yamayı yaz
    if (vm_write(task, addr, (vm_offset_t)patch, (mach_msg_type_number_t)size) != KERN_SUCCESS) {
        memcpy((void *)addr, patch, size); // vm_write başarısız olursa alternatif
    }

    // 3. İzinleri eski haline getir (Sadece Oku ve Çalıştır)
    vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);

    // 4. KRİTİK: CPU Önbelleğini temizle (Ban yememek için şart!)
    sys_icache_invalidate((void *)addr, size);
}

void apply_patches() {
    // arm64 'RET' instruction: 0xC0035FD6
    unsigned char ret[] = {0xC0, 0x03, 0x5F, 0xD6};
    uint32_t zero = 0;
    
    // Analiz ettiğimiz Ace/AnoSDK kritik kontrol noktaları
    patch_memory(0xF838C,  ret, 4);  // Sistem çağrı tablosu kontrolü (bak 6.txt)
    patch_memory(0x23998C, ret, 4);  // Raporlama mekanizması
    patch_memory(0x202B5C, ret, 4);  // Thread izleme
    patch_memory(0x2030FC, ret, 4);  // Modül doğrulama
    patch_memory(0x17F4C,  ret, 4);  // Integrity Check (Bütünlük Kontrolü)
    
    // Küçük ofsetlerdeki (Data segmenti) kontrolleri sıfırlıyoruz
    patch_memory(0x30,  (unsigned char*)&zero, 4);
    patch_memory(0x178, (unsigned char*)&zero, 4);
    
    // Tek byte'lık bayrak (Flag) yaması
    unsigned char zero_byte = 0;
    patch_memory(0x376, &zero_byte, 1);
    
    NSLog(@"[TssBypass] Tüm yamalar başarıyla uygulandı!");
}

__attribute__((constructor))
void _init() {
    // 1.5 saniye bekleme süresi iyidir, uygulamanın yüklenmesine izin verir
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        apply_patches();
    });
}
