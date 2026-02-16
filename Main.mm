#import <UIKit/UIKit.h>
#include <sys/mman.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

// --- UI GÖSTERİM FONKSİYONU ---
void show_bypass_label() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        // Modern iOS (13+) için pencere yakalama
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        // Eski sürümler için fallback
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;

        if (window && ![window viewWithTag:2026]) {
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, window.frame.size.width, 20)];
            lbl.text = @"🛡️ ONUR CAN PRECISION GHOST ACTIVE ✅";
            lbl.textColor = [UIColor greenColor];
            lbl.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
            lbl.textAlignment = NSTextAlignmentCenter;
            lbl.font = [UIFont boldSystemFontOfSize:9];
            lbl.tag = 2026;
            [window addSubview:lbl];
        }
    });
}

// --- ANA KONTROL MERKEZİ ---
__attribute__((constructor))
static void initialize_ano_killer() {
    // Oyunun ve anogs framework'ün yüklenmesi için 12 saniye bekle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1. ADIM: ANOGS HAFIZA İZİNLERİNİ KAPAT (RWX KILL)
        uint32_t count = _dyld_image_count();
        BOOL killed = NO;
        
        for (uint32_t i = 0; i < count; i++) {
            const char *name = _dyld_get_image_name(i);
            if (name && strstr(name, "anogs")) {
                uintptr_t base_addr = (uintptr_t)_dyld_get_image_header(i);
                
                // Kütüphanenin tüm yetkilerini (Okuma, Yazma, Yürütme) elinden alıyoruz.
                // PROT_NONE = Tam koruma, SDK artık hiçbir yere erişemez.
                if (mprotect((void *)(base_addr & ~PAGE_MASK), PAGE_SIZE * 800, PROT_NONE) == 0) {
                    killed = YES;
                }
                break;
            }
        }

        // 2. ADIM: YAZIYI GÖSTER
        // NOT: anogs bulunsa da bulunmasa da bypass'ın yüklendiğini teyit etmek için yazıyı basıyoruz.
        show_bypass_label();
    });
}
