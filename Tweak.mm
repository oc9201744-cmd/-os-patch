#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>
#include <substrate.h>

/*
    GEMINI V63 - FIX EDITION
    - sys_icache_invalidate hatası giderildi.
    - Aktivasyon: 10 Saniye
    - Hex Patch: 20 00 80 d2 c0 03 5f d6
*/

// --- BELLEK YAZMA FONKSİYONU ---
void patch_memory(uintptr_t address, uint8_t *data, size_t size) {
    mach_port_t task = mach_task_self();
    
    // Bellek korumasını yazılabilir hale getir (RWX)
    vm_protect(task, (vm_address_t)address, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    // Yamayı uygula
    memcpy((void *)address, data, size);
    
    // Korumayı eski haline döndür (RX)
    vm_protect(task, (vm_address_t)address, size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    
    // HATA DÜZELTME: sys_icache_invalidate yerine builtin fonksiyon kullanımı
    __builtin___clear_cache((char *)address, (char *)address + size);
}

// --- GÖRSEL UYARI ---
void show_gemini_alert() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V63"
                                    message:@"Yama 10 saniye sonunda başarıyla uygulandı!\nDurum: Aktif (Survival On)"
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                    window = [((UIWindowScene *)scene).windows firstObject];
                    break;
                }
            }
        }
        if (!window) window = [[UIApplication sharedApplication] keyWindow];
        
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// --- ANA MOTOR ---
__attribute__((constructor))
static void start_engine() {
    // 10 Saniye Gecikme
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        if (slide > 0) {
            // Hex: mov x0, #1; ret
            uint8_t patch_hex[] = {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
            
            // Adreslere yama yap
            patch_memory(slide + 0x17998, patch_hex, sizeof(patch_hex));
            patch_memory(slide + 0xF012C, patch_hex, sizeof(patch_hex));
            patch_memory(slide + 0xF838C, patch_hex, sizeof(patch_hex));

            show_gemini_alert();
            NSLog(@"[GEMINI] Memory Patch tamamlandı.");
        }
    });
}
