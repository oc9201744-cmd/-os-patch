#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <UIKit/UIKit.h>

// Dobby'nin fonksiyonunu dışarıdan tanıtıyoruz (import hatası almamak için)
extern int DobbyCodePatch(void *address, uint8_t *buffer, uint32_t buffer_size);

void apply_dobby_patch(uintptr_t target_addr) {
    // ARM64 için NOP komutu: 0xD503201F (Küçük uçlu dizilimi: 1F 20 03 D5)
    uint8_t nop_bytes[] = {0x1F, 0x20, 0x03, 0xD5};
    
    if (DobbyCodePatch((void *)target_addr, nop_bytes, 4) == 0) {
        NSLog(@"[Dobby] Başarıyla Yamalandı: 0x%lx", target_addr);
    } else {
        NSLog(@"[Dobby] Yama Hatası: 0x%lx", target_addr);
    }
}

__attribute__((constructor))
static void initialize() {
    // Oyunun yüklenmesi ve UIKit'in hazır olması için biraz bekle
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1. Ana kütüphanenin başlangıç adresini al (ASLR için)
        uintptr_t base_addr = (uintptr_t)_dyld_get_image_header(0);

        // 2. Senin adreslerini tek tek Dobby ile yamala
        apply_dobby_patch(base_addr + 0xF1198);
        apply_dobby_patch(base_addr + 0xF11A0);
        apply_dobby_patch(base_addr + 0xF119C);
        apply_dobby_patch(base_addr + 0xF11B0);
        apply_dobby_patch(base_addr + 0xF11B4);

        // 3. Ekrana bildirim bas
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

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Dobby V4" 
                                                                       message:@"Anogs Bypass Tamamlandı!\n5 Adet Adres NOP'landı." 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Harika" style:UIAlertActionStyleDefault handler:nil]];
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

// Protokol hatası gelmemesi için boş sınıf
@interface DevHack : NSObject
@end
@implementation DevHack
@end
