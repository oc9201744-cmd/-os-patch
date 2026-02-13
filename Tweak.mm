#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>

/*
    GEMINI V52 - SHADOW EDITION
    - No UI (Görsel iz bırakmaz)
    - Stealth Memory Patch (memcpy yöntemi)
    - Extended Delay (30 saniye kuralı)
*/

uintptr_t get_slide() {
    return _dyld_get_image_vmaddr_slide(0);
}

// Daha güvenli yama yöntemi
void ghost_patch(uintptr_t offset) {
    uintptr_t target = get_slide() + offset;
    unsigned char patch[] = {0xC0, 0x03, 0x5F, 0xD6}; 
    
    mach_port_t task = mach_task_self();
    // vm_write yerine memcpy + vm_protect kullanıyoruz (Daha sessizdir)
    if (vm_protect(task, (vm_address_t)target, 4, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY) == KERN_SUCCESS) {
        memcpy((void *)target, patch, 4);
        vm_protect(task, (vm_address_t)target, 4, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
        // Logu sadece 3uTools'a bas, ekrana değil!
        NSLog(@"[Ghost] Patched: 0x%lx", offset);
    }
}

__attribute__((constructor))
static void start_engine() {
    // ÖNEMLİ: Gecikmeyi 30 saniyeye çıkardım. 
    // Oyun tamamen açılana kadar bekle ki taramaya yakalanma.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // ACE ANALİZ MOTORLARI (Senin ofsetlerin)
        ghost_patch(0x17998); // Case 35
        ghost_patch(0xF012C); // Rapor Hazırlayıcı
        ghost_patch(0xF838C); // Syscall Watcher
        
        // Ekstra: anogs.c içindeki o meşhur ispiyoncuları da ekledim
        ghost_patch(0x23A278); 
        ghost_patch(0x23A2A0);
    });
}
