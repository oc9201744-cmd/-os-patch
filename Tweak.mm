#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>

/*
    GEMINI V63 - LINKER FIX EDITION
    - Linker hatası veren cache fonksiyonları kaldırıldı.
    - Doğrudan ARM64 Cache Flush (Assembly/Syscall) eklendi.
    - Aktivasyon: 10 Saniye
*/

// --- ÖNBELLEK TEMİZLEME (ASM) ---
// Linker hatalarını aşmak için doğrudan çekirdek seviyesinde cache flush
void gemini_clear_cache(void *start, size_t size) {
#if defined(__arm64__) || defined(__aarch64__)
    // ARM64 için instruction cache temizleme
    __asm__ volatile (
        "dc cvau, %0\n"
        "ic ivau, %0\n"
        "isb sy\n"
        : : "r" (start) : "memory"
    );
#endif
}

// --- BELLEK YAZMA FONKSİYONU ---
void patch_memory(uintptr_t address, uint8_t *data, size_t size) {
    mach_port_t task = mach_task_self();
    
    // Belleği yazılabilir yap
    vm_protect(task, (vm_address_t)address, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    // Yamayı uygula
    memcpy((void *)address, data, size);
    
    // Belleği eski haline döndür
    vm_protect(task, (vm_address_t)address, size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    
    // Kendi yazdığımız ASM tabanlı cache flush'ı kullan
    gemini_clear_cache((void *)address, size);
}

// --- GÖRSEL UYARI ---
void show_gemini_alert() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V63"
                                    message:@"Memory Patch Basariyla Uygulandi!\nHex: mov x0, #1; ret"
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        if (slide > 0) {
            uint8_t patch_hex[] = {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
            
            patch_memory(slide + 0x17998, patch_hex, sizeof(patch_hex));
            patch_memory(slide + 0xF012C, patch_hex, sizeof(patch_hex));
            patch_memory(slide + 0xF838C, patch_hex, sizeof(patch_hex));

            show_gemini_alert();
            NSLog(@"[GEMINI] Patch islemi tamam. Linker sorunu ASM ile asildi.");
        }
    });
}
