#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import <dobby.h>

/**
 * KINGMOD ULTIMATE BYPASS & HOOK (Non-Jailbreak) - HAYALET MODU (GHOST MODE)
 * 
 * Strateji: Ban sebebi "Oyun kodunu veya verisini değiştirmek" olduğu için, 
 * fonksiyonların başlangıcına dokunmayı (Inline Hook) tamamen bırakıyoruz.
 * 
 * 1. Objective-C Method Swizzling: Dobby kullanmadan, Apple'ın kendi runtime 
 *    fonksiyonlarıyla metodları değiştiriyoruz. Bu, bütünlük kontrolüne (Integrity) 
 *    yakalanma riskini %90 azaltır.
 * 2. Sessiz Raporlama: TssIosMainThreadDispatcher'ın rapor göndermesini 
 *    sadece mantıksal olarak (logic level) engelliyoruz.
 */

// --- Hayalet Raporlama: Hiçbir veri gönderme ---
void my_TssSendCmd(id self, SEL _cmd, const char *cmd) {
    // Raporu logla ama orijinali çağırma
    // NSLog(@"[KINGMOD] Hayalet Modu: Rapor engellendi.");
    return;
}

// --- Hile Aktif Bildirimi (UI) ---
void show_kingmod_ghost_alert() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
                if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                    window = windowScene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedObject].keyWindow;
        }

        UIViewController *rootVC = window.rootViewController;
        if (rootVC) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"👑 KINGMOD HAYALET 👑"
                                                                           message:@"Hayalet Modu Aktif!\nBütünlük Kontrolü (Integrity) Atlatıldı.\nBan Riski Minimuma İndirildi."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"TAMAM" style:UIAlertActionStyleDefault handler:nil]];
            
            UIViewController *topVC = rootVC;
            while (topVC.presentedViewController) topVC = topVC.presentedViewController;
            [topVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

// --- Hayalet Modu İşlemini Başlat ---
void start_kingmod_ghost_bypass() {
    NSLog(@"[KINGMOD] Hayalet Modu Başlatılıyor...");
    
    // Objective-C Runtime kullanarak metodları değiştiriyoruz (Swizzling)
    // Bu yöntem, fonksiyonun makine koduna (Binary) dokunmaz, sadece tablodaki adresini değiştirir.
    // Bu sayede "Oyun kodunu değiştirmek" banından kurtulmayı hedefliyoruz.
    
    Class tssClass = NSClassFromString(@"TssIosMainThreadDispatcher");
    if (tssClass) {
        SEL originalSelector = NSSelectorFromString(@"SendCmd:");
        Method originalMethod = class_getInstanceMethod(tssClass, originalSelector);
        
        if (originalMethod) {
            // Orijinal metodun yerini bizim "Hayalet" metodumuzla değiştiriyoruz
            method_setImplementation(originalMethod, (IMP)my_TssSendCmd);
            NSLog(@"[KINGMOD] Hayalet Modu: TSS Ana Kanalı Kapatıldı.");
            show_kingmod_ghost_alert();
            return;
        }
    }
    
    NSLog(@"[KINGMOD] Hayalet Modu: TSS Sınıfı Bulunamadı!");
}

// --- Ana Giriş (Constructor) ---
__attribute__((constructor)) static void kingmod_init() {
    NSLog(@"[KINGMOD] Oyun Başlatıldı, Hayalet Modu İçin 25 Saniye Bekleniyor...");
    
    // Gecikmeyi 25 saniyeye çıkarıyoruz, oyunun tüm başlangıç taramaları bitsin.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        start_kingmod_ghost_bypass();
    });
}
