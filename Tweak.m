#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>
#include <dispatch/dispatch.h>
#include <stdint.h>
#include <string.h>

// --- Dobby Hook Tanımı ---
#ifdef __cplusplus
extern "C" {
#endif
    int DobbyHook(void *function_address, void *replace_call, void **origin_call);
#ifdef __cplusplus
}
#endif

// --- Tip Tanımlamaları ---
typedef long long int64_t_ace;

// --- Orijinal Fonksiyonları Saklayacağımız Değişkenler ---
static int64_t_ace (*orig_sub_F012C)(void *a1);
static int64_t_ace (*orig_sub_11D85C)(int64_t_ace a1, int64_t_ace a2, ...);

#pragma mark - Hook Fonksiyonları (Bypass Mantığı)

// 1. Raporlayıcıyı Sustur (Bypass 1)
static int64_t_ace hook_sub_F012C(void *a1) {
    // Rapor göndermeyi engellemek için 0 döndürüyoruz.
    return 0; 
}

// 2. Hafıza Taraması Engelleyici (Bypass 2)
static int64_t_ace hook_sub_11D85C(int64_t_ace a1, int64_t_ace a2, ...) {
    // 0x35 (Case 35) taraması yakalandığında "temiz" (1) döndür.
    if (a2 != 0 && *(unsigned char *)(a2 + 168) == 0x35) {
        return 1; 
    }
    // Diğer durumlarda oyunu bozmamak için 0 dönüyoruz.
    return 0; 
}

#pragma mark - ASLR / BASE Hesaplama

static uintptr_t get_game_base(void) {
    uintptr_t slide = 0;
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "ShadowTrackerExtra")) {
            slide = _dyld_get_image_vmaddr_slide(i);
            break;
        }
    }
    return (0x100000000 + slide);
}

#pragma mark - Constructor (Başlatıcı)

__attribute__((constructor))
static void onurcan_initializer(void) {
    // ❗ KRİTİK: Güvenlik sisteminin yüklenmesi için 45 saniye bekleme.
    // Lobi banlarını ve erken tespiti bu engeller.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(45.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        
        uintptr_t base = get_game_base();
        NSLog(@"[onurcan] Base Adresi Hesaplandı: 0x%lx", base);

        if (base > 0x100000000) {
            // --- Dobby İle Hook İşlemleri ---
            DobbyHook((void *)(base + 0xF012C), (void *)hook_sub_F012C, (void **)&orig_sub_F012C);
            DobbyHook((void *)(base + 0x11D85C), (void *)hook_sub_11D85C, (void **)&orig_sub_11D85C);
            
            NSLog(@"[onurcan] Dobby Bypass Aktif Edildi.");

            // Kendi uygulaman için uyarı banner'ı
            UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:@"Onurcan Bypass"
                                                message:@"Bypass başarıyla yüklendi.\nMaça girebilirsin kanka."
                                         preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Tamam"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            
            UIWindow *keyWindow = nil;
            if (@available(iOS 13.0, *)) {
                for (UIWindowScene* scene in [UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive) {
                        keyWindow = ((UIWindowScene*)scene).windows.firstObject;
                        break;
                    }
                }
            } else {
                keyWindow = [UIApplication sharedApplication].keyWindow;
            }
            
            [keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        } else {
            NSLog(@"[onurcan] Hata: Oyun base adresi bulunamadı!");
        }
    });
}
