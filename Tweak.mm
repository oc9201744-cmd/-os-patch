#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <substrate.h>
#include <vector>

// --- Memory Patch Fonksiyonu ---
void patch_memory(uintptr_t address, std::vector<uint8_t> data) {
    mach_port_t self = mach_task_self();
    kern_return_t kr = vm_protect(self, (vm_address_t)address, data.size(), FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr == KERN_SUCCESS) {
        memcpy((void *)address, data.data(), data.size());
        vm_protect(self, (vm_address_t)address, data.size(), FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

// --- Ekrana Uyarı Yazısı Basma ---
void hile_aktif_mesaji() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V36"
                                    message:@"\n🚀 Hile Aktif Edildi!\nRapor Kanalları Kapatıldı."
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

__attribute__((constructor))
static void start_memory_patch() {
    // Oyunun tamamen yüklenmesi için 15 saniye bekle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        // ARM64 için "RET" (Geri dön) komutu: 0xC0 0x03 0x5F 0xD6
        std::vector<uint8_t> ret_patch = {0xC0, 0x03, 0x5F, 0xD6};

        // --- Memory Patch Uygulamaları (Slide Otomatik Hesaplanır) ---
        patch_memory(slide + 0x202B5C, ret_patch);
        patch_memory(slide + 0x202D9C, ret_patch);
        patch_memory(slide + 0x202F50, ret_patch);
        patch_memory(slide + 0x20297C, ret_patch);
        patch_memory(slide + 0x202A2C, ret_patch);
        patch_memory(slide + 0x2030FC, ret_patch);

        // Ekranda uyarıyı göster
        hile_aktif_mesaji();
        
        NSLog(@"[Gemini] Memory Patch Tamamlandı ve Uyarı Gösterildi!");
    });
}
