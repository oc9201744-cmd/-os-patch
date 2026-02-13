#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>
#include <mach/mach.h>

/*
    GEMINI V63 - ASLR & LINKER FIXED
    - ASLR (Slide) hesaplaması eklendi.
    - Inline Assembly ile Cache Flush yapıldı.
    - 10 Saniye gecikmeli aktivasyon.
*/

// --- CACHE FLUSH (ASM) ---
void gemini_clear_cache(void *start, size_t size) {
#if defined(__arm64__) || defined(__aarch64__)
    __asm__ volatile (
        "dc cvau, %0\n"
        "ic ivau, %0\n"
        "isb sy\n"
        : : "r" (start) : "memory"
    );
#endif
}

// --- MEMORY PATCHER ---
void patch_memory(uintptr_t address, uint8_t *data, size_t size) {
    mach_port_t task = mach_task_self();
    
    // Bellek yazma izni al (RWX)
    vm_protect(task, (vm_address_t)address, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    // Byte'ları değiştir
    memcpy((void *)address, data, size);
    
    // Güvenliği geri yükle (RX)
    vm_protect(task, (vm_address_t)address, size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    
    // İşlemciye değişikliği bildir
    gemini_clear_cache((void *)address, size);
}

// --- UI NOTIFICATION ---
void show_gemini_alert() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"GEMINI V63"
                                    message:@"ASLR Kayması Hesaplandı!\nPatch Başarıyla Uygulandı."
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

// --- INITIALIZER ---
__attribute__((constructor))
static void start_engine() {
    // 10 Saniye bekle (ASLR ve Binary yüklenmesi için)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // --- ASLR HESAPLAMA BURADA ---
        // Uygulamanın bellekteki gerçek başlangıç kaymasını alır.
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        if (slide > 0) {
            // "mov x0, #1; ret" makine kodu
            uint8_t patch_hex[] = {0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6};
            
            // ASLR (Slide) + Static Offset = Gerçek RAM Adresi
            patch_memory(slide + 0x17998, patch_hex, sizeof(patch_hex));
            patch_memory(slide + 0xF012C, patch_hex, sizeof(patch_hex));
            patch_memory(slide + 0xF838C, patch_hex, sizeof(patch_hex));

            show_gemini_alert();
            NSLog(@"[GEMINI] ASLR Uygulandı. Slide: 0x%lx", (unsigned long)slide);
        } else {
            NSLog(@"[GEMINI] ASLR Slide degeri alinamadi!");
        }
    });
}
