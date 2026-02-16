#import <UIKit/UIKit.h>
#include <sys/mman.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

void show_bypass_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;

        if (window && ![window viewWithTag:2026]) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, window.frame.size.width, 20)];
            lbl.text = @"🛡️ ONUR CAN SMART GHOST ACTIVE ✅";
            lbl.textColor = [UIColor greenColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:9];
            lbl.tag = 2026;
            [window addSubview:lbl];
        }
    });
}

__attribute__((constructor))
static void start_smart_lockdown() {
    // 15 saniye bekle (Oyunun tüm kontrolleri bitirmesi için)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uint32_t count = _dyld_image_count();
        for (uint32_t i = 0; i < count; i++) {
            const char *name = _dyld_get_image_name(i);
            
            if (name && strstr(name, "anogs")) {
                uintptr_t base_addr = (uintptr_t)_dyld_get_image_header(i);
                
                // --- STRATEJİ DEĞİŞİKLİĞİ ---
                // PROT_READ: Oyun dosyayı okuyabilsin (Crash yapmaz)
                // Yazma (Write) ve Yürütme (Exec) YASAK!
                // Böylece rapor oluşturamaz ve tarama yapamaz.
                mprotect((void *)(base_addr & ~PAGE_MASK), PAGE_SIZE * 1000, PROT_READ);
                break;
            }
        }
        show_bypass_label();
    });
}
