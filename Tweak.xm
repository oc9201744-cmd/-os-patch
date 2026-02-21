#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>

// --- KRİTİK DÜZELTME BURASI ---
// C++'ın fonksiyon ismini bozmamasını sağlıyoruz
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);
#ifdef __cplusplus
}
#endif

// --- Manuel Yama Fonksiyonu ---
void apply_dobby_patch(uintptr_t target_addr) {
    uint8_t nop_bytes[] = {0x1F, 0x20, 0x03, 0xD5}; // ARM64 NOP
    
    if (DobbyCodePatch((void *)target_addr, nop_bytes, 4) == 0) {
        NSLog(@"[Dobby] Başarıyla Yamalandı: 0x%lx", target_addr);
    } else {
        NSLog(@"[Dobby] Yama Hatası: 0x%lx", target_addr);
    }
}

// Modern Bildirim Basma Fonksiyonu
void show_alert(NSString *msg) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].windows.firstObject;

        if (window.rootViewController) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dobby V4" 
                                                                           message:msg 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam" style:UIAlertActionStyleDefault handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

%ctor {
    uintptr_t base_addr = (uintptr_t)_dyld_get_image_header(0);

    // Senin adreslerin
    apply_dobby_patch(base_addr + 0xF1198);
    apply_dobby_patch(base_addr + 0xF11A0);
    apply_dobby_patch(base_addr + 0xF119C);
    apply_dobby_patch(base_addr + 0xF11B0);
    apply_dobby_patch(base_addr + 0xF11B4);

    show_alert(@"Dobby Bypass Aktif!\nAdresler NOP'landı.");
}
